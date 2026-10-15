import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import { common, bundleManager, wantAgent } from '@kit.AbilityKit';
import Want from '@ohos.app.ability.Want';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { audio } from '@kit.AudioKit';
import { avSession } from '@kit.AVSessionKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import commonEventManager from '@ohos.commonEventManager';
import { fileIo as fs, picker } from '@kit.CoreFileKit';

const DOMAIN = 0x0001;
const TAG = 'AppPlugin';

/** 保活播放的输出音量（0~1）：真实音频有效输出，但调到近乎无声 */
const KEEP_ALIVE_VOLUME = 0.03;

/** 状态栏托盘菜单动作的内部事件（StatusBarTray 发布，AppPlugin 订阅后转发 Dart） */
const EVENT_TRAY_ACTION = 'com.appshub.bettbox.TRAY_ACTION';

/** 长时任务模式名（与 module.json5 的 backgroundModes 取值一一对应） */
const MODE_DATA_TRANSFER = 'dataTransfer';
const MODE_AUDIO_PLAYBACK = 'audioPlayback';
const MODE_TASK_KEEPING = 'taskKeeping';

/**
 * 保活首选模式 = taskKeeping（计算任务）。
 *
 * 真机实测（HarmonyOS 7.0.0 / API 26）：
 *  · 证书 ACL 已含 ohos.permission.KEEP_BACKGROUND_RUNNING_SYSTEM 时，
 *    `startBackgroundRunning(ctx, ['taskKeeping'], agent)` 正常返回，
 *    连续任务在 TUN 建好后 ~113ms 由系统创建成功 —— 不存在「申请会挂住」。
 *  · taskKeeping 没有 dataTransfer 的「10 分钟必须更新进度」义务（进度只能经实况窗
 *    履行，场景权限未开通时返回 401），也不需要 audioPlayback 的真实音频渲染。
 *
 * ⚠️ 不要给其它模式附加 dataTransfer：附加即把 C4 的进度义务引入整个任务，
 *    实测会在 10 分 03 秒被系统取消（resource_schedule_service:
 *    StopContinuousTaskByUserInner ... because notification remove）。
 */
const PREFERRED_MODE = MODE_TASK_KEEPING;

/**
 * 取消原因里「dataTransfer 的进度义务被判违约」这一族：
 * 4 = SYSTEM_CANCEL_DATA_TRANSFER_LOW_SPEED，12 = SYSTEM_CANCEL_DATA_TRANSFER_NOT_UPDATE。
 * 遇到它们重申请 dataTransfer 必然重演 10 分 03 秒的取消，必须换模式而不是重试。
 */
const REASON_DATA_TRANSFER_FATAL: number[] = [4, 12];

/** 系统取消后连续重申请的预算（次）：用完即停手，避免对系统管控死缠烂打（C14） */
const KEEPALIVE_REAPPLY_BUDGET = 3;

interface PackageItem {
  packageName: string;
  label: string;
  system: boolean;
  internet: boolean;
  firstInstallTime: number;
  lastUpdateTime: number;
}

interface PickedFileItem {
  name: string;
  path: string;
}

interface PackageInfoJson {
  appName: string;
  packageName: string;
  version: string;
  buildNumber: string;
}


/**
 * 长时任务取消原因：取值与 @ohos.resourceschedule.backgroundTaskManager 的
 * ContinuousTaskCancelReason 枚举一一对应（API 15+），不要自行臆造。
 * 其中 4/6/12 正是「dataTransfer 速率低」「audioPlayback 实际没在播」「进度未更新」，
 * 即旧方案（dataTransfer + audioPlayback）被系统取消的具体原因；
 * taskKeeping（计算任务）没有这类「业务未真实发生」的校验。
 */
const CONTINUOUS_TASK_CANCEL_REASON: Record<number, string> = {
  1: 'USER_CANCEL',
  2: 'SYSTEM_CANCEL',
  3: 'USER_CANCEL_REMOVE_NOTIFICATION',
  4: 'SYSTEM_CANCEL_DATA_TRANSFER_LOW_SPEED',
  5: 'SYSTEM_CANCEL_AUDIO_PLAYBACK_NOT_USE_AVSESSION',
  6: 'SYSTEM_CANCEL_AUDIO_PLAYBACK_NOT_RUNNING',
  7: 'SYSTEM_CANCEL_AUDIO_RECORDING_NOT_RUNNING',
  8: 'SYSTEM_CANCEL_NOT_USE_LOCATION',
  9: 'SYSTEM_CANCEL_NOT_USE_BLUETOOTH',
  10: 'SYSTEM_CANCEL_NOT_USE_MULTI_DEVICE',
  11: 'SYSTEM_CANCEL_USE_ILLEGALLY',
  12: 'SYSTEM_CANCEL_DATA_TRANSFER_NOT_UPDATE',
  13: 'SYSTEM_CANCEL_VOIP_NOT_RUNNING'
};

/**
 * 带超时的 Promise 包装。
 * 长时任务的系统接口在个别机型/场景下可能长时间不返回（实测 taskKeeping 申请
 * 会一直挂住），而调用方（Dart 的 VPN 启动流程）会 await 它 —— 一旦挂住就表现为
 * 应用卡死。因此所有长时任务相关系统调用都必须有超时上限。
 */
function withTimeout<T>(task: Promise<T>, ms: number, label: string): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    let settled = false;
    const timer = setTimeout(() => {
      if (!settled) {
        settled = true;
        reject(new Error(`${label} timeout after ${ms}ms`));
      }
    }, ms);
    task.then((value: T) => {
      if (!settled) {
        settled = true;
        clearTimeout(timer);
        resolve(value);
      }
    }).catch((err: Error) => {
      if (!settled) {
        settled = true;
        clearTimeout(timer);
        reject(err);
      }
    });
  });
}

/** 长时任务系统调用的超时上限（毫秒） */
const BG_TASK_CALL_TIMEOUT_MS = 3000;
const BG_TASK_QUERY_TIMEOUT_MS = 2000;

export default class AppPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  // 真实音频低音量保活播放：实例须以成员变量持有（官方要求，存局部变量会被系统回收导致
  // 强制暂停），随 audioPlayback 模式长时任务启停；PCM 为 rawfile WAV 解出的数据段
  /** 长时任务是否「应该」在运行（Dart 按 VPN 状态设置）；系统取消后据此自动重申请 */
  private static keepAliveDesired: boolean = false;
  /** 最近一次实际生效的模式（供 EntryAbility.onBackground 补申请时复用，避免改变用户所选类型） */
  private static keepAliveModesSnapshot: string[] = [];
  /** 最近一次申请的模式，重申请时沿用 */
  private keepAliveModes: string[] = [];
  /** 看门狗定时器：周期性校验长时任务是否仍在，防止系统静默取消后一直裸奔 */
  private keepAliveWatchdogId: number = -1;
  /** 取消/暂停监听是否已注册 */
  private continuousTaskListenerReady: boolean = false;
  /** 取消后重申请的剩余预算（成功拿到任务即回满），防止无限热循环 */
  private keepAliveReapplyBudget: number = KEEPALIVE_REAPPLY_BUDGET;

  private keepAliveRenderer: audio.AudioRenderer | null = null;
  private keepAliveSession: avSession.AVSession | null = null;
  private keepAlivePcm: Uint8Array | null = null;
  private keepAlivePcmPos: number = 0;
  // PC/2in1 状态栏托盘：托盘模块含 PC 专属系统能力，仅在 2in1 设备动态加载
  private traySubscriber: commonEventManager.CommonEventSubscriber | null = null;
  /** 当前存活的插件实例（深链投递需要，见 deliverAppLink） */
  private static liveInstance: AppPlugin | null = null;
  /**
   * 待消费的深链队列。
   *
   * 冷启动由 clash:// 拉起时，`want.uri` 比 Dart 侧的 MethodChannel 监听器更早到，
   * 此时无论「立即推送」还是「等通道就绪再推」都可能被引擎丢弃（没有 handler 的消息会被丢掉）。
   * 所以这里只入队 + 发一条「有新的深链」通知，内容一律由 Dart 主动 `consumeAppLinks` 取走：
   * 通知丢了也能在 Dart 注册回调时补取到，且队列是消费即清空，不会重复投递。
   */
  private static pendingAppLinks: string[] = [];

  getUniqueClassName(): string {
    return 'AppPlugin';
  }

  constructor(context?: common.UIAbilityContext) {
    if (context) {
      this.context = context;
    }
    AppPlugin.liveInstance = this;
  }

  /** EntryAbility 收到 want.uri 后调用；Dart 侧再从 consumeAppLinks 取走。 */
  static deliverAppLink(uri: string): void {
    AppPlugin.pendingAppLinks.push(uri);
    const plugin = AppPlugin.liveInstance;
    if (plugin && plugin.channel) {
      // 只在引擎已就绪时发通知（热启动/应用运行中）；冷启动靠 Dart 注册时的主动补取
      // 注意：ArkTS 的 invokeMethod(method, args, callback?) 第二个参数是必填的
      plugin.channel.invokeMethod('appLinkAvailable', {});
    } else {
      hilog.warn(DOMAIN, TAG, 'app link queued before engine is attached: %{public}s', uri);
    }
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'app');
    this.channel.setMethodCallHandler(this);
    this.initTray().catch((err: BusinessError) => {
      hilog.warn(DOMAIN, TAG, 'initTray failed: %{public}s', JSON.stringify(err));
    });
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    if (this.traySubscriber) {
      commonEventManager.unsubscribe(this.traySubscriber, (err: BusinessError | null) => {});
      this.traySubscriber = null;
    }
  }

  /** PC/2in1：动态加载状态栏托盘模块（手机等设备不加载，避免解析 PC 专属系统模块） */
  private async initTray(): Promise<void> {
    if (!this.context || deviceInfo.deviceType !== '2in1') {
      return;
    }
    try {
      const tray: ESObject = await import('../tray/StatusBarTray');
      await tray.install(this.context, EVENT_TRAY_ACTION);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'init status bar tray failed: %{public}s', JSON.stringify(err));
    }
    await this.subscribeTrayActions();
  }

  /** PC/2in1：下发状态栏托盘菜单（动态 import 有模块缓存，重复加载开销可忽略） */
  private async updateTrayMenu(menuJson: string): Promise<void> {
    if (deviceInfo.deviceType !== '2in1') {
      return;
    }
    try {
      const tray: ESObject = await import('../tray/StatusBarTray');
      tray.updateMenu(menuJson);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'update tray menu failed: %{public}s', JSON.stringify(err));
    }
  }

  /** 保持屏幕常亮（鸿蒙无 wakelock_plus 实现，用窗口接口替代） */
  private async setKeepScreenOn(enabled: boolean): Promise<void> {
    const ctx = this.context;
    if (!ctx) {
      return;
    }
    try {
      const win = await window.getLastWindow(ctx);
      await win.setWindowKeepScreenOn(enabled);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'set keep screen on failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 把应用切到后台。鸿蒙没有 window_manager / Android 的 moveTaskToBack，
   * Dart 侧 System.back() 依赖该能力，此前是空实现导致返回键无反应。
   */
  private async moveTaskToBack(): Promise<boolean> {
    const ctx = this.context;
    if (!ctx) {
      return false;
    }
    try {
      await ctx.moveAbilityToBackground();
      return true;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'moveAbilityToBackground failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /** 用系统浏览器（或声明了 viewData 的应用）打开链接：鸿蒙没有 url_launcher 实现 */
  private async openUrl(url: string): Promise<boolean> {
    const ctx = this.context;
    if (!ctx || url.length === 0) {
      return false;
    }
    try {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: url
      };
      await ctx.startAbility(want);
      return true;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'open url failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /** 应用自身版本信息：鸿蒙没有 package_info_plus 实现，这里读 bundle 元数据 */
  private getPackageInfo(): PackageInfoJson {
    try {
      const info = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      return {
        appName: info.appInfo?.label ?? 'Bettbox',
        packageName: info.name,
        version: info.versionName,
        buildNumber: info.versionCode.toString()
      };
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'getPackageInfo failed: %{public}s', JSON.stringify(err));
      return {
        appName: 'Bettbox',
        packageName: 'com.appshub.bettbox',
        version: '',
        buildNumber: ''
      };
    }
  }

  /** 订阅托盘菜单动作并转发给 Flutter（Dart 侧处理启动/停止代理） */
  private async subscribeTrayActions(): Promise<void> {
    try {
      this.traySubscriber = await commonEventManager.createSubscriber({
        events: [EVENT_TRAY_ACTION]
      });
      commonEventManager.subscribe(
        this.traySubscriber,
        (err: BusinessError | null, data: commonEventManager.CommonEventData) => {
          if (!err && data.event === EVENT_TRAY_ACTION && this.channel) {
            const params = data.parameters;
            const action = params ? params['action'] as string : '';
            this.channel.invokeMethod('trayAction', { 'action': action });
          }
        }
      );
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'subscribe tray actions failed: %{public}s', JSON.stringify(err));
    }
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    const method = call.method;
    switch (method) {
      case 'isAndroidTV':
        result.success(false);
        break;

      // 深链：Dart 主动取走待处理的 clash:// 链接（见 deliverAppLink）。
      // 只有回包成功才清空队列 —— 先清后发的话，回包失败就等于把链接静默丢了。
      case 'consumeAppLinks': {
        const links: string[] = AppPlugin.pendingAppLinks;
        try {
          result.success(links);
          AppPlugin.pendingAppLinks = [];
        } catch (err) {
          hilog.warn(DOMAIN, TAG, 'consumeAppLinks reply failed, keep %{public}d link(s)',
            links.length);
        }
        break;
      }

      case 'moveTaskToBack':
        result.success(await this.moveTaskToBack());
        break;

      case 'openUrl': {
        const url = (call.argument('url') as string | undefined) ?? '';
        result.success(await this.openUrl(url));
        break;
      }

      case 'getPackageInfo':
        result.success(this.getPackageInfo());
        break;

      case 'updateExcludeFromRecents':
        result.success(true);
        break;

      case 'initShortcuts':
        result.success(true);
        break;

      case 'startBackgroundTask':
        await this.startBackgroundTask(call, result);
        break;

      case 'stopBackgroundTask':
        await this.stopBackgroundTask(result);
        break;

      case 'getBackgroundTaskModes':
        result.success(await this.getBackgroundTaskModes());
        break;

      case 'scanCode':
        try {
          if (!this.context) {
            result.error('NO_CONTEXT', 'Context unavailable', null);
            return;
          }
          const options: scanBarcode.ScanOptions = {
            scanTypes: [scanCore.ScanType.ALL],
            enableMultiMode: false,
            enableAlbum: true
          };
          const scanRes = await scanBarcode.startScanForResult(this.context, options);
          result.success(scanRes.originalValue ?? '');
        } catch (err) {
          result.error('SCAN_FAILED', (err as Error).message, null);
        }
        break;

      case 'pickFiles':
        await this.pickFiles(call, result);
        break;

      case 'saveFile':
        await this.saveFile(call, result);
        break;

      case 'updateTrayMenu': {
        const menuJson = (call.argument('menuJson') as string | undefined) ?? '';
        await this.updateTrayMenu(menuJson);
        result.success(true);
        break;
      }

      case 'setKeepScreenOn': {
        const enabled = (call.argument('enabled') as boolean | undefined) ?? false;
        await this.setKeepScreenOn(enabled);
        result.success(true);
        break;
      }

      case 'getPackages':
        try {
          const list: PackageItem[] = [];
          const selfInfo = bundleManager.getBundleInfoForSelfSync(
            bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
          );
          if (selfInfo && selfInfo.name) {
            const item: PackageItem = {
              packageName: selfInfo.name,
              label: selfInfo.appInfo?.label ?? selfInfo.name,
              system: false,
              internet: true,
              firstInstallTime: selfInfo.installTime ?? 0,
              lastUpdateTime: selfInfo.updateTime ?? 0
            };
            list.push(item);
          }
          result.success(list);
        } catch (err) {
          hilog.warn(DOMAIN, TAG, 'getPackages failed: %{public}s', JSON.stringify(err));
          result.success([]);
        }
        break;

      case 'hasPackageListPermission':
      case 'requestPackageListPermission':
      case 'hasCameraPermission':
      case 'requestCameraPermission':
      case 'openAppSettings':
      case 'tip':
      case 'setLauncherIcon':
      case 'requestIgnoreBatteryOptimizations':
      case 'isIgnoringBatteryOptimizations':
        result.success(true);
        break;

      case 'openFcmDiagnostics':
        result.success(false);
        break;

      case 'getChinaPackageNames':
        result.success([]);
        break;

      case 'getPackageIcon':
        result.success(null);
        break;

      default:
        result.notImplemented();
        break;
    }
  }

  /**
   * 从通道参数解析请求的长时任务模式，非法/空入参回退 taskKeeping。
   *
   * ⚠️ 这里**不再**给 audioPlayback 自动补 dataTransfer。旧实现补了它，理由是
   * 「音频可能被冻结，靠 dataTransfer 兜底」—— 但副作用是致命的：主/子模式的
   * 一致性校验与进度义务是**逐模式**生效的，一旦 dataTransfer 进入任务集合，
   * 整个任务都要满足 C4「10 分钟内更新一次进度」，而进度只能经实况窗履行；
   * 本机 startLiveView 返回 401（AGC 场景权限未开通），义务必然违约，
   * 于是系统在 10 分 03 秒取消整个任务，把本来无义务的 audioPlayback 一起带走。
   * 兜底应改用 taskKeeping（见 startTaskWithFallback 的降级链），而不是 dataTransfer。
   */
  private parseBgModes(call: MethodCall): string[] {
    const raw = call.argument('modes') as string[] | null | undefined;
    if (!raw || raw.length === 0) {
      return [PREFERRED_MODE];
    }
    const modes: string[] = [];
    for (const mode of raw) {
      if (mode === MODE_DATA_TRANSFER || mode === MODE_AUDIO_PLAYBACK
        || mode === MODE_TASK_KEEPING) {
        modes.push(mode);
      }
    }
    return modes.length === 0 ? [PREFERRED_MODE] : modes;
  }

  /** 查询当前运行中的长时任务里属于本应用的模式（无任务返回空数组） */
  private async getBackgroundTaskModes(): Promise<string[]> {
    if (!this.context) {
      return [];
    }
    return await AppPlugin.queryRunningModes(this.context);
  }

  /** 查询本应用当前实际生效的长时任务模式（静态版，供 onBackground 等静态路径复用） */
  private static async queryRunningModes(context: common.UIAbilityContext): Promise<string[]> {
    try {
      const tasks = await withTimeout(backgroundTaskManager.getAllContinuousTasks(context),
        BG_TASK_QUERY_TIMEOUT_MS, 'getAllContinuousTasks');
      for (const task of tasks) {
        const modes = task.backgroundModes;
        if (modes.includes(MODE_DATA_TRANSFER) || modes.includes(MODE_AUDIO_PLAYBACK)
          || modes.includes(MODE_TASK_KEEPING)) {
          return modes;
        }
      }
      return [];
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'queryRunningModes failed: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  private async startBackgroundTask(call: MethodCall, result: MethodResult): Promise<void> {
    if (!this.context) {
      result.error('NO_CONTEXT', 'Context unavailable', null);
      return;
    }
    try {
      const modes = this.parseBgModes(call);
      let effectiveModes: string[] = modes;
      const runningModes = await this.getBackgroundTaskModes();
      if (runningModes.length === 0) {
        effectiveModes = await AppPlugin.startTaskWithFallback(this.context, modes);
      } else if (this.canUpdateTo(runningModes, modes)) {
        // 9800005 #14：update 只允许保持原类型并在其上新增 dataTransfer。
        // 任务可能属于其他 ability 上下文（如 VPN extension 自保任务），
        // 此时对本上下文 update 会失败，回退为尽力停旧后新建本上下文的任务
        try {
          await withTimeout(backgroundTaskManager.updateBackgroundRunning(this.context, modes),
            BG_TASK_CALL_TIMEOUT_MS, 'updateBackgroundRunning');
          hilog.info(DOMAIN, TAG, 'updateBackgroundRunning: %{public}s', JSON.stringify(modes));
        } catch (updateErr) {
          hilog.info(DOMAIN, TAG,
            'updateBackgroundRunning failed, fallback to restart: %{public}s',
            JSON.stringify(updateErr));
          await this.stopTaskBestEffort();
          effectiveModes = await AppPlugin.startTaskWithFallback(this.context, modes);
        }
      } else {
        // 运行中的类型无法通过 update 变更（如 dataTransfer → audio 复合），
        // 必须先停旧任务再按新类型申请
        await this.stopTaskBestEffort();
        effectiveModes = await AppPlugin.startTaskWithFallback(this.context, modes);
      }
      // audioPlayback 模式配套真实音频保活播放：官方要求媒体流（MUSIC）后台播放必须接 AVSession，
      // 否则系统检测到后台无会话会强制停止音频输出
      // taskKeeping 生效时无需静音音频（计算任务本身就防冻结），省电且不占音频焦点
      if (effectiveModes.includes(MODE_AUDIO_PLAYBACK)) {
        const title = (call.argument('taskTitle') as string | null | undefined) || '';
        await this.startKeepAlivePlayback(title);
      } else {
        await this.stopKeepAlivePlayback();
      }
      AppPlugin.keepAliveDesired = true;
      this.keepAliveModes = effectiveModes;
      AppPlugin.keepAliveModesSnapshot = effectiveModes;
      this.registerContinuousTaskListeners();
      this.startKeepAliveWatchdog();
      result.success(true);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'startBackgroundTask failed: %{public}s',
        JSON.stringify(err));
      result.error('START_BG_TASK_FAILED', (err as Error).message, null);
    }
  }

  /**
   * 申请长时任务，返回【实际生效】的模式集合。
   *
   * 降级链：调用方请求的模式 → taskKeeping → dataTransfer。
   *  - `requested` 尊重用户在设置里的选择；
   *  - `taskKeeping` 是首选兜底（本机 ACL 已授予，无进度义务、无音频/定位负担）；
   *  - `dataTransfer` 是最后退路，只在实况窗场景权限开通后才真正能长期存活，
   *    降级到它属于「前台可用、后台不承诺」，调用方应按 effective 结果如实提示。
   *
   * 日志一律用 WARN：release 包（app.json5 `debug:false`）的 hilog **info 级会被系统
   * 过滤**，真机上完全不可见（实测同机 debug 包可见、release 包 0 条 info），
   * 保活这条链路的每一步都必须落在 WARN 及以上才能在现场归因。
   */
  private static async startTaskWithFallback(
    context: common.UIAbilityContext,
    requested: string[]
  ): Promise<string[]> {
    // 严格尊重用户设置，不做静默的模式替换：requested 优先，其后才是兜底项
    const candidates: string[][] = [requested];
    if (!requested.includes(MODE_TASK_KEEPING)) {
      candidates.push([MODE_TASK_KEEPING]);
    }
    if (!requested.includes(MODE_DATA_TRANSFER)) {
      candidates.push([MODE_DATA_TRANSFER]);
    }
    let lastError: Error | null = null;
    for (const modes of candidates) {
      // taskKeeping 在个别机型上可能长时间不返回：给它更短的超时，尽快走到下一级
      const isTaskKeeping = modes.length === 1 && modes[0] === MODE_TASK_KEEPING;
      try {
        await AppPlugin.startTaskOnContext(context, modes, isTaskKeeping ? 1500 : undefined);
        hilog.warn(DOMAIN, TAG, 'background task started, modes: %{public}s',
          JSON.stringify(modes));
        return modes;
      } catch (err) {
        lastError = err as Error;
        hilog.warn(DOMAIN, TAG, 'start background task %{public}s failed: %{public}s',
          JSON.stringify(modes), JSON.stringify(err));
        // 超时 ≠ 系统没受理：超时后系统仍可能已建好任务，此时若继续降级会重复申请
        // （旧任务被覆盖/叠加）。先查一次实际状态，已生效就直接采信。
        const running = await AppPlugin.queryRunningModes(context);
        if (running.length > 0) {
          hilog.warn(DOMAIN, TAG,
            'background task %{public}s reported failure but is actually running: %{public}s',
            JSON.stringify(modes), JSON.stringify(running));
          return running;
        }
      }
    }
    throw lastError ?? new Error('start background task failed');
  }

  /** 为指定 UIAbility 上下文申请长时任务（通知点击回主界面） */
  private static async startTaskOnContext(
    context: common.UIAbilityContext,
    modes: string[],
    timeoutMs: number = BG_TASK_CALL_TIMEOUT_MS
  ): Promise<void> {
    const bundleInfo = bundleManager.getBundleInfoForSelfSync(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    );
    const wantInfo: wantAgent.WantAgentInfo = {
      wants: [{ bundleName: bundleInfo.name, abilityName: 'EntryAbility' }],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    const agent = await withTimeout(wantAgent.getWantAgent(wantInfo),
      BG_TASK_QUERY_TIMEOUT_MS, 'getWantAgent');
    await withTimeout(backgroundTaskManager.startBackgroundRunning(context, modes, agent),
      timeoutMs, `startBackgroundRunning(${modes.join('+')})`);
    hilog.info(DOMAIN, TAG, 'startBackgroundRunning: %{public}s', JSON.stringify(modes));
  }

  /**
   * 判断目标类型能否通过 update 达成（9800005 #14）：
   * 原有类型必须全部保留，且新增类型只能是 dataTransfer
   */
  private canUpdateTo(runningModes: string[], targetModes: string[]): boolean {
    const originalKept = runningModes.every((m) => targetModes.includes(m));
    const additionsAllowed = targetModes.every(
      (m) => runningModes.includes(m) || m === MODE_DATA_TRANSFER
    );
    return originalKept && additionsAllowed;
  }

  /** 尽力停止当前长时任务（任务可能属于其他 ability 上下文，失败不影响主流程） */
  private async stopTaskBestEffort(): Promise<void> {
    if (!this.context) {
      return;
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
      hilog.info(DOMAIN, TAG, 'stopBackgroundRunning (before restart)');
    } catch (err) {
      hilog.info(DOMAIN, TAG, 'stopBackgroundRunning skipped: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 长时任务类型切换：update 无法变更类型（9800005 #14），先尽力停旧再按新模式申请。
   * 走完整降级链（而不是裸 startTaskOnContext），避免新模式申请失败后完全失去保活；
   * 并把实际生效的模式回写到 keepAliveModes，后续 watchdog 重申请才不会再退回旧模式。
   */
  private async transitionTask(modes: string[]): Promise<void> {
    if (!this.context) {
      return;
    }
    const running = await this.getBackgroundTaskModes();
    if (running.length > 0 && this.sameModeSet(running, modes)) {
      return; // 类型未变化，避免重复停启造成通知抖动
    }
    await this.stopTaskBestEffort();
    try {
      const effective = await AppPlugin.startTaskWithFallback(this.context, modes);
      this.keepAliveModes = effective;
      AppPlugin.keepAliveModesSnapshot = effective;
      if (effective.includes(MODE_AUDIO_PLAYBACK)) {
        await this.startKeepAlivePlayback('');
      }
      hilog.warn(DOMAIN, TAG, 'background task transitioned: %{public}s',
        JSON.stringify(effective));
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'background task transition failed: %{public}s',
        JSON.stringify(err));
    }
  }

  /** 两个任务类型集合是否一致（忽略顺序） */
  private sameModeSet(a: string[], b: string[]): boolean {
    return a.length === b.length && a.every((m) => b.includes(m));
  }

  /**
   * 保活音频流被打断时的让出与任务收敛（官方规则会对音频播放被打断的
   * 应用冻结/取消 audioPlayback 长时任务，此即音频模式后台断网的根因）：
   * - 音频失效（PAUSE/STOP）→ 任务收敛为 taskKeeping（计算任务，无进度义务、
   *   无需真实音频，后台豁免照常生效，且不会像 dataTransfer 那样 10 分钟后被拆）
   * - 音频恢复（RESUME 或打断结束）→ 任务回到 audioPlayback，恢复媒体卡片形态
   * 共享型打断仅让出，不与前台音频争焦点；保活流恢复后音量近乎无声。
   */
  private async handleKeepAliveAudioInterrupt(
    event: audio.InterruptEvent,
    renderer: audio.AudioRenderer,
    session: avSession.AVSession
  ): Promise<void> {
    if (this.keepAliveRenderer !== renderer) {
      return; // 保活播放已被业务停止，忽略残留打断事件，避免任务被重新拉起
    }
    hilog.info(DOMAIN, TAG,
      'keep-alive playback interrupted: eventType=%{public}d forceType=%{public}d hintType=%{public}d',
      event.eventType, event.forceType, event.hintType);
    switch (event.hintType) {
      case audio.InterruptHint.INTERRUPT_HINT_PAUSE:
        try {
          await renderer.pause();
        } catch (err) {
          hilog.warn(DOMAIN, TAG, 'keep-alive renderer pause failed: %{public}s',
            JSON.stringify(err));
        }
        await this.onKeepAliveAudioInvalid(session);
        break;
      case audio.InterruptHint.INTERRUPT_HINT_STOP:
        try {
          await renderer.stop();
        } catch (err) {
          // 系统可能已先行停止，重复 stop 报错可忽略
        }
        await this.onKeepAliveAudioInvalid(session);
        break;
      case audio.InterruptHint.INTERRUPT_HINT_RESUME:
        await this.onKeepAliveAudioResumed(renderer, session);
        break;
      default:
        // duck/unduck 期间播放持续有效，无需处理；
        // 打断结束事件（即使未携带 RESUME hint）按音频恢复处理
        if (event.eventType === audio.InterruptType.INTERRUPT_TYPE_END) {
          await this.onKeepAliveAudioResumed(renderer, session);
        }
        break;
    }
  }

  /**
   * 音频业务失效：媒体卡片置暂停态，任务收敛为 taskKeeping。
   * 收敛目标是 taskKeeping 而**不是** dataTransfer —— 后者带 10 分钟进度义务
   * （只能经实况窗履行，本机 401），收敛过去等于把任务送进 10 分 03 秒的取消点。
   */
  private async onKeepAliveAudioInvalid(session: avSession.AVSession): Promise<void> {
    await this.setKeepAliveSessionState(session, avSession.PlaybackState.PLAYBACK_STATE_PAUSE);
    await this.transitionTask([MODE_TASK_KEEPING]);
  }

  /** 音频业务恢复：渲染器续播、卡片回 PLAY、任务回到 audioPlayback（不再附加 dataTransfer） */
  private async onKeepAliveAudioResumed(
    renderer: audio.AudioRenderer,
    session: avSession.AVSession
  ): Promise<void> {
    try {
      await renderer.start();
    } catch (err) {
      // 渲染器可能仍在运行，仍按系统指示恢复任务
      hilog.warn(DOMAIN, TAG, 'keep-alive renderer resume failed: %{public}s',
        JSON.stringify(err));
    }
    await this.setKeepAliveSessionState(session, avSession.PlaybackState.PLAYBACK_STATE_PLAY);
    await this.transitionTask([MODE_AUDIO_PLAYBACK]);
  }

  /** 更新保活会话播放状态（会话可能已被并发的停用流程销毁，失败忽略） */
  private async setKeepAliveSessionState(
    session: avSession.AVSession,
    state: avSession.PlaybackState
  ): Promise<void> {
    try {
      await session.setAVPlaybackState({ state: state });
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'update keep-alive session state failed: %{public}s',
        JSON.stringify(err));
    }
  }

  /** 注册长时任务被系统取消/暂停的监听（API 15/20+） */
  private registerContinuousTaskListeners(): void {
    if (this.continuousTaskListenerReady) {
      return;
    }
    try {
      const cancelCallback: (info: backgroundTaskManager.ContinuousTaskCancelInfo) => void =
        (info: backgroundTaskManager.ContinuousTaskCancelInfo) => {
          const reasonText = CONTINUOUS_TASK_CANCEL_REASON[info.reason] ?? `UNKNOWN(${info.reason})`;
          // detailedReason 比 reason 更精确（如进度未更新 vs 速率过低），一并落日志便于归因
          hilog.warn(DOMAIN, TAG,
            'continuousTaskCancel: id=%{public}d reason=%{public}s detailed=%{public}s raw=%{public}s',
            info.id, reasonText, String(info.detailedReason ?? -1), JSON.stringify(info));
          this.onContinuousTaskCancelled(reasonText, info.reason);
        };
      backgroundTaskManager.on('continuousTaskCancel', cancelCallback);
      this.continuousTaskListenerReady = true;
      hilog.info(DOMAIN, TAG, 'continuous task cancel listener registered');
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'register continuous task listener failed: %{public}s',
        JSON.stringify(err));
    }
    try {
      const suspendCallback: (info: backgroundTaskManager.ContinuousTaskSuspendInfo) => void =
        (info: backgroundTaskManager.ContinuousTaskSuspendInfo) => {
          hilog.warn(DOMAIN, TAG, 'continuousTaskSuspend: %{public}s', JSON.stringify(info));
        };
      backgroundTaskManager.on('continuousTaskSuspend', suspendCallback);
    } catch (err) {
      hilog.info(DOMAIN, TAG, 'continuous task suspend listener unavailable: %{public}s',
        JSON.stringify(err));
    }
  }

  /**
   * 任务被系统取消：VPN 仍在运行则延迟重申请（避开系统刚取消的窗口）。
   *
   * reason 一并传入，因为取消原因是**分模式**的：reason 12
   * （SYSTEM_CANCEL_DATA_TRANSFER_NOT_UPDATE）与 reason 4（低速挂起）说明
   * dataTransfer 的进度义务无法履行，重申请同一个模式只会再死一次 ——
   * 这种情况必须改用 taskKeeping（见 reapplyKeepAlive）。
   */
  private onContinuousTaskCancelled(reasonText: string, reason: number): void {
    if (!AppPlugin.keepAliveDesired) {
      hilog.info(DOMAIN, TAG, 'keep-alive cancelled by %{public}s but no longer desired, skip',
        reasonText);
      return;
    }
    hilog.warn(DOMAIN, TAG, 'keep-alive cancelled by %{public}s, re-applying in 1s', reasonText);
    setTimeout(() => {
      this.reapplyKeepAlive('cancel', reason).catch((err: Error) => {
        hilog.warn(DOMAIN, TAG, 're-apply after cancel failed: %{public}s', JSON.stringify(err));
      });
    }, 1000);
  }

  /**
   * 重新申请长时任务（幂等：已有任务则直接返回）。
   *
   * 带一个连败预算：系统刚取消就重申请属于「不得立即再次申请」的边缘
   * （C14 的精神是防止对系统管控死缠烂打），连续 3 次仍拿不到就停手并如实记录，
   * 由 UI 状态暴露真相，而不是无限热循环。
   */
  private async reapplyKeepAlive(trigger: string, reason: number = -1): Promise<void> {
    if (!this.context || !AppPlugin.keepAliveDesired) {
      return;
    }
    const running = await this.getBackgroundTaskModes();
    if (running.length > 0) {
      this.keepAliveReapplyBudget = KEEPALIVE_REAPPLY_BUDGET;
      return;
    }
    if (this.keepAliveReapplyBudget <= 0) {
      hilog.warn(DOMAIN, TAG,
        'keep-alive re-apply (%{public}s) skipped: budget exhausted, keeping UI honest instead',
        trigger);
      return;
    }
    this.keepAliveReapplyBudget--;
    let modes = this.keepAliveModes.length > 0 ? this.keepAliveModes : [PREFERRED_MODE];
    if (modes.includes(MODE_DATA_TRANSFER) && REASON_DATA_TRANSFER_FATAL.includes(reason)) {
      // dataTransfer 被按进度义务/低速取消：重申请同一模式必然重演 10 分钟崩溃
      hilog.warn(DOMAIN, TAG,
        'keep-alive: dataTransfer cancelled (reason=%{public}d), re-applying with %{public}s instead',
        reason, PREFERRED_MODE);
      modes = [PREFERRED_MODE];
    }
    try {
      const effective = await AppPlugin.startTaskWithFallback(this.context, modes);
      this.keepAliveModes = effective;
      AppPlugin.keepAliveModesSnapshot = effective;
      if (effective.includes(MODE_AUDIO_PLAYBACK)) {
        await this.startKeepAlivePlayback('');
      }
      hilog.warn(DOMAIN, TAG, 'keep-alive re-applied (%{public}s): %{public}s',
        trigger, JSON.stringify(effective));
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'keep-alive re-apply (%{public}s) failed: %{public}s',
        trigger, JSON.stringify(err));
    }
  }

  /** 看门狗：每 30s 校验一次长时任务是否仍在（覆盖系统静默取消、通知被划掉等场景） */
  private startKeepAliveWatchdog(): void {
    if (this.keepAliveWatchdogId !== -1) {
      return;
    }
    this.keepAliveWatchdogId = setInterval(() => {
      this.keepAliveWatchdogTick().catch((err: Error) => {
        hilog.warn(DOMAIN, TAG, 'keep-alive watchdog tick failed: %{public}s', JSON.stringify(err));
      });
    }, 30000);
    hilog.info(DOMAIN, TAG, 'keep-alive watchdog started (30s)');
  }

  private stopKeepAliveWatchdog(): void {
    if (this.keepAliveWatchdogId !== -1) {
      clearInterval(this.keepAliveWatchdogId);
      this.keepAliveWatchdogId = -1;
      hilog.info(DOMAIN, TAG, 'keep-alive watchdog stopped');
    }
  }

  private async keepAliveWatchdogTick(): Promise<void> {
    if (!AppPlugin.keepAliveDesired) {
      return;
    }
    const running = await this.getBackgroundTaskModes();
    if (running.length === 0) {
      hilog.warn(DOMAIN, TAG, 'keep-alive missing in watchdog, re-applying');
      await this.reapplyKeepAlive('watchdog');
    }
  }

  /** 供 EntryAbility.onBackground 调用：切后台时确保长时任务已申请（官方推荐时机） */
  static async ensureKeepAliveFromBackground(context: common.UIAbilityContext): Promise<void> {
    if (!AppPlugin.keepAliveDesired) {
      hilog.info(DOMAIN, TAG, 'onBackground: keep-alive not desired, skip');
      return;
    }
    try {
      const running = await AppPlugin.queryRunningModes(context);
      if (running.length > 0) {
        hilog.info(DOMAIN, TAG, 'onBackground: keep-alive already running: %{public}s',
          JSON.stringify(running));
        return;
      }
      hilog.warn(DOMAIN, TAG, 'onBackground: keep-alive missing, re-applying');
      // 用上次实际生效的模式；未记录时用首选模式（taskKeeping），
      // 不再退回 dataTransfer —— 它在本机没有实况窗通道时是必死的降级项
      const modes = AppPlugin.keepAliveModesSnapshot.length > 0
        ? AppPlugin.keepAliveModesSnapshot
        : [PREFERRED_MODE];
      const effective = await AppPlugin.startTaskWithFallback(context, modes);
      AppPlugin.keepAliveModesSnapshot = effective;
      hilog.warn(DOMAIN, TAG, 'onBackground: keep-alive re-applied %{public}s',
        JSON.stringify(effective));
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'onBackground keep-alive check failed: %{public}s',
        JSON.stringify(err));
    }
  }

  private async stopBackgroundTask(result: MethodResult): Promise<void> {
    if (!this.context) {
      result.error('NO_CONTEXT', 'Context unavailable', null);
      return;
    }
    try {
      const runningModes = await this.getBackgroundTaskModes();
      if (runningModes.length > 0) {
        try {
          await withTimeout(backgroundTaskManager.stopBackgroundRunning(this.context),
            BG_TASK_CALL_TIMEOUT_MS, 'stopBackgroundRunning');
          hilog.info(DOMAIN, TAG, 'stopBackgroundRunning: %{public}s', JSON.stringify(runningModes));
        } catch (stopErr) {
          // 任务可能属于其他 ability 上下文（如 VPN extension 自保任务），本上下文无任务可停
          hilog.info(DOMAIN, TAG, 'stopBackgroundRunning skipped: %{public}s', JSON.stringify(stopErr));
        }
      }
      await this.stopKeepAlivePlayback();
      AppPlugin.keepAliveDesired = false;
      this.stopKeepAliveWatchdog();
      result.success(true);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'stopBackgroundTask failed: %{public}s',
        JSON.stringify(err));
      result.error('STOP_BG_TASK_FAILED', (err as Error).message, null);
    }
  }

  /**
   * 真实音频低音量保活播放：循环输出 rawfile/keepalive.wav（44.1kHz 单声道 S16LE，
   * 8 秒无缝循环的真实音频），再把输出音量压到近乎无声。系统按实际音频输出判定
   * 有效播放，全零静音流会被判无效并连带冻结 audioPlayback 长时任务，因此数据源
   * 必须是真实信号。文件格式约定：44100Hz / 单声道 / 16-bit PCM WAV
   * （loadKeepAlivePcm 强制校验）。title 用于媒体中心/通知卡片展示。
   */
  private async startKeepAlivePlayback(title: string): Promise<void> {
    const ctx = this.context;
    if (!ctx) {
      return;
    }
    if (this.keepAliveRenderer) {
      return; // 已在播放
    }
    try {
      const pcm = await this.loadKeepAlivePcm(ctx);
      this.keepAlivePcm = pcm;
      this.keepAlivePcmPos = 0;

      const session = await avSession.createAVSession(ctx, 'BettboxKeepAlive', 'audio');
      await session.setAVMetadata({
        assetId: 'bettbox_keepalive',
        title: title || 'Bettbox',
        artist: 'Bettbox'
      });
      await session.setAVPlaybackState({
        state: avSession.PlaybackState.PLAYBACK_STATE_PLAY
      });
      await session.activate();
      this.keepAliveSession = session;

      const renderer = await audio.createAudioRenderer({
        streamInfo: {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
          channels: audio.AudioChannel.CHANNEL_1,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        rendererInfo: {
          usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
          rendererFlags: 0
        }
      });
      renderer.on('writeData', (data: ArrayBuffer): audio.AudioDataCallbackResult => {
        this.fillKeepAliveData(new Uint8Array(data));
        return audio.AudioDataCallbackResult.VALID;
      });
      renderer.on('audioInterrupt', (event: audio.InterruptEvent): void => {
        this.handleKeepAliveAudioInterrupt(event, renderer, session).catch(
          (err: BusinessError) => {
            hilog.warn(DOMAIN, TAG, 'handleKeepAliveAudioInterrupt failed: %{public}s',
              JSON.stringify(err));
          }
        );
      });
      this.keepAliveRenderer = renderer;
      await renderer.start();
      await renderer.setVolume(KEEP_ALIVE_VOLUME); // 真实输出但近乎无声
      hilog.info(DOMAIN, TAG, 'keep-alive playback started (real audio, low volume)');
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'startKeepAlivePlayback failed: %{public}s',
        JSON.stringify(err));
      // 清理可能的半成品实例，避免残留
      await this.stopKeepAlivePlayback();
    }
  }

  private async stopKeepAlivePlayback(): Promise<void> {
    const renderer = this.keepAliveRenderer;
    this.keepAliveRenderer = null;
    this.keepAlivePcm = null;
    this.keepAlivePcmPos = 0;
    if (renderer) {
      try {
        await renderer.stop();
      } catch (err) {
        // 非 running/paused 状态下 stop 会报错，可忽略
      }
      try {
        await renderer.release();
      } catch (err) {
        hilog.warn(DOMAIN, TAG, 'release keep-alive renderer failed: %{public}s',
          JSON.stringify(err));
      }
    }
    const session = this.keepAliveSession;
    this.keepAliveSession = null;
    if (session) {
      try {
        await session.deactivate();
        await session.destroy();
      } catch (err) {
        hilog.warn(DOMAIN, TAG, 'destroy keep-alive session failed: %{public}s',
          JSON.stringify(err));
      }
    }
  }

  /** 读取 rawfile/keepalive.wav 并剥掉 WAV 头，返回纯 PCM data 段 */
  private async loadKeepAlivePcm(ctx: common.UIAbilityContext): Promise<Uint8Array> {
    const raw = await ctx.resourceManager.getRawFd('keepalive.wav');
    try {
      const buf = new ArrayBuffer(raw.length);
      fs.readSync(raw.fd, buf, { offset: raw.offset, length: raw.length });
      return this.parseWavPcm(new Uint8Array(buf));
    } finally {
      fs.closeSync(raw.fd);
    }
  }

  /** 解析 WAV 容器，校验与渲染器配置一致（44100Hz/单声道/16-bit PCM）并返回 data 段 */
  private parseWavPcm(bytes: Uint8Array): Uint8Array {
    if (bytes.length < 44) {
      throw new Error('keepalive.wav: file too short');
    }
    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    if (view.getUint32(0, true) !== 0x46464952 /* 'RIFF' */) {
      throw new Error('keepalive.wav: not a RIFF file');
    }
    let channels = 0;
    let sampleRate = 0;
    let bitsPerSample = 0;
    let pos = 12;
    while (pos + 8 <= bytes.length) {
      const chunkId = view.getUint32(pos, true);
      const chunkSize = view.getUint32(pos + 4, true);
      const dataPos = pos + 8;
      if (chunkId === 0x20746d66 /* 'fmt ' */) {
        channels = view.getUint16(dataPos + 2, true);
        sampleRate = view.getUint32(dataPos + 4, true);
        bitsPerSample = view.getUint16(dataPos + 14, true);
        if (view.getUint16(dataPos, true) !== 1 /* PCM */) {
          throw new Error('keepalive.wav: encoding is not PCM');
        }
      } else if (chunkId === 0x61746164 /* 'data' */) {
        if (channels !== 1 || sampleRate !== 44100 || bitsPerSample !== 16) {
          throw new Error(
            `keepalive.wav: expect 44100Hz mono 16bit, got ${sampleRate}Hz ${channels}ch ${bitsPerSample}bit`
          );
        }
        return bytes.subarray(dataPos, Math.min(dataPos + chunkSize, bytes.length));
      }
      // 块按偶数字节对齐
      pos = dataPos + chunkSize + (chunkSize % 2);
    }
    throw new Error('keepalive.wav: data chunk not found');
  }

  /** 用保活 WAV 的 PCM 数据填满 writeData 缓冲，越界回绕实现无缝循环 */
  private fillKeepAliveData(dst: Uint8Array): void {
    const pcm = this.keepAlivePcm;
    if (!pcm || pcm.length === 0) {
      dst.fill(0); // 数据缺失时退回静音填充，保持回调有效
      return;
    }
    let written = 0;
    while (written < dst.length) {
      const chunk = Math.min(dst.length - written, pcm.length - this.keepAlivePcmPos);
      dst.set(pcm.subarray(this.keepAlivePcmPos, this.keepAlivePcmPos + chunk), written);
      written += chunk;
      this.keepAlivePcmPos = (this.keepAlivePcmPos + chunk) % pcm.length;
    }
  }

  /**
   * 系统文件选择器（DocumentViewPicker）：选中的文件复制到应用缓存目录后返回
   * [{name, path}]，Dart 侧据此构造 PlatformFile（读取 bytes 或直接用路径）。
   * 返回空数组表示用户取消或选择失败（鸿蒙 end 的 file_picker 无实现）。
   */
  private async pickFiles(call: MethodCall, result: MethodResult): Promise<void> {
    const ctx = this.context;
    if (!ctx) {
      result.success([]);
      return;
    }
    const allowMultiple = (call.argument('allowMultiple') as boolean | undefined) ?? false;
    const extensions = call.argument('allowedExtensions') as string[] | undefined;
    const picked: PickedFileItem[] = [];
    try {
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = allowMultiple ? 100 : 1;
      if (extensions && extensions.length > 0) {
        options.fileSuffixFilters = [
          extensions.map((ext: string) => ext.startsWith('.') ? ext : `.${ext}`).join(',')
        ];
      }
      const uris = await new picker.DocumentViewPicker(ctx).select(options);
      for (let i = 0; i < uris.length; i++) {
        const item = this.copyToCacheDir(ctx, uris[i], i);
        if (item) {
          picked.push(item);
        }
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'pickFiles failed: %{public}s', JSON.stringify(err));
    }
    result.success(picked);
  }

  /** 把选择器返回的 URI 复制到缓存目录，确保 Dart 侧可直接按路径读取 */
  private copyToCacheDir(
    ctx: common.UIAbilityContext,
    uri: string,
    index: number
  ): PickedFileItem | null {
    try {
      const name = this.fileNameFromUri(uri, index);
      const dst = `${ctx.cacheDir}/picked_${Date.now()}_${index}_${name}`;
      const src = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      try {
        fs.copyFileSync(src.fd, dst);
      } finally {
        fs.closeSync(src);
      }
      return { name: name, path: dst };
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'copy picked file failed: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  /** 从文件 URI 提取文件名（最后一段，URL 解码），异常时回退序号名 */
  private fileNameFromUri(uri: string, index: number): string {
    const path = uri.split('?')[0];
    const segment = path.split('/').pop() ?? '';
    const name = decodeURIComponent(segment);
    return name.length > 0 ? name : `file_${index}`;
  }

  /**
   * 系统文件保存（DocumentViewPicker.save）：用户选择保存位置后，把 Dart 侧
   * 传入的字节写入目标 URI。返回保存位置 URI；用户取消或失败返回 null。
   */
  private async saveFile(call: MethodCall, result: MethodResult): Promise<void> {
    const ctx = this.context;
    if (!ctx) {
      result.success(null);
      return;
    }
    const fileName = (call.argument('fileName') as string | undefined) ?? '';
    const bytes = call.argument('bytes') as Uint8Array | undefined;
    if (fileName.length === 0 || !bytes) {
      result.success(null);
      return;
    }
    try {
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [fileName];
      const uris = await new picker.DocumentViewPicker(ctx).save(options);
      if (!uris || uris.length === 0) {
        result.success(null);
        return;
      }
      // 拷贝出独立缓冲，规避子视图共享底层 buffer 的偏移问题
      const buffer = new ArrayBuffer(bytes.byteLength);
      new Uint8Array(buffer).set(bytes);
      const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, buffer);
      } finally {
        fs.closeSync(file);
      }
      result.success(uris[0]);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'saveFile failed: %{public}s', JSON.stringify(err));
      result.success(null);
    }
  }
}
