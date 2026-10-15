import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import VpnPlugin from '../plugins/VpnPlugin';
import AppPlugin from '../plugins/AppPlugin';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

const DOMAIN = 0x0001;
const TAG = 'EntryAbility';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    flutterEngine.getPlugins()?.add(new VpnPlugin(this.context));
    flutterEngine.getPlugins()?.add(new AppPlugin(this.context));
  }

  /**
   * 冷启动入口：可能来自桌面图标（want.uri 为空），也可能来自 clash://install-config 深链。
   * 深链在冷启动时到得比 Flutter 引擎还早，AppPlugin 会先缓存，等通道就绪再投给 Dart。
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onCreate(want, launchParam);
    this.handleAppLink(want);
  }

  /** 应用已在运行时再次被深链唤起：同样要接管，否则订阅链接会被静默丢弃。 */
  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParams);
    this.handleAppLink(want);
  }

  private handleAppLink(want: Want): void {
    const uri: string | undefined = want?.uri;
    if (!uri) {
      return;
    }
    // 用 warn 而非 info：release 包（app.json5 debug:false）的 info 级 hilog 会被系统过滤。
    // 深链是用户主动触发且低频的事件，留痕比省这一行更有价值（排障时先看这行有没有）。
    hilog.warn(DOMAIN, TAG, 'handleAppLink: %{public}s', uri);
    AppPlugin.deliverAppLink(uri);
  }

  /**
   * Dart 的 SystemNavigator.pop()（应用内"退出"）走这里。
   * FlutterAbility 默认返回 false，引擎随即退化为 router.back()，
   * 结果是"退出"只停掉代理与核心、应用进程仍在后台运行。
   */
  onBackground(): void {
    // 必须调用基类实现：FlutterAbility.onBackground() 会通过 delegate.onHide()
    // 通知 Flutter 引擎生命周期。漏掉它会导致引擎收不到前后台事件、视图不渲染
    // （表现为打开应用即卡死/黑屏）。
    super.onBackground();
    // 用 warn 而非 info：release 包（app.json5 debug:false）的 info 级 hilog 会被
    // 系统过滤，真机上不可见；保活是后台断网的第一嫌疑点，这一行必须留痕。
    hilog.warn(DOMAIN, TAG, 'onBackground: ensure keep-alive long task');
    AppPlugin.ensureKeepAliveFromBackground(this.context).catch((err: Error) => {
      hilog.warn(0x0001, 'EntryAbility', 'ensure keep-alive failed: %{public}s',
        JSON.stringify(err));
    });
  }

  onForeground(): void {
    // 同上：基类会调用 delegate.onShow()，漏掉会导致 Flutter 视图不渲染
    super.onForeground();
    hilog.info(0x0001, 'EntryAbility', 'onForeground');
  }

  popSystemNavigator(): boolean {
    this.context.terminateSelf().catch((err: BusinessError) => {
      hilog.warn(DOMAIN, TAG, 'terminateSelf failed: %{public}s', JSON.stringify(err));
    });
    return true;
  }
}
