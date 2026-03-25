/// =============================================================
/// File: create_to_screen.dart
/// Mô tả: UI (giao diện) cho màn hình "Create TO" - Tạo bao hàng.
///        Logic xử lý nằm trong create_to_logic.dart.
/// =============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/to_model.dart';
import 'create_to_logic.dart';
import 'PhanLoaiScreen.dart';

class CreateTOScreen extends StatefulWidget {
  final TOModel? editTO;
  final Map<String, dynamic>? user;
  const CreateTOScreen({super.key, this.editTO, this.user});

  @override
  State<CreateTOScreen> createState() => _CreateTOScreenState();
}

class _CreateTOScreenState extends State<CreateTOScreen>
    with SingleTickerProviderStateMixin {
  late CreateTOLogic logic;
  bool _justSuccess = false;

  late AnimationController animationController;
  late Animation<double> animation;

  final ScrollController listScrollController = ScrollController();
  final FocusNode inputFocus = FocusNode();
  final TextEditingController inputController = TextEditingController();
  final AudioPlayer player = AudioPlayer();
  final ImagePicker _picker = ImagePicker();

  // Scanner tối ưu: unrestricted = quét liên tục, không chờ frame
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    facing: CameraFacing.back,
    returnImage: false,
    formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13, BarcodeFormat.code128],
  );

  // Center message overlay
  String? centerMessage;
  Color? centerMessageColor;
  Timer? _messageTimer;

  // Chống quét trùng
  String? _lastScannedCode;
  DateTime _lastScannedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    logic = CreateTOLogic(user: widget.user, editTO: widget.editTO);

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

  // ── Message overlay ──

  void _showCenterMessage(String text, Color color,
      {Duration duration = const Duration(milliseconds: 900)}) {
    _messageTimer?.cancel();
    setState(() {
      centerMessage = text;
      centerMessageColor = color;
    });
    _messageTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() => centerMessage = null);
    });
  }

  // ── Xử lý kết quả quét ──

  Future<void> _handleScanResult(ScanResult result) async {
    switch (result) {
      case ScanResult.success:
        await _playBeep(); // Beep NGAY khi thành công
        _justSuccess = true;
        _showCenterMessage('Thêm mã thành công', Colors.green);
        setState(() {});
        _scrollToTop();
        Future.delayed(const Duration(milliseconds: 500), () {
          _justSuccess = false;
        });
        break;

      case ScanResult.autoComplete:
        await _playBeep();
        _showCenterMessage('TO đã đầy tự động đóng TO', Colors.green);
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context);
        break;

      case ScanResult.empty:
        _showCenterMessage('Mã trống vui lòng quét lại', Colors.orange);
        break;
      case ScanResult.invalidFormat:
        _showCenterMessage('Mã không hợp lệ vui lòng quét lại', Colors.red);
        await _playErrorSound();
        break;
      case ScanResult.duplicate:
        _showCenterMessage('Mã đã quét rồi', Colors.red);
        await _playErrorSound();
        break;
      case ScanResult.notFound:
        _showCenterMessage('Không tìm thấy đơn hàng này', Colors.red);
        await _playErrorSound();
        break;
      case ScanResult.wrongStation:
        _showCenterMessage('Khác station thử lại', Colors.red);
        await _playErrorSound();
        break;
      case ScanResult.overWeightNewTO:
        await _playBeep(); // Đơn hàng đã được nhận vào TO mới
        _showCenterMessage(
            'TO cũ đã đóng tự tạo TO mới: ${logic.toId}', Colors.blue,
            duration: const Duration(milliseconds: 1500));
        setState(() {});
        _scrollToTop();
        break;
      case ScanResult.maxItems:
        _showCenterMessage(
            'Đã đạt tối đa ${TOModel.maxGoiHang} gói hàng', Colors.red);
        await _playErrorSound();
        break;
      case ScanResult.alreadyInTO:
        _showCenterMessage('Mã này đã nằm trong TO khác', Colors.red);
        await _playErrorSound();
        break;
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (listScrollController.hasClients) {
        listScrollController.animateTo(0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut);
      }
    });
  }

  // ── Camera barcode callback — delay 200ms chống trùng ──

  void _handleBarcode(BarcodeCapture capture) async {
    if (isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final newValue = barcode.rawValue?.trim() ?? "";
    if (newValue.isEmpty) return;

    // Chống quét trùng liên tục
    final now = DateTime.now();
    if (newValue == _lastScannedCode &&
        now.difference(_lastScannedAt).inMilliseconds < 500) {
      return;
    }
    _lastScannedCode = newValue;
    _lastScannedAt = now;

    isProcessing = true;
    try {
      final result = await logic.processCode(newValue);
      await _handleScanResult(result);
    } catch (error) {
      if (!_justSuccess) {
        _showCenterMessage('Lỗi quét mã thử lại', Colors.red);
        await _playErrorSound();
      }
    } finally {
      // Delay 200ms — đủ chống duplicate, nhanh hơn cũ (600ms)
      await Future.delayed(const Duration(milliseconds: 200));
      isProcessing = false;
    }
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
        try {
          final result = await logic.processCode(newValue);
          await _handleScanResult(result);
        } finally {
          isProcessing = false;
        }
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã hợp lệ trong ảnh.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    await _playErrorSound();
  }

  // ── Nhập tay ──

  Future<void> _onManualInput() async {
    final text = inputController.text.trim();
    if (text.isNotEmpty) {
      FocusScope.of(context).unfocus();
      isProcessing = true;
      final result = await logic.processCode(text);
      await _handleScanResult(result);
      inputController.clear();
      isProcessing = false;
    } else {
      _showCenterMessage('Vui lòng nhập mã vào ô trống', Colors.orange);
    }
  }

  // ── Complete TO ──

  Future<void> _completeAndCloseTo() async {
    if (logic.scannedCodes.isEmpty) {
      _showCenterMessage('Chưa quét gói hàng nào', Colors.orange);
      return;
    }
    await logic.completeTO();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    controller.dispose();
    animationController.dispose();
    listScrollController.dispose();
    inputFocus.dispose();
    inputController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header cam ──
                _buildHeader(),
                // ── Nội dung chính ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(),
                        const SizedBox(height: 12),
                        _buildInputRow(),
                        const SizedBox(height: 24),
                        _buildCameraPreview(),
                        const SizedBox(height: 10),
                        Center(
                          child: Text('Quét Mã',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              )),
                        ),
                        const SizedBox(height: 24),
                        _buildScannedList(),
                        const SizedBox(height: 24),
                        _buildCompleteButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildCenterMessageOverlay(),
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

  Widget _buildInfoRow() {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final style = TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: textColor);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TO ID: ${logic.toId}', style: style),
            Text(
                'Số lượng: ${logic.scannedCodes.length}/${TOModel.maxGoiHang}',
                style: style),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Station: ${logic.station}', style: style),
            Text(
                'Khối lượng: ${logic.tongKhoiLuong.toStringAsFixed(2)}/${TOModel.maxWeight} kg',
                style: style),
          ],
        ),
        const SizedBox(height: 4),
        Row(children: [Text('Packer: ${logic.packer}', style: style)]),
      ],
    );
  }

  Widget _buildInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Dữ liệu input:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            )),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: inputController,
            focusNode: inputFocus,
            decoration: InputDecoration(
              hintText: 'Nhập dữ liệu...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.black)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Colors.black, width: 2)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _onManualInput,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 6,
            shadowColor: Colors.orange.withOpacity(0.5),
          ),
          child: const Text('Confirm',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange[600]!, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.15),
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
                            Colors.orange.withValues(alpha: 0),
                            Colors.orange,
                            Colors.orange.withValues(alpha: 0),
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
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannedList() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          height: 260,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mã đơn',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Expanded(
                        flex: 4,
                        child: Text('Mã',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))),
                    Expanded(
                        flex: 2,
                        child: Text('Thời gian',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))),
                    Expanded(
                        flex: 2,
                        child: Text('Khối lượng',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))),
                    SizedBox(width: 24),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: logic.scannedCodes.isEmpty
                    ? const Center(
                        child: Text('Đưa camera vào mã để quét...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, color: Colors.black)))
                    : ListView.builder(
                        controller: listScrollController,
                        itemCount: logic.scannedCodes.length,
                        itemBuilder: (context, index) {
                          final item = logic.scannedCodes[index];
                          final timeStr =
                              DateFormat('HH:mm:ss').format(item.timestamp);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: SelectableText(item.code,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(timeStr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                      '${item.weight.toStringAsFixed(2)} kg',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87)),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await logic.removeItem(index);
                                    if (!mounted) return;
                                    if (logic.scannedCodes.isEmpty) {
                                      // TO đã bị xóa vì hết đơn hàng
                                      Navigator.pop(context);
                                      return;
                                    }
                                    setState(() {});
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(Icons.close,
                                        size: 18, color: Colors.red[400]),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _completeAndCloseTo,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
          shadowColor: Colors.orange.withOpacity(0.6),
        ),
        child: const Text('Complete',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      ),
    );
  }

  Widget _buildCenterMessageOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: centerMessage == null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: centerMessage == null ? 0.0 : 1.0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (centerMessageColor ?? Colors.black87)
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                centerMessage ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
