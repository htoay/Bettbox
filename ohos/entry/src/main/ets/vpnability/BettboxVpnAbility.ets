import VpnExtensionAbility from '@ohos.app.ability.VpnExtensionAbility';
import vpnExtension from '@ohos.net.vpnExtension';
import connection from '@ohos.net.connection';
import Want from '@ohos.app.ability.Want';
import commonEventManager from '@ohos.commonEventManager';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';
import entry from 'libentry.so';
import { fileIo as fs } from '@kit.CoreFileKit';
import { process } from '@kit.ArkTS';

const DOMAIN = 0x0001;
const TAG = 'BettboxVpnAbility';
const SELF_BUNDLE = 'com.appshub.bettbox';

export const EVENT_VPN_TUN_CREATED = 'com.appshub.bettbox.VPN_TUN_CREATED';
export const EVENT_VPN_START_FAILED = 'com.appshub.bettbox.VPN_START_FAILED';
export const EVENT_VPN_STOPPED = 'com.appshub.bettbox.VPN_STOPPED';

/**
 * vNIC 的 MTU 合法区间。官方 `@ohos.net.vpnExtension.VpnConfig.mtu` 声明为 [576,1500]，
 * 而 Bettbox 的配置默认沿用 Android 的 9000，必须在此夹取，否则要么被系统判为非法参数
 * （VPN 建链失败），要么得到一个与实际链路（1500）不匹配的网卡 MTU —— 超过 vNIC MTU 的
 * 下行报文会被内核丢弃，表现为「部分网站 TLS 握手/大响应卡死」。
 */
const MTU_MIN = 576;
const MTU_MAX = 1500;
const MTU_DEFAULT = 1500;

/** NetAddress.family：1 = IPv4，2 = IPv6 */
const FAMILY_IPV4 = 1;
const FAMILY_IPV6 = 2;

const DEFAULT_IPV4_ADDRESS = '198.51.100.1';
const DEFAULT_IPV4_PREFIX = 30;
const DEFAULT_IPV6_PREFIX = 126;
const VPN_INTERFACE = 'vpn-tun';

/** tun fd 交接：总时长 / 单次原生调用超时 / 重试间隔（毫秒） */
const TRANSFER_TIMEOUT_MS = 25000;
const TRANSFER_ATTEMPT_MS = 2500;
const TRANSFER_RETRY_INTERVAL_MS = 500;

interface AccessControlJson {
  enable?: boolean;
  mode?: string;
  acceptList?: string[];
  rejectList?: string[];
}

interface VpnOptionsJson {
  enable?: boolean;
  port?: number;
  ipv4Address?: string;
  ipv6Address?: string;
  accessControl?: AccessControlJson;
  routeAddress?: string[];
  routeMode?: string;
  dnsServerAddress?: string;
  mtu?: number;
}

/** 解析后的 CIDR（地址 + 前缀 + 地址族） */
interface Cidr {
  address: string;
  prefixLength: number;
  family: number;
}

/** 把 "10.0.0.0/8" / "fdfe:dcba:9876::1/126" 解析为 Cidr，非法输入返回 null */
function parseCidr(value: string, defaultPrefix: number): Cidr | null {
  const text = value.trim();
  if (text.length === 0) {
    return null;
  }
  const parts = text.split('/');
  const address = parts[0].trim();
  let family = 0;
  let maxPrefix = 0;
  if (address.indexOf(':') >= 0) {
    family = FAMILY_IPV6;
    maxPrefix = 128;
  } else if (address.indexOf('.') >= 0) {
    family = FAMILY_IPV4;
    maxPrefix = 32;
  } else {
    return null;
  }
  let prefixLength = defaultPrefix;
  if (parts.length > 1) {
    const parsed = Number.parseInt(parts[1].trim(), 10);
    if (!Number.isNaN(parsed)) {
      prefixLength = parsed;
    }
  }
  if (prefixLength < 0 || prefixLength > maxPrefix) {
    prefixLength = defaultPrefix;
  }
  return { address: address, prefixLength: prefixLength, family: family };
}

/** 组装单条 vNIC 路由（默认路由即前缀为 0 的路由） */
function buildRoute(cidr: Cidr, gateway: string): connection.RouteInfo {
  return {
    interface: VPN_INTERFACE,
    destination: {
      address: { address: cidr.address, family: cidr.family },
      prefixLength: cidr.prefixLength
    },
    gateway: { address: gateway, family: cidr.family },
    hasGateway: true,
    isDefaultRoute: cidr.prefixLength === 0
  };
}

export default class BettboxVpnAbility extends VpnExtensionAbility {
  private vpnConnection: vpnExtension.VpnConnection | null = null;

  async onCreate(want: Want): Promise<void> {
    hilog.info(DOMAIN, TAG, 'BettboxVpnAbility onCreate');
    try {
      this.vpnConnection = vpnExtension.createVpnConnection(this.context);

      const configParam = want.parameters?.['vpnConfig'] as string | undefined;
      if (!configParam) {
        hilog.warn(DOMAIN, TAG, 'onCreate: no vpnConfig parameter in want');
        this.publishStartFailed('vpnConfig parameter is missing');
        return;
      }

      const options: VpnOptionsJson = JSON.parse(configParam);
      const config = this.buildVpnConfig(options);

      // protectProcessNet 让本进程（含 Go 核心）的出站 socket 直走物理网卡，避免流量回环。
      // 官方未约定它必须早于 create()，因此先尝试一次；失败则在 create() 之后重试。
      let protectedBeforeCreate = await this.tryProtectProcessNet();
      if (!protectedBeforeCreate) {
        hilog.warn(DOMAIN, TAG, 'protectProcessNet before create failed, will retry after create');
      }

      const tunFd = await this.vpnConnection.create(config);
      hilog.info(DOMAIN, TAG,
        'VPN TUN created, tunFd=%{public}d mtu=%{public}d routes=%{public}d ipv6=%{public}s',
        tunFd, config.mtu ?? MTU_DEFAULT, config.routes?.length ?? 0,
        config.isIPv6Accepted ? 'on' : 'off');

      if (!protectedBeforeCreate && !(await this.tryProtectProcessNet())) {
        // 未保护进程时核心出站连接会被系统再次送回 vpn-tun，形成回环；
        // 这里只告警不中断：部分机型 API < 22 无此能力，仍需依赖 fd 侧兜底。
        hilog.error(DOMAIN, TAG, 'protectProcessNet unavailable: traffic loop protection is degraded');
      }

      const sockPath = want.parameters?.['sockPath'] as string | undefined;
      // sockPath 是主进程建的抽象命名空间 socket（@name）：
      // 真机实测 release 下 VPN 扩展处于隔离 SELinux 域，文件型 socket 的
      // connect 一律 EACCES(-13)，只有抽象 socket（无文件 inode）能完成 fd 交接。
      const candidates: string[] = [];
      if (sockPath) {
        candidates.push(sockPath);
      }
      if (candidates.length > 0) {
        const transferRes = await this.transferTunFd(candidates, tunFd);
        if (transferRes !== 0) {
          // fd 没送到 Go 核心：此时 VPN 已建立但核心没有 TUN，
          // 必须按启动失败上报，否则 Dart 侧会显示「已连接」却完全不转发
          throw new Error(`transfer tun fd failed, code=${transferRes}`);
        }
      }

      commonEventManager.publish(EVENT_VPN_TUN_CREATED, {
        code: tunFd,
        data: tunFd.toString()
      }, (err: BusinessError | null) => {
        if (err) {
          hilog.error(DOMAIN, TAG, 'publish TUN_CREATED error: %{public}s', JSON.stringify(err));
        }
      });

      // VPN 建立后为本 extension 进程申请 dataTransfer 长时任务：
      // VPN extension 独立于 UI 进程运行，退后台后若无长时任务保活会被系统回收，
      // 进程被杀会导致系统直接 teardown VPN（状态栏图标消失，且来不及走 onDestroy 广播）
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'setup VPN failed: %{public}s', JSON.stringify(err));
      // 启动链路任何一步失败都要回收已建立的 vNIC，避免系统侧残留一个没有核心接管的 VPN
      await this.destroyConnection();
      this.publishStartFailed((err as Error).message ?? 'VPN setup failed');
    }
  }

  /**
   * 逐个候选路径把 tun fd 送进 Go 核心，返回 0 表示成功。
   *
   * 注意：原生 sendTunFd 单次最多阻塞 ~2.5s（鸿蒙会把长时间阻塞 JS 线程的扩展进程
   * 判为 appfreeze 并杀掉，真机崩溃栈就落在 sendTunFd），所以重试放在这里用
   * 异步循环做，JS 线程在每轮之间是空闲的。
   */
  private async transferTunFd(candidates: string[], tunFd: number): Promise<number> {
    const deadline = Date.now() + TRANSFER_TIMEOUT_MS;
    let lastResult = -1;
    while (Date.now() < deadline) {
      for (const candidate of candidates) {
        if (Date.now() >= deadline) {
          break;
        }
        const result = entry.sendTunFd(candidate, tunFd, TRANSFER_ATTEMPT_MS);
        hilog.info(DOMAIN, TAG, 'sendTunFd %{public}s result: %{public}d', candidate, result);
        if (result === 0) {
          return 0;
        }
        lastResult = result;
      }
      if (Date.now() < deadline) {
        await new Promise<void>((resolve) => {
          setTimeout(() => resolve(), TRANSFER_RETRY_INTERVAL_MS);
        });
      }
    }
    return lastResult;
  }




  /** 销毁已建立的 vpnConnection（失败忽略） */
  private async destroyConnection(): Promise<void> {
    const connectionInstance = this.vpnConnection;
    if (!connectionInstance) {
      return;
    }
    try {
      await connectionInstance.destroy();
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'destroy vpnConnection failed: %{public}s', JSON.stringify(e));
    }
  }

  /** 组装 VpnConfig：地址、路由、DNS、MTU、分应用名单 */
  private buildVpnConfig(options: VpnOptionsJson): vpnExtension.VpnConfig {
    const parsedIpv4 = parseCidr(options.ipv4Address ?? DEFAULT_IPV4_ADDRESS, DEFAULT_IPV4_PREFIX);
    const ipv4: Cidr = parsedIpv4 !== null && parsedIpv4.family === FAMILY_IPV4
      ? parsedIpv4
      : { address: DEFAULT_IPV4_ADDRESS, prefixLength: DEFAULT_IPV4_PREFIX, family: FAMILY_IPV4 };

    // 只有核心真正启用了 IPv6（Dart 侧下发 ipv6Address）才接受 IPv6：
    // 反之 IPv6 流量会绕过 vpn-tun 直连物理网卡（双栈站点实际未被代理）。
    let ipv6: Cidr | null = null;
    const ipv6Option = options.ipv6Address ?? '';
    if (ipv6Option.length > 0) {
      const parsed = parseCidr(ipv6Option, DEFAULT_IPV6_PREFIX);
      if (parsed !== null && parsed.family === FAMILY_IPV6) {
        ipv6 = parsed;
      } else {
        hilog.warn(DOMAIN, TAG, 'ignore invalid ipv6Address: %{public}s', ipv6Option);
      }
    }

    const addresses: connection.LinkAddress[] = [
      { address: { address: ipv4.address, family: FAMILY_IPV4 }, prefixLength: ipv4.prefixLength }
    ];
    if (ipv6 !== null) {
      addresses.push({
        address: { address: ipv6.address, family: FAMILY_IPV6 },
        prefixLength: ipv6.prefixLength
      });
    }

    const routes = this.buildRoutes(options, ipv4, ipv6);

    const dnsAddress = (options.dnsServerAddress ?? '').trim();
    const dnsAddr = dnsAddress.length > 0 ? [dnsAddress] : ['198.51.100.2'];

    const requestedMtu = options.mtu ?? 0;
    const mtu = requestedMtu >= MTU_MIN && requestedMtu <= MTU_MAX ? requestedMtu : MTU_DEFAULT;

    const selfBundle = SELF_BUNDLE;
    let trustedApps: string[] | undefined = undefined;
    let blockedApps: string[] | undefined = undefined;

    if (options.accessControl?.enable) {
      if (options.accessControl.mode === 'acceptSelected' && options.accessControl.acceptList?.length) {
        trustedApps = options.accessControl.acceptList.filter((b: string) => b !== selfBundle);
      } else if (options.accessControl.mode === 'rejectSelected' && options.accessControl.rejectList?.length) {
        const list = [...options.accessControl.rejectList];
        if (!list.includes(selfBundle)) list.push(selfBundle);
        blockedApps = list;
      } else {
        blockedApps = [selfBundle];
      }
    } else {
      blockedApps = [selfBundle];
    }

    return {
      addresses: addresses,
      routes: routes,
      mtu: mtu,
      dnsAddresses: dnsAddr,
      trustedApplications: trustedApps,
      blockedApplications: blockedApps,
      isIPv4Accepted: true,
      isIPv6Accepted: ipv6 !== null,
      isBlocking: false
    };
  }

  /**
   * 路由表：与 Android 端 `BettboxVpnService` 保持同一语义 ——
   * 配置了下发路由（默认开启「绕过私有网段」时会下发公网段列表）就按列表下发，
   * 否则回落到默认路由。这样局域网/私有网段不会被 vpn-tun 劫持。
   */
  private buildRoutes(
    options: VpnOptionsJson,
    ipv4: Cidr,
    ipv6: Cidr | null
  ): connection.RouteInfo[] {
    const ipv4Routes: connection.RouteInfo[] = [];
    const ipv6Routes: connection.RouteInfo[] = [];
    const configured = options.routeAddress ?? [];
    for (const item of configured) {
      // 路由必须带前缀长度（如 10.0.0.0/8），否则无从判断网段，直接忽略
      if (item.indexOf('/') < 0) {
        continue;
      }
      const cidr = parseCidr(item, -1);
      if (cidr === null || cidr.prefixLength < 0) {
        continue;
      }
      if (cidr.family === FAMILY_IPV4) {
        ipv4Routes.push(buildRoute(cidr, ipv4.address));
      } else if (ipv6 !== null) {
        ipv6Routes.push(buildRoute(cidr, ipv6.address));
      }
    }

    if (ipv4Routes.length === 0) {
      ipv4Routes.push(buildRoute({
        address: '0.0.0.0',
        prefixLength: 0,
        family: FAMILY_IPV4
      }, ipv4.address));
    }
    if (ipv6 !== null && ipv6Routes.length === 0) {
      ipv6Routes.push(buildRoute({
        address: '::',
        prefixLength: 0,
        family: FAMILY_IPV6
      }, ipv6.address));
    }

    return ipv4Routes.concat(ipv6Routes);
  }

  /** 保护本进程出站流量，返回是否成功（API 22+ 才有该能力） */
  private async tryProtectProcessNet(): Promise<boolean> {
    const connectionInstance = this.vpnConnection;
    if (!connectionInstance) {
      return false;
    }
    try {
      await connectionInstance.protectProcessNet();
      hilog.info(DOMAIN, TAG, 'protectProcessNet succeeded');
      return true;
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'protectProcessNet error: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  /** 通知宿主启动失败（带上错误信息，Dart 侧据此提示并回滚连接状态） */
  private publishStartFailed(message: string): void {
    commonEventManager.publish(EVENT_VPN_START_FAILED, {
      code: -1,
      data: message
    }, (err: BusinessError | null) => {
      if (err) {
        hilog.error(DOMAIN, TAG, 'publish START_FAILED error: %{public}s', JSON.stringify(err));
      }
    });
  }


  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'BettboxVpnAbility onDestroy');
    // 后台保活由主进程 UIAbility 负责：官方约束「Stage 模型下长时任务仅支持 UIAbility 申请」，
    // 扩展申请必然 401。这里只做 VPN 自身的清理。
    if (this.vpnConnection) {
      this.vpnConnection.destroy().catch((err: Error) => {
        hilog.error(DOMAIN, TAG, 'destroy vpnConnection failed: %{public}s', JSON.stringify(err));
      });
      this.vpnConnection = null;
    }
    commonEventManager.publish(EVENT_VPN_STOPPED, {
      code: 0,
      data: 'STOPPED'
    }, (err: BusinessError | null) => {});
  }
}
