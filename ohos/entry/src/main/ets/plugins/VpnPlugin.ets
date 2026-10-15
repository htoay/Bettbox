import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import vpnExtension from '@ohos.net.vpnExtension';
import connection from '@ohos.net.connection';
import commonEventManager from '@ohos.commonEventManager';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';
import {
  EVENT_VPN_TUN_CREATED,
  EVENT_VPN_START_FAILED,
  EVENT_VPN_STOPPED
} from '../vpnability/BettboxVpnAbility';

const DOMAIN = 0x0001;
const TAG = 'VpnPlugin';

/** 本应用 vNIC 的地址段，用于把 VPN 自身网络从「物理网络」中排除 */
const VNIC_IPV4_PREFIX = '198.51.100.';
const VNIC_IPV6_PREFIX = 'fdfe:dcba:9876';

export default class VpnPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private isRunning: boolean = false;
  private statusSubscriber: commonEventManager.CommonEventSubscriber | null = null;
  private netConnection: connection.NetConnection | null = null;


  getUniqueClassName(): string {
    return 'VpnPlugin';  }

  constructor(context?: common.UIAbilityContext) {
    if (context) {
      this.context = context;
    }
  }

  async onAttachedToEngine(binding: FlutterPluginBinding): Promise<void> {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'service');
    this.channel.setMethodCallHandler(this);
    hilog.info(DOMAIN, TAG, 'VpnPlugin attached to engine');

    try {
      this.statusSubscriber = await commonEventManager.createSubscriber({
        events: [EVENT_VPN_STOPPED]
      });
      commonEventManager.subscribe(
        this.statusSubscriber,
        (err: BusinessError | null, data: commonEventManager.CommonEventData) => {
          if (!err && data.event === EVENT_VPN_STOPPED) {
            this.isRunning = false;
            this.notifyRunState('STOP');
          }
        }
      );
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'Failed to subscribe EVENT_VPN_STOPPED: %{public}s', JSON.stringify(e));
    }

    // Android 端由 VpnPlugin 的 NetworkCallback 把「网络变化 / 系统 DNS」推给 Dart，
    // 鸿蒙这里用 @ohos.net.connection 补齐同一职责：系统 DNS 必须送达核心，
    // 否则 mihomo 的 system 解析器为空，会退回内置的 114.114.114.114/8.8.8.8。
    this.registerNetworkCallback();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    if (this.statusSubscriber) {
      commonEventManager.unsubscribe(this.statusSubscriber, (err: BusinessError | null) => {});
      this.statusSubscriber = null;
    }
    this.unregisterNetworkCallback();
    hilog.info(DOMAIN, TAG, 'VpnPlugin detached from engine');
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    const method = call.method;
    hilog.info(DOMAIN, TAG, 'onMethodCall: %{public}s', method);

    switch (method) {
      case 'init':
        result.success(true);
        break;

      case 'destroy':
        await this.stopVpnInternal();
        result.success(true);
        break;

      case 'startVpn':
        try {
          const dataStr = call.argument('data') as string;
          const sockPath = (call.argument('sockPath') as string) ?? '';
          const tunFd = await this.startVpnInternal(dataStr, sockPath);
          result.success(tunFd);
        } catch (e) {
          hilog.error(DOMAIN, TAG, 'startVpn error: %{public}s', JSON.stringify(e));
          result.error('START_VPN_FAILED', (e as Error).message, null);
        }
        break;

      case 'stopVpn':
        await this.stopVpnInternal();
        result.success(true);
        break;

      case 'isServiceEngineRunning':
        result.success(this.isRunning);
        break;

      case 'status':
        result.success(this.isRunning);
        break;

      case 'smartStop':
      case 'smartResume':
      case 'setSmartStopped':
      case 'isSmartStopped':
      case 'setQuickResponse':
        // 鸿蒙端不支持 Android 的 smart stop（销毁 vNIC 省电）与快捷响应通道，
        // 由 Dart 侧智能停机的桌面分支兜底，见 manager/smart_auto_stop_manager.dart
        result.success(false);
        break;

      case 'getLocalIpAddresses':
        result.success(await this.getLocalIpAddresses());
        break;

      case 'getLocalGateways':
        result.success(await this.getLocalGateways());
        break;

      case 'getSystemDns':
        result.success(await this.getSystemDns());
        break;

      case 'getNetworkInfo':
        result.success(await this.getNetworkInfo());
        break;

      // 鸿蒙端没有 Android 的通知栏自定义能力，这些方法必须给出明确结果，
      // 否则 Dart 侧会收到 MissingPluginException
      case 'updateNotificationSpeed':
      case 'restoreNotification':
      case 'setHighPriorityNotification':
        result.success(true);
        break;

      case 'reconnectIpc':
        result.success(false);
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  private async startVpnInternal(configStr: string, sockPath: string): Promise<number> {
    const subscriber = await commonEventManager.createSubscriber({
      events: [EVENT_VPN_TUN_CREATED, EVENT_VPN_START_FAILED]
    });

    const tunPromise = new Promise<number>((resolve, reject) => {
      const timer = setTimeout(() => {
        commonEventManager.unsubscribe(subscriber, (err: BusinessError | null) => {});
        reject(new Error('VPN start timed out waiting for authorization or TUN creation'));
      }, 30000);

      commonEventManager.subscribe(
        subscriber,
        (err: BusinessError | null, data: commonEventManager.CommonEventData) => {
          if (err) {
            clearTimeout(timer);
            commonEventManager.unsubscribe(subscriber, (unsubErr: BusinessError | null) => {});
            reject(new Error(err.message));
            return;
          }
          if (data.event === EVENT_VPN_TUN_CREATED) {
            clearTimeout(timer);
            commonEventManager.unsubscribe(subscriber, (unsubErr: BusinessError | null) => {});
            resolve(data.code ?? 0);
          } else if (data.event === EVENT_VPN_START_FAILED) {
            // 建链失败必须走 reject：此前该分支被 resolve(data.code) 抢先命中，
            // tunFd = -1 被当成成功返回，Dart 侧据此显示「已连接」但核心拿不到 fd
            clearTimeout(timer);
            commonEventManager.unsubscribe(subscriber, (unsubErr: BusinessError | null) => {});
            reject(new Error(data.data ?? 'VPN start failed'));
          }
        }
      );
    });

    const want: Want = {
      bundleName: 'com.appshub.bettbox',
      abilityName: 'BettboxVpnAbility',
      parameters: {
        'vpnConfig': configStr,
        'sockPath': sockPath
      }
    };

    hilog.info(DOMAIN, TAG, 'Calling startVpnExtensionAbility...');
    await vpnExtension.startVpnExtensionAbility(want);

    let tunFd = 0;
    try {
      tunFd = await tunPromise;
    } catch (e) {
      const message = (e as Error).message ?? 'VPN start failed';
      // 失败后必须结束扩展实例：sockPath 是启动时通过 want 下发的，
      // 旧实例不会重新 onCreate，留着它会让后续每次启动都投递到失效路径
      await this.stopVpnInternal();
      this.notifyStartFailed(message);
      // ArkTS 只允许抛出 Error 类型（arkts-limited-throw）
      throw new Error(message);
    }

    // 0/1/2 是标准输入输出，不可能是 vNIC 的 fd；-1 为能力侧失败码
    if (tunFd <= 2) {
      const message = `invalid tun fd from vpn extension: ${tunFd}`;
      await this.stopVpnInternal();
      this.notifyStartFailed(message);
      throw new Error(message);
    }

    this.isRunning = true;
    this.notifyRunState('START');
    hilog.info(DOMAIN, TAG, 'startVpnInternal succeeded with tunFd: %{public}d', tunFd);
    return tunFd;
  }

  private async stopVpnInternal(): Promise<void> {
    const want: Want = {
      bundleName: 'com.appshub.bettbox',
      abilityName: 'BettboxVpnAbility'
    };
    try {
      await vpnExtension.stopVpnExtensionAbility(want);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'stopVpnExtensionAbility error: %{public}s', JSON.stringify(e));
    }
    this.isRunning = false;
    this.notifyRunState('STOP');
  }

  private notifyRunState(state: string): void {
    if (this.channel) {
      this.channel.invokeMethod('runStateChanged', state);
    }
  }

  /** 建链失败事件：与 Android ServicePlugin.notifyVpnStartFailed 对齐 */
  private notifyStartFailed(message: string): void {
    if (this.channel) {
      this.channel.invokeMethod('vpnStartFailed', message);
    }
  }

  private registerNetworkCallback(): void {
    if (this.netConnection) {
      return;
    }
    try {
      const specifier: connection.NetSpecifier = {
        netCapabilities: {
          networkCap: [
            connection.NetCap.NET_CAPABILITY_INTERNET,
            connection.NetCap.NET_CAPABILITY_NOT_VPN
          ],
          // 只关心物理承载（蜂窝/Wi-Fi/蓝牙/以太网），排除 VPN 自身
          bearerTypes: [
            connection.NetBearType.BEARER_CELLULAR,
            connection.NetBearType.BEARER_WIFI,
            connection.NetBearType.BEARER_BLUETOOTH,
            connection.NetBearType.BEARER_ETHERNET
          ]
        }
      };
      const netConnection = connection.createNetConnection(specifier);
      // 先挂监听再 register，避免 register 成功与挂载监听之间的事件丢失
      const onPhysicalNetChanged = (data: connection.NetHandle): void => {
        this.onNetworkChanged();
      };
      netConnection.on('netAvailable', onPhysicalNetChanged);
      netConnection.on('netLost', onPhysicalNetChanged);
      netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo): void => {
        this.onNetworkChanged();
      });
      netConnection.register((err: BusinessError) => {
        if (err) {
          hilog.warn(DOMAIN, TAG, 'register network callback failed: %{public}s', JSON.stringify(err));
          return;
        }
        this.netConnection = netConnection;
        hilog.info(DOMAIN, TAG, 'network callback registered');
        // 注册成功后立刻上报一次，让核心在启动早期就拿到真实的系统 DNS
        this.onNetworkChanged();
      });
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'createNetConnection error: %{public}s', JSON.stringify(e));
    }
  }

  private unregisterNetworkCallback(): void {
    const netConnection = this.netConnection;
    if (!netConnection) {
      return;
    }
    this.netConnection = null;
    try {
      netConnection.unregister((err: BusinessError) => {
        if (err) {
          hilog.warn(DOMAIN, TAG, 'unregister network callback failed: %{public}s', JSON.stringify(err));
        }
      });
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'unregister network callback error: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 物理网络发生变化：通知 Dart（关停陈旧连接、重新评估智能停机、重新下发系统 DNS）。
   * Dart 侧 Service._handleMethodCall 收到后会主动拉取 getSystemDns 并推给核心。
   */
  private onNetworkChanged(): void {
    if (this.channel) {
      this.channel.invokeMethod('networkChanged', '');
    }
    this.getSystemDns().then((dns: string) => {
      hilog.info(DOMAIN, TAG, 'system dns: %{public}s', dns);
    }).catch((err: BusinessError) => {
      hilog.warn(DOMAIN, TAG, 'read system dns failed: %{public}s', JSON.stringify(err));
    });
  }

  /** 收集所有物理网络（排除 VPN 自身 vNIC）的连接属性 */
  private async collectPhysicalProperties(): Promise<connection.ConnectionProperties[]> {
    const properties: connection.ConnectionProperties[] = [];
    try {
      const nets = await connection.getAllNets();
      for (const net of nets) {
        try {
          const props = await connection.getConnectionProperties(net);
          if (this.isVpnProperties(props)) {
            continue;
          }
          properties.push(props);
        } catch (e) {
          // 网络可能在枚举过程中失效，忽略该网络
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'getAllNets failed: %{public}s', JSON.stringify(e));
    }
    return properties;
  }

  private isVpnProperties(props: connection.ConnectionProperties): boolean {
    const name = props.interfaceName ?? '';
    if (name.indexOf('vpn') >= 0) {
      return true;
    }
    const links = props.linkAddresses ?? [];
    for (const link of links) {
      const address = link.address?.address ?? '';
      if (address.startsWith(VNIC_IPV4_PREFIX) || address.startsWith(VNIC_IPV6_PREFIX)) {
        return true;
      }
    }
    return false;
  }

  private isLoopback(address: string): boolean {
    return address.startsWith('127.');
  }

  /** 物理网络 IPv4 地址（与 Android getLocalIpAddresses 语义一致） */
  private async getLocalIpAddresses(): Promise<string[]> {
    const addresses: string[] = [];
    const properties = await this.collectPhysicalProperties();
    for (const props of properties) {
      const links = props.linkAddresses ?? [];
      for (const link of links) {
        const address = link.address?.address ?? '';
        if (address.length === 0 || address.indexOf(':') >= 0 || this.isLoopback(address)) {
          continue;
        }
        if (!addresses.includes(address)) {
          addresses.push(address);
        }
      }
    }
    return addresses;
  }

  /** 物理网络默认网关（与 Android getLocalGateways 语义一致） */
  private async getLocalGateways(): Promise<string[]> {
    const gateways: string[] = [];
    const properties = await this.collectPhysicalProperties();
    let routeCount = 0;
    for (const props of properties) {
      const routes = props.routes ?? [];
      routeCount += routes.length;
      for (const route of routes) {
        // 判定默认路由：默认路由就是「目的前缀长度 0」（0.0.0.0/0 或 ::/0）。
        // 不再依赖 isDefaultRoute / hasGateway：真机上这两个字段可能为 false/undefined，
        // 会把真正的默认路由排除掉（表现为「网关」恒显示 -）。
        // 后面还有 IPv4 / 非回环 / 非 0.0.0.0 的过滤兜底，放宽这里不会引入垃圾值。
        const isDefault = route.isDefaultRoute === true
          || route.destination?.prefixLength === 0;
        if (!isDefault) {
          continue;
        }
        const gateway = route.gateway?.address ?? '';
        if (gateway.length === 0 || gateway.indexOf(':') >= 0 || this.isLoopback(gateway) || gateway === '0.0.0.0') {
          continue;
        }
        if (!gateways.includes(gateway)) {
          gateways.push(gateway);
        }
      }
    }
    if (gateways.length === 0) {
      // 真机上「网关显示 -」的唯一线索：先看物理网络到底有没有暴露路由表
      hilog.warn(DOMAIN, TAG, 'getLocalGateways: no IPv4 default route (nets=%{public}d routes=%{public}d)',
        properties.length, routeCount);
    }
    return gateways;
  }

  /**
   * 物理网络的 DNS 服务器（逗号分隔的 host:port 形式，和 Android 侧 asSocketAddressText(53) 一致）。
   * 必须排除 vNIC 自身：VPN 起来后系统默认网络的 DNS 就是核心的 198.51.100.2，
   * 把它当成「系统 DNS」下发会造成解析回环。
   */
  private async getSystemDns(): Promise<string> {
    const dnsList: string[] = [];
    const properties = await this.collectPhysicalProperties();
    for (const props of properties) {
      const dnses = props.dnses ?? [];
      for (const dns of dnses) {
        const address = dns.address ?? '';
        if (address.length === 0) {
          continue;
        }
        const isIpv6 = dns.family === 2 || address.indexOf(':') >= 0;
        const text = isIpv6 ? `[${address}]:53` : `${address}:53`;
        if (!dnsList.includes(text)) {
          dnsList.push(text);
        }
      }
    }
    return dnsList.join(',');
  }

  /**
   * 仪表盘「更多 IP 信息」：Android 侧由 ServicePlugin 的原生聚合返回
   * （VpnPlugin.getNetworkInfo），鸿蒙这里补齐同一份契约。
   * 键名必须逐字为 type / interface / ip / gateway / dns(string[])，
   * 与 lib/models/common.dart 的 NetworkInfo.fromJson 一一对应。
   * 任何一步失败都退化为空值：上游只在原生分支内 try/catch，异常抛出去会让整个仪表盘取数失败。
   */
  private async getNetworkInfo(): Promise<Record<string, Object>> {
    const type = await this.getNetworkType();
    const properties = await this.getPrimaryPhysicalProperties();
    const addresses = await this.getLocalIpAddresses();
    const gateways = await this.getLocalGateways();

    // getSystemDns 返回的是 "host:port" 文本（与 Android asSocketAddressText(53) 一致，供核心下发），
    // 仪表盘要的是裸 IP，与 Android getNetworkInfo 的 hostAddress 形态对齐，这里统一剥掉端口
    const dns: string[] = [];
    const dnsText = await this.getSystemDns();
    for (const entry of dnsText.split(',')) {
      const address = this.stripDnsPort(entry);
      if (address.length > 0 && !dns.includes(address)) {
        dns.push(address);
      }
    }

    const info: Record<string, Object> = {
      'type': type,
      'interface': properties?.interfaceName ?? '',
      'ip': addresses.length > 0 ? addresses[0] : '',
      'gateway': gateways.length > 0 ? gateways[0] : '',
      'dns': dns
    };
    return info;
  }

  /**
   * 主物理网络的连接属性，语义对齐 Android 的 getDefaultPhysicalNetwork()：
   * 优先取带默认路由的那一个（collectPhysicalProperties 已排除 vNIC 自身），
   * 没有默认路由时退回第一个物理网络。
   */
  private async getPrimaryPhysicalProperties(): Promise<connection.ConnectionProperties | null> {
    const properties = await this.collectPhysicalProperties();
    let fallback: connection.ConnectionProperties | null = null;
    for (const props of properties) {
      if (fallback === null) {
        fallback = props;
      }
      const routes = props.routes ?? [];
      for (const route of routes) {
        if (route.isDefaultRoute) {
          return props;
        }
      }
    }
    return fallback;
  }

  /**
   * 当前物理承载类型，文案与 Android physicalTransports 一致：'Wi-Fi' / 'Cellular' / 'Ethernet'。
   * VPN 起来后 getDefaultNet() 可能返回 vNIC 自身（承载为 BEARER_VPN），
   * 直接采信会得到空类型，所以在取不到物理承载时回退到枚举全部网络。
   * 完全不支持时不抛异常，返回空串（NetworkInfo.type 允许为空）。
   */
  private async getNetworkType(): Promise<string> {
    try {
      const net = await connection.getDefaultNet();
      const type = await this.readBearerType(net);
      if (type.length > 0) {
        return type;
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'getDefaultNet failed: %{public}s', JSON.stringify(e));
    }

    try {
      const nets = await connection.getAllNets();
      for (const net of nets) {
        const type = await this.readBearerType(net);
        if (type.length > 0) {
          return type;
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'getAllNets for network type failed: %{public}s', JSON.stringify(e));
    }
    return '';
  }

  /** 单个网络的承载类型文案；非物理承载（含 vNIC）或读取失败一律返回空串，不抛异常 */
  private async readBearerType(net: connection.NetHandle): Promise<string> {
    try {
      const capabilities = await connection.getNetCapabilities(net);
      const bearerTypes = capabilities.bearerTypes ?? [];
      for (const bearer of bearerTypes) {
        if (bearer === connection.NetBearType.BEARER_WIFI) {
          return 'Wi-Fi';
        }
        if (bearer === connection.NetBearType.BEARER_CELLULAR) {
          return 'Cellular';
        }
        if (bearer === connection.NetBearType.BEARER_ETHERNET) {
          return 'Ethernet';
        }
      }
    } catch (e) {
      // 网络可能在枚举过程中失效，忽略该网络
    }
    return '';
  }

  /** "1.2.3.4:53" / "[2001:db8::1]:53" → 裸 IP；解析不出主机部分时返回空串 */
  private stripDnsPort(text: string): string {
    const value = text.trim();
    if (value.startsWith('[')) {
      const end = value.indexOf(']');
      return end > 0 ? value.substring(1, end) : '';
    }
    const colon = value.indexOf(':');
    return colon > 0 ? value.substring(0, colon) : value;
  }
}
