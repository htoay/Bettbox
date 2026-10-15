/// OHOS 适配垫片（cupertino_ui）。
///
/// 与 `third_party/material_ui` 同理：上游 v1.19.5 把 iOS 风格 UI 迁到了外部包
/// `cupertino_ui`（Flutter 官方 cupertino 库的再发布副本），其穷举 `TargetPlatform`
/// 的 switch 不含 flutter_ohos 新增的 `TargetPlatform.ohos`，会导致 Dart 前端编译失败
/// （实测 cupertino_ui 1.0.2 有 34 处）。这里 re-export 工具链自带的 cupertino 库。
library;

export 'package:flutter/cupertino.dart' hide TranslateAnimationSource;

// 与 material_ui 垫片同理：cupertino_ui 也带本地化实现，上游代码可能直接用它。
export 'package:flutter_localizations/flutter_localizations.dart';
