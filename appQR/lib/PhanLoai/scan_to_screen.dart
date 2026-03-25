/// =============================================================
/// File: scan_to_screen.dart
/// Mô tả: UI (giao diện) cho màn hình "Scan TO" - Quét mã bao hàng.
///        Logic xử lý nằm trong scan_to_logic.dart.
/// =============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'scan_to_logic.dart';

class ScanTOScreen extends StatefulWidget {
  const ScanTOScreen({super.key});

  @override
  State<ScanTOScreen> createState() => _ScanTOScreenState();
}

class _ScanTOScreenState extends State<ScanTOScreen>
    with SingleTickerProviderStateMixin {
  final ScanTOLogic logic = ScanTOLogic();

  late AnimationController animationController;
  late Animation<double> animation;

  final TextEditingController inputController = TextEditingController();
  final AudioPlayer player = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  // Scanner tối ưu: unrestricted = quét liên tục
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    facing: CameraFacing.back,
    returnImage: false,
    formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13, BarcodeFormat.code128],
  );

  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Cache audio trước để phát nhanh hơn
    player.setSourceAsset('beep.mp3');

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    animation = Tween<double>(begin: 0, end: 1).animate(animationController);
  }

  // ── Audio ──

  Future<void> _playBeep() async {
    try {
      await player.stop();
      await player.play(AssetSource('beep.mp3'));
    } catch (_) {}
  }

  Future<void> _playErrorSound() async {
    try {
      await player.stop();
      await player.play(AssetSource('error.mp3'));
    } catch (_) {}
  }

  // ── Xử lý kết quả quét ──

  Future<void> _handleResult(ScanTOResult result) async {
    switch (result) {
      case ScanTOResult.success:
        await _playBeep(); // Beep NGAY khi thành công
        setState(() {});
        break;

      case ScanTOResult.duplicate:
        await _playErrorSound();
        break;

      case ScanTOResult.invalidFormat:
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearMaterialBanners();
          messenger.showMaterialBanner(
            const MaterialBanner(
              content: Text("Lỗi vui lòng quét lại",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red,
              leading: Icon(Icons.error, color: Colors.white),
              actions: [SizedBox()],
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            messenger.clearMaterialBanners();
          });
        }
        await _playErrorSound();
        break;

      case ScanTOResult.empty:
        break;
    }
  }

  // ── Camera barcode callback — delay 200ms chống trùng ──

  void _handleBarcode(BarcodeCapture capture) async {
    if (isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final newValue = barcode.rawValue?.trim() ?? "";
    if (newValue.isEmpty) return;

    isProcessing = true;
    final result = logic.processCode(newValue, barcode.format.name);
    await _handleResult(result);

    // Delay 200ms — nhanh hơn cũ (900ms)
    await Future.delayed(const Duration(milliseconds: 200));
    isProcessing = false;
  }

  // ── Quét từ gallery ──

  Future<void> _scanFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final BarcodeCapture? capture = await controller.analyzeImage(image.path);
    if (capture != null && capture.barcodes.isNotEmpty) {
      final barcode = capture.barcodes.first;
      final newValue = barcode.rawValue?.trim() ?? "";
      if (newValue.isNotEmpty) {
        isProcessing = true;
        final result = logic.processCode(newValue, barcode.format.name);
        await _handleResult(result);
        isProcessing = false;
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã hợp lệ trong ảnh'),
          backgroundColor: Colors.red,
        ),
      );
    }
    await _playErrorSound();
  }

  @override
  void dispose() {
    controller.dispose();
    animationController.dispose();
    inputController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header cam ──
            _buildHeader(),
            // ── Nội dung chính ──
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputSection(isDark),
                    const SizedBox(height: 24),
                    _buildCameraPreview(isDark),
                    const SizedBox(height: 10),
                    Center(
                      child: Text('Quét Mã',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          )),
                    ),
                    const SizedBox(height: 24),
                    _buildResultSection(isDark),
                    const SizedBox(height: 30),
                    _buildCompleteButton(isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // UI Components
  // ══════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange[600],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text('Quay lại',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  onPressed: _scanFromGallery,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: const [
                Icon(Icons.inventory_2, size: 50, color: Colors.white),
                SizedBox(height: 8),
                Text('SPX Express',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dữ liệu input:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: InputDecoration(
                  hintText: 'Nhập dữ liệu...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.orange[600]!, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                final text = inputController.text.trim();
                if (text.isNotEmpty) {
                  FocusScope.of(context).unfocus();
                  isProcessing = true;
                  final result = logic.processCode(text, 'Manual Input');
                  await _handleResult(result);
                  inputController.clear();
                  isProcessing = false;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập mã vào ô trống'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 6,
                shadowColor: Colors.orange.withOpacity(0.5),
              ),
              child: const Text('Confirm',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCameraPreview(bool isDark) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange[600]!, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.15),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              MobileScanner(
                controller: controller,
                onDetect: _handleBarcode,
              ),
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Positioned(
                    top: animation.value * 248,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0),
                            Colors.orange,
                            Colors.orange.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Center(
                child: Icon(Icons.camera_alt_outlined,
                    size: 60,
                    color: Colors.white.withOpacity(0.3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dữ liệu quét:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey[600],
              )),
          const SizedBox(height: 6),
          Text(
            logic.result.isEmpty
                ? 'Đưa camera vào mã để quét...'
                : logic.result,
            style: TextStyle(
              fontSize: 17,
              fontWeight: logic.result.isEmpty
                  ? FontWeight.normal
                  : FontWeight.w600,
              color: logic.result.isEmpty
                  ? (isDark ? Colors.grey[500] : Colors.grey[400])
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 4,
          shadowColor: Colors.orange.withOpacity(0.4),
        ),
        child: const Text('Complete',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      ),
    );
  }
}
