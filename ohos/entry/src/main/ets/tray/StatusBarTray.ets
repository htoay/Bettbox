import { common, Want } from '@kit.AbilityKit';
import { BusinessError, deviceInfo, emitter } from '@kit.BasicServicesKit';
import commonEventManager from '@ohos.commonEventManager';
import { statusBarManager } from '@kit.DeskTopExtensionKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * PC/2in1 状态栏托盘（Desktop Extension Kit）：
 * - 左键点击图标：把主窗口带回前台
 * - 右键菜单：由 Dart 侧下发菜单结构（模式/代理组/工具），菜单项通过
 *   notifyOnly + menuCode 回传 commonEvent 交给 Dart 分发
 * 本模块只允许被动态 import（模块内含 PC 专属系统模块，手机等设备加载会失败），
 * 由 AppPlugin 在检测到 2in1 设备后按需加载。
 */

const DOMAIN = 0x0001;
const TAG = 'StatusBarTray';

const ABILITY_NAME = 'EntryAbility';
const MODULE_NAME = 'entry';
const ICON_WHITE = 'tray_white.png';
const ICON_BLACK = 'tray_black.png';

/** Dart 侧下发的菜单项结构（JSON） */
interface TrayMenuItemSpec {
  label: string;
  code?: string;
  selected?: boolean;
  submenu?: TrayMenuItemSpec[];
}

interface TrayGroupSpec {
  items: TrayMenuItemSpec[];
}

interface TrayMenuSpec {
  groups: TrayGroupSpec[];
}

let installed = false;
let trayContext: common.UIAbilityContext | null = null;
let actionEventName = '';

async function loadIcon(
  context: common.UIAbilityContext,
  name: string
): Promise<image.PixelMap> {
  const content = context.resourceManager.getRawFileContentSync(name);
  const buffer = new ArrayBuffer(content.byteLength);
  new Uint8Array(buffer).set(content);
  const source = image.createImageSource(buffer);
  try {
    return await source.createPixelMap();
  } finally {
    source.release();
  }
}

/** 通过拉起自身 UIAbility 把主窗口带回前台 */
function showMainWindow(): void {
  const ctx = trayContext;
  if (!ctx) {
    return;
  }
  const want: Want = {
    bundleName: ctx.abilityInfo.bundleName,
    moduleName: ctx.abilityInfo.moduleName,
    abilityName: ctx.abilityInfo.name
  };
  ctx.startAbility(want).catch((err: BusinessError) => {
    hilog.warn(DOMAIN, TAG, 'show main window failed: %{public}s', JSON.stringify(err));
  });
}

const onIconClick = (eventData: emitter.EventData): void => {
  const data = eventData.data;
  if (data && (data['iconClickType'] as string) === 'leftClick') {
    showMainWindow();
  }
};

const onRightMenuClick = (eventData: emitter.EventData): void => {
  const data = eventData.data;
  const menuCode = data ? data['menuCode'] as string : '';
  if (menuCode.length > 0 && actionEventName.length > 0) {
    commonEventManager.publish(
      actionEventName,
      { parameters: { action: menuCode } },
      (err: BusinessError) => {
        if (err) {
          hilog.warn(DOMAIN, TAG, 'publish tray action failed: %{public}s', JSON.stringify(err));
        }
      }
    );
  }
};

function buildMenuItem(spec: TrayMenuItemSpec): statusBarManager.StatusBarMenuItem {
  const submenu = spec.submenu;
  if (submenu && submenu.length > 0) {
    const subItems: statusBarManager.StatusBarSubMenuItem[] = submenu.map(
      (item: TrayMenuItemSpec): statusBarManager.StatusBarSubMenuItem => {
        return {
          subTitle: item.label,
          menuAction: {
            abilityName: ABILITY_NAME,
            moduleName: MODULE_NAME,
            notifyOnly: true,
            menuCode: item.code ?? ''
          },
          options: { selected: item.selected ?? false }
        };
      }
    );
    return { title: spec.label, subMenu: subItems };
  }
  const code = spec.code ?? '';
  if (code.length === 0) {
    // 无动作码：点击直接拉起主窗口
    return {
      title: spec.label,
      menuAction: { abilityName: ABILITY_NAME, moduleName: MODULE_NAME }
    };
  }
  return {
    title: spec.label,
    menuAction: {
      abilityName: ABILITY_NAME,
      moduleName: MODULE_NAME,
      notifyOnly: true,
      menuCode: code
    },
    options: { selected: spec.selected ?? false }
  };
}

/** 接入状态栏图标（仅 PC/2in1；重复调用无效） */
export async function install(
  context: common.UIAbilityContext,
  eventName: string
): Promise<void> {
  if (installed || deviceInfo.deviceType !== '2in1') {
    return;
  }
  actionEventName = eventName;
  try {
    const icons: statusBarManager.StatusBarIcon = {
      white: await loadIcon(context, ICON_WHITE),
      black: await loadIcon(context, ICON_BLACK)
    };
    // abilityName 传空串：左键点击不走业务弹窗，改由 statusBarIconClick 事件处理
    const quickOperation: statusBarManager.QuickOperation = {
      abilityName: '',
      title: 'Bettbox',
      height: 1,
      moduleName: MODULE_NAME
    };
    const item: statusBarManager.StatusBarItem = {
      icons: icons,
      quickOperation: quickOperation,
      hoverTips: 'Bettbox'
    };
    statusBarManager.addToStatusBar(context, item);
    statusBarManager.on('statusBarIconClick', onIconClick);
    statusBarManager.on('rightMenuClick', onRightMenuClick);
    trayContext = context;
    installed = true;
    hilog.info(DOMAIN, TAG, 'status bar tray installed');
  } catch (err) {
    hilog.warn(DOMAIN, TAG, 'install status bar tray failed: %{public}s', JSON.stringify(err));
  }
}

/** 用 Dart 下发的菜单结构重建右键菜单（快照式，状态变化即整份替换） */
export function updateMenu(json: string): void {
  const ctx = trayContext;
  if (!installed || !ctx || json.length === 0) {
    return;
  }
  try {
    const spec = JSON.parse(json) as TrayMenuSpec;
    const menus: statusBarManager.StatusBarGroupMenu[] = spec.groups.map(
      (group: TrayGroupSpec): statusBarManager.StatusBarGroupMenu =>
        group.items.map((item: TrayMenuItemSpec) => buildMenuItem(item))
    );
    statusBarManager.updateStatusBarMenu(ctx, menus);
  } catch (err) {
    hilog.warn(DOMAIN, TAG, 'update status bar menu failed: %{public}s', JSON.stringify(err));
  }
}
