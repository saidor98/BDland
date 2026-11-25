import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';

/// Universal Mouza sheet viewer widget supporting:
/// 1) Local raster assets (`assets/...jpg`, `.png`) decoded with safe memory cap (`cacheWidth`)
/// 2) Local PDF assets (`assets/...pdf` via two-tier bounded DPI `Printing.raster` — prevents Android OOM crashes!)
/// 3) Network JPG/PNG OR Network PDF (`free.mouzamap.tech/download.aspx?...`) with throttled progress updates
/// 4) Local device filesystem files (JPG/PNG/PDF)
/// Never silently substitutes a sample sheet when an actual load fails.
class MouzaSheetImage extends StatefulWidget {
  final String source;
  final BoxFit fit;
  final int pdfPageIndex;
  final double pdfDpi;
  final int maxDecodeWidth;
  final VoidCallback? onRetry;
  final Widget? errorFallback;

  const MouzaSheetImage({
    super.key,
    required this.source,
    this.fit = BoxFit.contain,
    this.pdfPageIndex = 0,
    this.pdfDpi = 120.0,
    this.maxDecodeWidth = 2048,
    this.onRetry,
    this.errorFallback,
  });

  @override
  State<MouzaSheetImage> createState() => _MouzaSheetImageState();
}

class _MouzaSheetImageState extends State<MouzaSheetImage> {
  static final Map<String, Uint8List> _memoryCache = {};

  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _errorMessage;
  int _loadedBytes = 0;
  int? _totalBytes;
  int _reloadToken = 0;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  @override
  void didUpdateWidget(covariant MouzaSheetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.pdfPageIndex != widget.pdfPageIndex ||
        oldWidget.maxDecodeWidth != widget.maxDecodeWidth) {
      _loadSource();
    }
  }

  String get _cacheKey => '${widget.source}#p${widget.pdfPageIndex}';

  static bool _isPdfMagic(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x25 && // %
        bytes[1] == 0x50 && // P
        bytes[2] == 0x44 && // D
        bytes[3] == 0x46;   // F
  }

  Future<void> _loadSource() async {
    final epoch = ++_loadEpoch;
    final src = widget.source.trim();
    if (src.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'কোনো ম্যাপ সোর্স দেওয়া হয়নি';
        _isLoading = false;
      });
      return;
    }

    // Fast path for non-PDF bundled raster assets: direct Image.asset with safe cacheWidth
    if (src.startsWith('assets/') && !src.toLowerCase().endsWith('.pdf')) {
      if (!mounted) return;
      setState(() {
        _imageBytes = null;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    final cached = _memoryCache[_cacheKey];
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _imageBytes = cached;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _loadedBytes = 0;
      _totalBytes = null;
    });

    try {
      Uint8List rawBytes;
      if (src.startsWith('assets/')) {
        final data = await rootBundle.load(src);
        rawBytes = data.buffer.asUint8List();
      } else if (src.startsWith('http://') || src.startsWith('https://')) {
        rawBytes = await _downloadWithProgress(src, epoch);
      } else {
        final file = File(src);
        if (!await file.exists()) {
          throw Exception('ফাইল পাওয়া যায়নি: $src');
        }
        rawBytes = await file.readAsBytes();
      }

      if (epoch != _loadEpoch || !mounted) return;

      if (rawBytes.isEmpty) {
        throw Exception('ফাইলটি খালি বা ডাউনলোড অসম্পূর্ণ');
      }

      Uint8List finalImageBytes;
      if (_isPdfMagic(rawBytes) || src.toLowerCase().endsWith('.pdf')) {
        finalImageBytes = await _rasterizePdfPageSafe(rawBytes, widget.pdfPageIndex);
      } else {
        finalImageBytes = rawBytes;
      }

      if (epoch != _loadEpoch || !mounted) return;

      // Bound cache size tightly (2 entries max so high-res mouza sheets never pressure RAM)
      while (_memoryCache.length >= 2) {
        _memoryCache.remove(_memoryCache.keys.first);
      }
      _memoryCache[_cacheKey] = finalImageBytes;

      setState(() {
        _imageBytes = finalImageBytes;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (epoch != _loadEpoch || !mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<Uint8List> _downloadWithProgress(String url, int epoch) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    client.badCertificateCallback = (cert, host, port) => true;

    try {
      final uri = Uri.parse(url);
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'Mozilla/5.0 (BDLandPro Cadastral OS)');

      final resp = await req.close().timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw Exception('সার্ভার রেসপন্স ত্রুটি (HTTP ${resp.statusCode})');
      }

      final contentType = resp.headers.value('content-type') ?? '';
      if (contentType.contains('text/html')) {
        throw Exception('সার্ভার থেকে ইমেজ/PDF এর বদলে ওয়েবপেইজ রিটার্ন এসেছে');
      }

      final total = resp.contentLength > 0 ? resp.contentLength : null;
      if (mounted && epoch == _loadEpoch) {
        setState(() => _totalBytes = total);
      }

      final builder = BytesBuilder(copy: false);
      int loaded = 0;
      int lastNotifyMs = 0;
      await for (final chunk in resp) {
        if (epoch != _loadEpoch) break;
        builder.add(chunk);
        loaded += chunk.length;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (mounted && (nowMs - lastNotifyMs) >= 120) {
          lastNotifyMs = nowMs;
          setState(() => _loadedBytes = loaded);
        }
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }

  /// Safe two-tier PDF rasterization preventing native OOM crashes on large A0/A1 Mouza PDFs:
  /// Probes page size at low 42 DPI first (~3-8 MB), then caps resolution to <= maxDecodeWidth (~2048 px)
  /// instead of blindly calling dpi=150 which allocates 100-300+ MB native Pdfium bitmaps on large sheets!
  Future<Uint8List> _rasterizePdfPageSafe(Uint8List pdfBytes, int pageIndex) async {
    const double probeDpi = 42.0;
    PdfRaster? probePage;

    await for (final page in Printing.raster(
      pdfBytes,
      pages: [pageIndex],
      dpi: probeDpi,
    )) {
      probePage = page;
      break;
    }

    if (probePage == null) {
      throw Exception('PDF পেজ রেন্ডার করা সম্ভব হয়নি');
    }

    final maxSide = math.max(probePage.width, probePage.height).toDouble();
    final targetMaxPx = widget.maxDecodeWidth.toDouble().clamp(1000.0, 2200.0);

    // If probe at 42 DPI is already large (>= 1300px, e.g. A0/A1 Mouza scan), refine safely up to targetMaxPx
    final safeDpi = (probeDpi * (targetMaxPx / math.max(maxSide, 1.0))).clamp(36.0, widget.pdfDpi);

    if ((safeDpi - probeDpi).abs() < 12.0 && maxSide >= 900) {
      return await probePage.toPng();
    }

    await for (final page in Printing.raster(
      pdfBytes,
      pages: [pageIndex],
      dpi: safeDpi,
    )) {
      return await page.toPng();
    }

    return await probePage.toPng();
  }

  void _retry() {
    _memoryCache.remove(_cacheKey);
    _reloadToken++;
    _loadSource();
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    final src = widget.source.trim();
    final safeCacheWidth = widget.maxDecodeWidth.clamp(600, 2200);

    if (src.startsWith('assets/') && !src.toLowerCase().endsWith('.pdf')) {
      return Image.asset(
        src,
        key: ValueKey('asset_${src}_${safeCacheWidth}_$_reloadToken'),
        fit: widget.fit,
        cacheWidth: safeCacheWidth,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (ctx, err, stack) => widget.errorFallback ?? _buildErrorWidget('অ্যাসেট শিট লোড হয়নি'),
      );
    }

    if (_isLoading) {
      final pct = (_totalBytes != null && _totalBytes! > 0)
          ? '${(_loadedBytes / _totalBytes! * 100).clamp(0, 100).toStringAsFixed(0)}%'
          : '';
      return Container(
        padding: const EdgeInsets.all(24),
        color: const Color(0xFFFAF6EE),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGreen),
              const SizedBox(height: 14),
              Text(
                'আসল মৌজা নকশা লোড হচ্ছে... $pct',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              if (_loadedBytes > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${(_loadedBytes / 1048576).toStringAsFixed(1)} MB'
                  '${_totalBytes != null ? ' / ${(_totalBytes! / 1048576).toStringAsFixed(1)} MB' : ''}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _imageBytes == null) {
      return widget.errorFallback ?? _buildErrorWidget(_errorMessage ?? 'নকশা শিট লোড ব্যর্থ');
    }

    return Image.memory(
      _imageBytes!,
      key: ValueKey('mem_${_cacheKey}_${safeCacheWidth}_$_reloadToken'),
      fit: widget.fit,
      cacheWidth: safeCacheWidth,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (ctx, err, stack) => widget.errorFallback ?? _buildErrorWidget('ছবি ডিকোড করা যায়নি'),
    );
  }

  Widget _buildErrorWidget(String msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade400),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.redAccent, size: 40),
            const SizedBox(height: 10),
            Text(
              msg,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('পুনরায় চেষ্টা করুন (Retry)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
