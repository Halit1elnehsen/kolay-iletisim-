// ============================================================
// lib/screens/camera_screen.dart
// AR Çeviri Kamerası
// Çevrilen metni orijinal metnin tam altına yerleştirir.
// ============================================================

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/service_result.dart';
import '../models/ocr_text_line.dart';
import '../services/ocr_service.dart';
import '../theme/app_colors.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();

  // Camera
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _cameraReady = false;
  bool _cameraError = false;
  final String _viewId = 'camera-preview-${DateTime.now().millisecondsSinceEpoch}';

  // Live scan
  Timer? _liveScanTimer;
  bool _isScanning = false;
  String _liveTranslation = '';
  String _liveOriginal = '';
  bool _liveActive = true;

  // Captured photo
  Uint8List? _capturedImage;
  double _capturedImageWidth = 0;
  double _capturedImageHeight = 0;
  List<OcrTextLine> _capturedLines = [];
  bool _isProcessingCapture = false;

  // Target language
  String _targetLang = 'tr';
  final List<Map<String, String>> _languages = [
    {'code': 'tr', 'label': '🇹🇷 Türkçe'},
    {'code': 'ar', 'label': '🇸🇦 العربية'},
    {'code': 'en', 'label': '🇺🇸 English'},
    {'code': 'de', 'label': '🇩🇪 Deutsch'},
    {'code': 'fr', 'label': '🇫🇷 Français'},
    {'code': 'es', 'label': '🇪🇸 Español'},
    {'code': 'ru', 'label': '🇷🇺 Русский'},
    {'code': 'zh', 'label': '🇨🇳 中文'},
    {'code': 'ja', 'label': '🇯🇵 日本語'},
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _liveScanTimer?.cancel();
    _stopCamera();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _videoElement!,
      );

      _mediaStream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'environment',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      _videoElement!.srcObject = _mediaStream;
      await _videoElement!.play();

      if (mounted) {
        setState(() => _cameraReady = true);
        _startLiveScan();
      }
    } catch (e) {
      if (mounted) setState(() => _cameraError = true);
    }
  }

  void _stopCamera() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _mediaStream = null;
  }

  // ─── CANLI TARAMA (Her 4 saniyede) ───
  void _startLiveScan() {
    _liveScanTimer?.cancel();
    _liveScanTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_liveActive && _cameraReady && _capturedImage == null && !_isScanning) {
        _scanCurrentFrame();
      }
    });
  }

  Future<void> _scanCurrentFrame() async {
    if (_videoElement == null || _isScanning) return;
    _isScanning = true;

    try {
      final captureData = _captureFrameBytes();
      if (captureData == null) { _isScanning = false; return; }
      final bytes = captureData['bytes'] as Uint8List;

      // OCR
      final ocrResult = await OcrService.instance.extractTextFromImage(bytes);
      List<OcrTextLine>? lines;
      ocrResult.when(
        success: (l) => lines = l,
        failure: (_) {},
      );

      if (lines != null && lines!.isNotEmpty && mounted && _capturedImage == null) {
        final text = lines!.map((l) => l.text).join('\n');
        final translated = await _autoTranslate(text, _targetLang);
        if (mounted && _capturedImage == null) {
          setState(() {
            _liveOriginal = text;
            _liveTranslation = translated ?? text;
          });
        }
      }
    } catch (_) {}
    _isScanning = false;
  }

  Map<String, dynamic>? _captureFrameBytes() {
    if (_videoElement == null) return null;

    int w = _videoElement!.videoWidth;
    int h = _videoElement!.videoHeight;
    if (w == 0 || h == 0) return null;

    // Küçült
    if (w > 800) {
      final ratio = 800 / w;
      w = 800;
      h = (h * ratio).toInt();
    }

    final canvas = html.CanvasElement(width: w, height: h);
    canvas.context2D.drawImageScaled(_videoElement!, 0, 0, w, h);
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.8);
    final base64 = dataUrl.split(',').last;
    return {
      'bytes': Uint8List.fromList(List<int>.from(html.window.atob(base64).codeUnits)),
      'width': w.toDouble(),
      'height': h.toDouble(),
    };
  }

  // ─── OTOMATİK DİL ALGILAMA + ÇEVİRİ ───
  Future<String?> _autoTranslate(String text, String targetCode) async {
    if (text.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetCode&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List && json.isNotEmpty && json[0] is List) {
          final segments = json[0] as List;
          final buffer = StringBuffer();
          for (var seg in segments) {
            if (seg is List && seg.isNotEmpty) buffer.write(seg[0]);
          }
          return buffer.toString().trim();
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── FOTOĞRAF ÇEK ───
  Future<void> _capturePhoto() async {
    if (_videoElement == null || !_cameraReady) return;

    final captureData = _captureFrameBytes();
    if (captureData == null) return;

    final bytes = captureData['bytes'] as Uint8List;
    final w = captureData['width'] as double;
    final h = captureData['height'] as double;

    _processCapturedImage(bytes, w, h);
  }

  // ─── GALERİDEN SEÇ ───
  Future<void> _pickFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      
      // Get image dimensions
      final image = await decodeImageFromList(bytes);
      
      _processCapturedImage(bytes, image.width.toDouble(), image.height.toDouble());
    } catch (_) {}
  }

  Future<void> _processCapturedImage(Uint8List bytes, double w, double h) async {
    setState(() {
      _capturedImage = bytes;
      _capturedImageWidth = w;
      _capturedImageHeight = h;
      _isProcessingCapture = true;
      _capturedLines = [];
    });

    // 1. OCR ile satırları al
    final ocrResult = await OcrService.instance.extractTextFromImage(bytes);
    List<OcrTextLine>? lines;
    ocrResult.when(
      success: (l) => lines = l,
      failure: (_) {
        if (mounted) setState(() => _isProcessingCapture = false);
      },
    );

    if (lines != null && lines!.isNotEmpty && mounted) {
      // 2. Her satırı tek tek çevir
      List<OcrTextLine> translatedLines = [];
      
      // Paralel çeviri istekleri atıyoruz hız için
      final translationFutures = lines!.map((line) async {
        final translated = await _autoTranslate(line.text, _targetLang);
        return line.copyWith(translatedText: translated ?? line.text);
      });

      translatedLines = await Future.wait(translationFutures);

      if (mounted) {
        setState(() {
          _capturedLines = translatedLines;
          _isProcessingCapture = false;
        });
      }
    } else {
       if (mounted) setState(() => _isProcessingCapture = false);
    }
  }

  // ─── TEMİZLE (X butonu) ───
  void _clearCapture() {
    setState(() {
      _capturedImage = null;
      _capturedLines = [];
      _isProcessingCapture = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // ─── 1. KAMERA / FOTOĞRAF ───
          if (_cameraReady && _capturedImage == null)
            Positioned.fill(child: HtmlElementView(viewType: _viewId))
          else if (_capturedImage != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Ekrana sığacak şekilde resmi ölçekle
                  double displayWidth = constraints.maxWidth;
                  double displayHeight = constraints.maxHeight;
                  
                  // BoxFit.cover davranışı için scale hesabı:
                  double scaleX = displayWidth / _capturedImageWidth;
                  double scaleY = displayHeight / _capturedImageHeight;
                  double scale = scaleX > scaleY ? scaleX : scaleY; // Cover

                  // Resmin gerçek gösterilen boyutları
                  double scaledWidth = _capturedImageWidth * scale;
                  double scaledHeight = _capturedImageHeight * scale;
                  
                  // Cover nedeniyle merkeze hizalama (kırpılan kısım)
                  double offsetX = (displayWidth - scaledWidth) / 2;
                  double offsetY = (displayHeight - scaledHeight) / 2;

                  return Stack(
                    children: [
                      // Arka Plan Fotoğraf
                      Positioned.fill(
                        child: Image.memory(_capturedImage!, fit: BoxFit.cover),
                      ),
                      
                      // AR Metin Katmanları (Çevrilen metinler orijinalin altına/üstüne yerleşir)
                      ..._capturedLines.where((l) => l.translatedText != null).map((line) {
                        // Koordinatları ekrana göre ölçekle
                        double boxLeft = (line.left * scale) + offsetX;
                        double boxTop = (line.top * scale) + offsetY;
                        double boxWidth = line.width * scale;
                        double boxHeight = line.height * scale;
                        
                        // Metin çok küçükse ekranda okunsun diye min boyut verelim
                        double fontSize = boxHeight * 0.7;
                        if (fontSize < 12) fontSize = 12;
                        if (fontSize > 40) fontSize = 40;

                        return Positioned(
                          left: boxLeft - 10, // Biraz padding payı
                          top: boxTop + boxHeight - 4, // Orijinal metnin hemen altına hizala
                          child: Container(
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth - boxLeft),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              line.translatedText!,
                              style: TextStyle(
                                color: Colors.white, // AppColors.bgDeep
                                fontSize: fontSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }
              ),
            )
          else if (_cameraError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_rounded, size: 56, color: AppColors.accentRose),
                  const SizedBox(height: 16),
                  const Text('Kamera açılamadı', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text('Galeriden Seç', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),

          // ─── 2. İŞLEM OVERLAY ───
          if (_isProcessingCapture)
            Positioned.fill(
              child: Container(
                color: AppColors.bgDeep.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.accentCyan),
                      SizedBox(height: 16),
                      Text('Metinler algılanıp çevriliyor...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),

          // ─── 3. CANLI ÇEVİRİ OVERLAY (kamera açıkken) ───
          if (_capturedImage == null && _liveTranslation.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.accentCyan, size: 14),
                        const SizedBox(width: 6),
                        const Text('Canlı Çeviri', style: TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (_isScanning)
                          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accentCyan)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _liveTranslation,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

          // ─── 4. ÜST BAR ───
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Hedef dil seçici
                GestureDetector(
                  onTap: _showLanguagePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.translate_rounded, color: AppColors.accentCyan, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _languages.firstWhere((l) => l['code'] == _targetLang)['label']!,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // X butonu (fotoğraf varsa)
                if (_capturedImage != null)
                  GestureDetector(
                    onTap: _clearCapture,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.bgDeep.withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),

          // ─── 5. ALT BUTONLAR (Kamera açıkken) ───
          if (!_isProcessingCapture && _capturedImage == null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 90,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSideButton(Icons.photo_library_rounded, _pickFromGallery),
                  const SizedBox(width: 36),
                  // Çekim butonu
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: AppColors.accentCyan.withOpacity(0.3), blurRadius: 30)],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                  // Canlı tarama aç/kapa
                  _buildSideButton(
                    _liveActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    () => setState(() { _liveActive = !_liveActive; _liveTranslation = ''; _liveOriginal = ''; }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                const Text('Çeviri Dili Seçin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Fotoğraftaki dil otomatik algılanır', style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: _languages.map((lang) {
                      final isSelected = lang['code'] == _targetLang;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _targetLang = lang['code']!);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentCyan.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSelected ? AppColors.accentCyan.withOpacity(0.4) : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Text(lang['label']!, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
                              const Spacer(),
                              if (isSelected) const Icon(Icons.check_circle, color: AppColors.accentCyan, size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSideButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bgDeep.withOpacity(0.6),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
