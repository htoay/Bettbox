/// OHOS 适配垫片（material_ui）。
///
/// 背景：上游 v1.19.5 把 UI 从 `package:flutter/material.dart` 迁到了外部包
/// `material_ui`（Flutter 官方 material 库的再发布副本）。但那份副本里所有对
/// `TargetPlatform` 的穷举 switch 都只覆盖 android/fuchsia/iOS/linux/macOS/windows，
/// 不含 flutter_ohos 分支为枚举新增的 `TargetPlatform.ohos`，Dart 前端会直接报
/// `The type 'TargetPlatform' is not exhaustively matched ... 'TargetPlatform.ohos'`
/// 从而**无法编译**（实测 166 处，分布在 material_ui / cupertino_ui 的 40+ 文件）。
///
/// 而 flutter_ohos 自带的 material 库本身就是这份库 + ohos 分支（该工具链里有
/// 82 个文件带 `TargetPlatform.ohos` 处理）。因此这里直接 re-export 工具链自带的
/// material：上游的 import 语句逐字保持不变，鸿蒙侧天然可用。
///
/// 副作用：material_ui 相对 Flutter 官方 material 的自有改动（若有）不会被采用。
/// 等 flutter_ohos 升级到上游需要的版本（Flutter 3.47+）后，可以删掉本垫片，
/// 回到真正的 material_ui 包。
library;

// 注意 hide：flutter_ohos 的 widgets/binding.dart 里有个带 @internal 的 OHOS LTPO 枚举
// TranslateAnimationSource，re-export 会把它变成本包的公开 API 并触发
// invalid_export_of_internal_element（项目内使用数 0，故直接隐藏）。
export 'package:flutter/material.dart' hide TranslateAnimationSource;

// material_ui 是 Flutter material 库的整份再发布副本，除了 material 本身还带上了
// GlobalMaterialLocalizations 等本地化实现（其 lib/src/global_material_localizations.dart）。
// 上游代码直接 import material_ui 就能用 GlobalMaterialLocalizations，所以垫片也要把它带出来。
export 'package:flutter_localizations/flutter_localizations.dart';
