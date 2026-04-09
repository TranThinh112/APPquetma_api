/// =============================================================
/// File: create_to_screen.dart
/// Mô tả: UI (giao diện) cho màn hình "Create TO" - Tạo bao hàng.
///        Logic xử lý nằm trong create_to_logic.dart.
/// =============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../../models/to_model.dart';
import 'create_to_logic.dart';
import '../PhanLoaiScreen.dart';
import '../ketqua_to_Screen.dart';
import '../../data/api_service.dart';
//co witget
class CreateTOScreen extends StatefulWidget {
  final TOModel? editTO;
  final Map<String, dynamic> user;
  const CreateTOScreen({super.key, this.editTO,required this.user});

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
  final AudioPlayer beepPlayer = AudioPlayer();
  final AudioPlayer errorPlayer = AudioPlayer();
  bool _isShowingMessage = false;
  DateTime _lastMessageTime = DateTime.now();
  String _holdingCode = "";
  DateTime _holdingStart = DateTime.now();
  Timer? _duplicateTimer;
  String _pendingDuplicateCode = "";
  bool _isProcessing = false;

  // Scanner tối ưu: unrestricted = quét liên tục, không chờ frame
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal, // ⚡ ổn định + không spam
    facing: CameraFacing.back,
    torchEnabled: false,
    returnImage: false,

    // hêm đủ format để scan nhanh hơn
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128, // SPX thường dùng
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
    ],
  );

  // Center message overlay
  String? centerMessage;
  Color? centerMessageColor;
  Timer? _messageTimer;

  // Chống quét trùng
  String? _lastScannedCode;
  DateTime _lastScannedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool isProcessing = false;


  Future<void> _initTO() async {
    await logic.initNewTO();
    setState(() {});
  }
  @override
  void initState() {
    super.initState();
    logic = CreateTOLogic(user: widget.user, editTO: widget.editTO);
    beepPlayer.setReleaseMode(ReleaseMode.stop);
    errorPlayer.setReleaseMode(ReleaseMode.stop);

    beepPlayer.setSource(AssetSource('beep.mp3'));
    errorPlayer.setSource(AssetSource('error.mp3'));


    if (widget.editTO == null) {
      _initTO(); // chỉ tạo mới khi KHÔNG edit
    }
      animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    animation = Tween<double>(begin: 0, end: 1).animate(animationController);
  }

  // ── tieng beep va erro  ──

  void _playBeep() {
    try {
      beepPlayer.stop(); // ⚡ reset nhanh
      beepPlayer.play(AssetSource('beep.mp3'));
    } catch (_) {}
  }
  void _playErrorSound() {
    try {
      errorPlayer.stop(); // ⚡ reset nhanh
      errorPlayer.play(AssetSource('error.mp3'));
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



  // ── Camera barcode callback — delay 200ms chống trùng ──
  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final code = capture.barcodes.first.rawValue?.trim() ?? "";
    if (code.isEmpty) return;

    inputController.text = code;

    _isProcessing = true;

    try {
      final response = await ApiService.scanOrder(
        id: code,
        maTO: logic.toId,
      );

      if (response['success'] == true)  {
        await Future.delayed(const Duration(milliseconds: 100));
        final to = await ApiService.getOneTO(logic.toId);

        if (to != null) {
          setState(() {
            logic.loadFromServer(to); // update trước
          });

          _playBeep();
          _showCenterMessage('Thêm mã thành công', Colors.green);
          inputController.clear();
        } else {
          _playErrorSound();
          _showCenterMessage('Không load được TO', Colors.red);
        }
        //clear trong textfiel
      } else {
        //lay tjong bao tu BE
        _playErrorSound();
        _showCenterMessage(
          response['message'] ?? 'Scan thất bại',
          Colors.red,
        );
        inputController.clear();
      }

    } catch (e) {
      print("loi real: $e");
      _playErrorSound();
      _showCenterMessage('Lỗi server', Colors.red);
    }

    await Future.delayed(const Duration(milliseconds: 200));
    _isProcessing = false;
  }

  // ── Nhập tay ──
  Future<void> _onManualInput() async {
    final text = inputController.text
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();

    print("ID: $text");

    if (text.isNotEmpty) {
      FocusScope.of(context).unfocus();
      _isProcessing = true;

      try {
        final response = await ApiService.scanOrder(
          id: text,
          maTO: logic.toId,
        );

        if (response['success'] == true) {
          final to = await ApiService.getOneTO(logic.toId);

          if (to != null) {
            setState(() {
              logic.loadFromServer(to); // update trước
            });

            _playBeep();
            _showCenterMessage('Thêm mã thành công', Colors.green);
          } else {
            _playErrorSound();
            _showCenterMessage('Không load được TO', Colors.red);
          }

        } else {
          _playErrorSound();
          _showCenterMessage(
            response['message'] ?? 'Scan thất bại',
            Colors.red,
          );
        }

      } catch (e) {
        _playErrorSound();
        _showCenterMessage('Lỗi server', Colors.red);
      }

      inputController.clear();
      _isProcessing = false;

    } else {
      _showCenterMessage('Vui lòng nhập mã vào ô trống',  Theme.of(context).colorScheme.primary);
    }
  }
  // ── Complete TO ──

  Future<void> _completeAndOpenResult() async {
    //kiem tra da packed chua, neu roi thi ko cho complet
    // if (logic.originalStatus == 'Packed') {
    //   _showCenterMessage('TO đã đóng rồi', Colors.red);
    //   return;
    // }

    if (logic.scannedCodes.isEmpty) {
      _showCenterMessage(
        'Chưa quét gói hàng nào',
        Theme.of(context).colorScheme.primary,
      );
      return;
    }
    await logic.completeTO(); // chờ server update

    // await Future.delayed(const Duration(milliseconds: 500));

    final to = await ApiService.getOneTO(logic.toId); // lấy lại data thật

    if (!mounted) return;

    if (to != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TOResultScreen(
            to: to, // truyền data chuẩn
            user: widget.user,
          ),
        ),
      );
      // neu reopen se cap nhat trang thai
      if (result == true) {
        final newTO = await ApiService.getOneTO(logic.toId);

        if (newTO != null) {
          setState(() {
            logic.loadFromServer(newTO); //  load lại trạng thái Packing
          });
        }
      }
    } else {
      _showCenterMessage('Không load được TO', Colors.red);
    }
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
                buildHeader(),
                const SizedBox(height: 5),
                // ── Header cam ──
                // ── Nội dung chính ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(),
                        const SizedBox(height: 1),
                        _buildInputRow(),
                        const SizedBox(height: 10),
                        _buildCameraPreview(),
                        const SizedBox(height: 5),
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
                        const SizedBox(height: 5),
                        _buildScannedList(),
                        const SizedBox(height: 10),
                        _buildCompleteButton(),
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
//appbar va logo, nut quay lai
  Widget buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:  Theme.of(context).colorScheme.primary,
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
                  onPressed: () {
                    //pushandremove: di trang moi va xoa het duong di
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text('Quay lại',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
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
            Text('Khối lượng: ${logic.tongKhoiLuong.toStringAsFixed(2)}/${TOModel.maxWeight} kg', style: style),
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
            backgroundColor:  Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 6,
            shadowColor:  Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
          border: Border.all(color:  Theme.of(context).colorScheme.primary!, width: 4),
          boxShadow: [
            BoxShadow(
              color:  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
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
                scanWindow: Rect.fromCenter(
                  center: Offset(130, 130),
                  width: 220,
                  height: 220,
                ),
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
  //build animation chay tu trai
  Widget buildMarqueeText(String text) {
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -1.0, end: 1.0),
        duration: const Duration(seconds: 3),
        curve: Curves.linear,
        builder: (context, value, child) {
          return FractionalTranslation(
            translation: Offset(value, 0),
            child: child,
          );
        },
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onEnd: () {}, // không loop để tránh lag
      ),
    );
  }
  Widget _buildScannedList() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          height: 180,
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
                                    final code = logic.scannedCodes[index].code;

                                    // XÓA NGAY UI (KHÔNG CHỜ SERVER)
                                    setState(() {
                                      logic.scannedCodes.removeAt(index);
                                    });

                                    // nếu hết → thoát luôn
                                    if (logic.scannedCodes.isEmpty) {
                                      Navigator.pop(context);
                                    }

                                    // gọi API ngầm
                                    await ApiService.removeOrder(
                                      id: code,
                                      maTO: logic.toId,
                                    );
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
        onPressed: _completeAndOpenResult,
        style: ElevatedButton.styleFrom(
          backgroundColor:  Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 8,
          shadowColor:  Theme.of(context).colorScheme.primary.withOpacity(0.6),
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
