import 'dart:io';
import 'dart:ui' as ui;
import 'package:bett_box/common/common.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/svg.dart';
import 'package:xml/xml.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;

class _IconFileManager {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.bytes,
    ),
  );

  static final Map<String, Future<File?>> _inFlightDownloads = {};

  static Future<File> getCacheFile(String url) async {
    final hash = md5.convert(utf8.encode(url)).toString();
    final tempDir = await appPath.tempPath;
    final ext = url.isSvg ? '.svg' : '.img';
    final dir = Directory(path.join(tempDir, 'icon_raw_cache'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return File(path.join(dir.path, '$hash$ext'));
  }

  static Future<File?> getFileFromCache(String url) async {
    try {
      final file = await getCacheFile(url);
      if (await file.exists() && (await file.length()) > 0) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  static Future<File?> downloadFile(String url) async {
    final existing = await getFileFromCache(url);
    if (existing != null) {
      return existing;
    }

    if (_inFlightDownloads.containsKey(url)) {
      return await _inFlightDownloads[url];
    }

    final future = _downloadInternal(url);
    _inFlightDownloads[url] = future;
    try {
      return await future;
    } finally {
      _inFlightDownloads.remove(url);
    }
  }

  static Future<File?> _downloadInternal(String url) async {
    try {
      final targetFile = await getCacheFile(url);
      final tempFile = File('${targetFile.path}.tmp');

      final response = await _dio.get<List<int>>(url);
      final data = response.data;
      if (data == null || data.isEmpty) {
        return null;
      }

      await tempFile.writeAsBytes(data, flush: true);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFile.path);
      return targetFile;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeFile(String url) async {
    try {
      final file = await getCacheFile(url);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

class CommonTargetIcon extends StatefulWidget {
  final String src;
  final double size;

  const CommonTargetIcon({super.key, required this.src, required this.size});

  static final ValueNotifier<int> _cacheVersion = ValueNotifier(0);

  static Future<void> clearCache() async {
    final tempDir = await appPath.tempPath;
    for (final name in ['icon_raw_cache', 'resized_icons']) {
      final dir = Directory(path.join(tempDir, name));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
    _CommonTargetIconState._moduleFileCache.clear();
    _CommonTargetIconState._moduleSvgValidCache.clear();
    _CommonTargetIconState._moduleFailureCache.clear();
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();
    svg.cache.clear();
    _cacheVersion.value++;
  }

  @override
  State<CommonTargetIcon> createState() => _CommonTargetIconState();
}

class _CommonTargetIconState extends State<CommonTargetIcon> {
  File? _file;
  String? _cachedSrc; // Cached src
  int? _cachedSize; // Cached size
  bool _didSyncCheck = false; // Guard for didChangeDependencies

  static final Map<String, File?> _moduleFileCache = {};
  static final Map<String, bool> _moduleSvgValidCache = {};
  static final Map<String, DateTime> _moduleFailureCache = {};
  static const _maxCacheEntries = 256;
  static const _failureCooldownSeconds = 10;

  String _moduleCacheKey(int cacheSize) {
    if (widget.src.isSvg) return 'svg|${widget.src}';
    return 'bmp|${widget.src}|$cacheSize';
  }

  static void _ensureCacheLimit() {
    while (_moduleFileCache.length > _maxCacheEntries) {
      _moduleFileCache.remove(_moduleFileCache.keys.first);
    }
    while (_moduleSvgValidCache.length > _maxCacheEntries) {
      _moduleSvgValidCache.remove(_moduleSvgValidCache.keys.first);
    }
  }

  bool _shouldRetry(String mKey) {
    final failedAt = _moduleFailureCache[mKey];
    if (failedAt == null) return true;
    if (DateTime.now().difference(failedAt).inSeconds <
        _failureCooldownSeconds) {
      return false;
    }
    _moduleFailureCache.remove(mKey);
    return true;
  }

  @override
  void initState() {
    super.initState();
    CommonTargetIcon._cacheVersion.addListener(_handleCacheReset);
  }

  @override
  void dispose() {
    CommonTargetIcon._cacheVersion.removeListener(_handleCacheReset);
    super.dispose();
  }

  void _handleCacheReset() {
    if (!mounted) return;
    setState(() {
      _file = null;
      _cachedSrc = null;
      _cachedSize = null;
    });
    _syncCheckAndInit();
  }

  void _syncCheckAndInit() {
    if (widget.src.isEmpty || widget.src.getBase64 != null) return;

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheSize = (widget.size * devicePixelRatio).ceil();
    final key = _moduleCacheKey(cacheSize);

    final exactFile = _moduleFileCache[key];
    if (exactFile != null) {
      _cachedSrc = widget.src;
      _cachedSize = cacheSize;
      _file = exactFile;
      return;
    }

    final fallbackFile = _findCachedFileForSrc(widget.src);
    if (fallbackFile != null) {
      _cachedSrc = widget.src;
      _cachedSize = null;
      _file = fallbackFile;
    }
    _init(cacheSize);
  }

  @override
  void didUpdateWidget(covariant CommonTargetIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src || oldWidget.size != widget.size) {
      _file = null;
      _cachedSrc = null;
      _cachedSize = null;
      _didSyncCheck = true;
      _syncCheckAndInit();
    }
  }

  static File? _findCachedFileForSrc(String src) {
    if (src.isSvg) {
      return _moduleFileCache['svg|$src'];
    }
    for (final entry in _moduleFileCache.entries) {
      if (entry.key.startsWith('bmp|$src|') && entry.value != null) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSyncCheck) return;
    _didSyncCheck = true;
    _syncCheckAndInit();
  }

  /// Generate resized cache path
  Future<String> _getResizedCachePath(String originalPath, int size) async {
    final hash = md5.convert(utf8.encode('${originalPath}_$size')).toString();
    final tempDir = await appPath.tempPath;
    return path.join(tempDir, 'resized_icons', '$hash.png');
  }

  /// Decode, resize and cache image to disk, preserving aspect ratio
  Future<File?> _resizeAndCacheImage(File originalFile, int targetSize) async {
    try {
      final cachePath = await _getResizedCachePath(
        originalFile.path,
        targetSize,
      );
      final cacheFile = File(cachePath);

      // Return cached file if exists
      if (await cacheFile.exists()) {
        return cacheFile;
      }

      // Read original image
      final bytes = await originalFile.readAsBytes();

      // Probe original image dimensions
      final probeCodec = await ui.instantiateImageCodec(bytes);
      final probeFrame = await probeCodec.getNextFrame();
      final origImage = probeFrame.image;
      final origWidth = origImage.width;
      final origHeight = origImage.height;

      // If already small enough, no need to resize and re-encode
      if (origWidth <= targetSize && origHeight <= targetSize) {
        return originalFile;
      }

      // Calculate aspect-ratio-preserving dimensions bounded by targetSize
      final int targetWidth;
      final int targetHeight;
      if (origWidth >= origHeight) {
        targetWidth = targetSize;
        targetHeight = (origHeight * targetSize / origWidth).round().clamp(
          1,
          targetSize,
        );
      } else {
        targetHeight = targetSize;
        targetWidth = (origWidth * targetSize / origHeight).round().clamp(
          1,
          targetSize,
        );
      }

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return originalFile;
      }

      // Save to disk
      await cacheFile.parent.create(recursive: true);
      await cacheFile.writeAsBytes(byteData.buffer.asUint8List());

      return cacheFile;
    } catch (e) {
      // Resize failed, verify original file is decodable before falling back
      try {
        final bytes = await originalFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        await codec.getNextFrame();
        return originalFile;
      } catch (_) {
        return null;
      }
    }
  }

  /// Validate and sanitize SVG file
  Future<bool> _validateSvg(File file) async {
    try {
      final content = await file.readAsString();
      final trimmed = content.trim();

      // Check if content starts with valid SVG/XML tags
      if (!trimmed.startsWith('<svg') &&
          !trimmed.startsWith('<?xml') &&
          !trimmed.startsWith('<!DOCTYPE svg')) {
        commonPrint.warn('Invalid SVG: not starting with svg tag');
        return false;
      }

      // Check for HTML error pages
      if (trimmed.contains('<!DOCTYPE html>') ||
          trimmed.contains('<html>') ||
          trimmed.contains('<head>') ||
          trimmed.contains('<body>')) {
        commonPrint.warn('Invalid SVG: HTML content detected');
        return false;
      }

      // Validate XML structure
      try {
        XmlDocument.parse(content);
      } catch (e) {
        commonPrint.warn('Invalid SVG: XML parse error - $e');
        return false;
      }

      // Fix invalid font-weight values
      if (content.contains('font-weight:none') ||
          content.contains('font-weight: none')) {
        final fixed = content
            .replaceAll('font-weight:none', 'font-weight:normal')
            .replaceAll('font-weight: none', 'font-weight: normal');
        await file.writeAsString(fixed);
      }
      return true;
    } catch (e) {
      commonPrint.warn('SVG validation failed: $e');
      return false;
    }
  }

  Future<void> _init(int cacheSize) async {
    if (widget.src.isEmpty) {
      return;
    }
    if (widget.src.getBase64 != null) {
      return;
    }

    // If cached with same src and size, return directly
    if (_cachedSrc == widget.src && _cachedSize == cacheSize && _file != null) {
      return;
    }

    final mKey = _moduleCacheKey(cacheSize);

    // Check module-level cache: another instance (or a previous
    // expand/collapse) may have already loaded this URL at the same size.
    // The cached File is already display-ready — no async resize needed.
    if (_moduleFileCache.containsKey(mKey)) {
      final cachedFile = _moduleFileCache[mKey];
      if (cachedFile == null) return; // permanently invalid

      if (mounted) {
        setState(() {
          _file = cachedFile;
          _cachedSrc = widget.src;
          _cachedSize = cacheSize;
        });
      }
      return;
    }

    if (!_shouldRetry(mKey)) return;

    final cachedFile = await _IconFileManager.getFileFromCache(widget.src);
    if (cachedFile != null && mounted && widget.src.isNotEmpty) {
      await _processFile(cachedFile, cacheSize, mKey);
      return;
    }

    try {
      final file = await _IconFileManager.downloadFile(widget.src);
      if (file != null && mounted && widget.src.isNotEmpty) {
        await _processFile(file, cacheSize, mKey);
      } else {
        _moduleFailureCache[mKey] = DateTime.now();
      }
    } catch (e) {
      _moduleFailureCache[mKey] = DateTime.now();
    }
  }

  Future<void> _processFile(File file, int cacheSize, String mKey) async {
    if (widget.src.isSvg) {
      final isValid = await _validateSvg(file);
      if (!isValid) {
        await _IconFileManager.removeFile(widget.src);
        _moduleFileCache[mKey] = null;
        _moduleFailureCache.remove(mKey);
        if (mounted) {
          setState(() {
            _file = null;
            _cachedSrc = null;
            _cachedSize = null;
          });
        }
        return;
      }
      _moduleFileCache[mKey] = file;
      _moduleSvgValidCache[widget.src] = true;
      _moduleFailureCache.remove(mKey);
      _ensureCacheLimit();
      if (mounted) {
        setState(() {
          _file = file;
          _cachedSrc = widget.src;
          _cachedSize = cacheSize;
        });
      }
      return;
    }

    final displayFile = (await _resizeAndCacheImage(file, cacheSize)) ?? file;
    _moduleFileCache[mKey] = displayFile;
    _moduleFailureCache.remove(mKey);
    _ensureCacheLimit();
    if (mounted) {
      setState(() {
        _file = displayFile;
        _cachedSrc = widget.src;
        _cachedSize = cacheSize;
      });
    }
  }

  Widget _defaultIcon() {
    return Icon(IconsExt.target, size: widget.size);
  }

  Widget _buildIcon() {
    if (widget.src.isEmpty) {
      return _defaultIcon();
    }
    final base64 = widget.src.getBase64;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheSize = (widget.size * devicePixelRatio).ceil();

    if (base64 != null) {
      return Image.memory(
        base64,
        gaplessPlayback: true,
        fit: BoxFit.contain,
        errorBuilder: (_, error, _) {
          return _defaultIcon();
        },
      );
    }
    if (_file != null) {
      if (widget.src.isSvg) {
        final mKey = _moduleCacheKey(cacheSize);
        if (_moduleSvgValidCache[widget.src] == true) {
          try {
            return SvgPicture.file(
              _file!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => _defaultIcon(),
            );
          } catch (e) {
            commonPrint.warn('Failed to load SVG: $e');
            _moduleFileCache.remove(mKey);
            _moduleSvgValidCache.remove(widget.src);
            _moduleFailureCache.remove(mKey);
            return _defaultIcon();
          }
        }
        return FutureBuilder<bool>(
          future: _validateSvg(_file!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _defaultIcon();
            }
            if (snapshot.hasError || snapshot.data == false) {
              commonPrint.warn(
                'SVG validation failed in build: ${snapshot.error}',
              );
              _IconFileManager.removeFile(widget.src);
              _moduleFileCache.remove(_moduleCacheKey(cacheSize));
              _moduleSvgValidCache.remove(widget.src);
              _file = null;
              _cachedSrc = null;
              _cachedSize = null;
              return _defaultIcon();
            }
            _moduleSvgValidCache[widget.src] = true;
            try {
              return SvgPicture.file(
                _file!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => _defaultIcon(),
              );
            } catch (e) {
              commonPrint.warn('Failed to load SVG: $e');
              _IconFileManager.removeFile(widget.src);
              _moduleFileCache.remove(_moduleCacheKey(cacheSize));
              _moduleSvgValidCache.remove(widget.src);
              _file = null;
              _cachedSrc = null;
              _cachedSize = null;
              return _defaultIcon();
            }
          },
        );
      }
      final mKey = _moduleCacheKey(cacheSize);
      return Image.file(
        _file!,
        gaplessPlayback: true,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          _moduleFileCache.remove(mKey);
          _moduleFailureCache.remove(mKey);
          return _defaultIcon();
        },
      );
    }
    return _defaultIcon();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey<String>('${widget.src}_${_file?.path}'),
          child: _buildIcon(),
        ),
      ),
    );
  }
}
