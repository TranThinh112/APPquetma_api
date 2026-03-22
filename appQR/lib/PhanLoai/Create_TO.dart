/// =============================================================
/// File: tao_bao_hang_screen.dart (CẬP NHẬP)
/// Mô tả: Màn hình "Create TO" - Tạo bao hàng lớn.
///
/// Thay đổi mới:
///   - Tối đa 5 kiện/bao (thay vì 15)
///   - Tối đa 10KG/bao
///   - Kiểm tra station (địa điểm) phải giống đơn hàng đầu tiên
///   - Tự động đóng TO khi đủ 5 kiện hoặc 10KG
///   - Từ chối đơn có station khác (không tạo TO mới)
///   - Lưu vào database (TODatabase)
/// =============================================================
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/to_model.dart';
import '../data/order_dtb.dart';
import '../data/to_database.dart';
import '../data/api_service.dart';
import 'PhanLoaiScreen.dart';
import 'package:flutter/foundation.dart';


class ScannedItem {
  final String code;
  final DateTime timestamp;
  final double weight;

  ScannedItem({
    required this.code,
    required this.timestamp,
    required this.weight,
  });
}

class CreateTO extends StatefulWidget {
  /// Nếu truyền editTO vào → chế độ chỉnh sửa (load dữ liệu cũ)
  final TOModel? editTO;
  final Map<String, dynamic>? user; //packer
  const CreateTO({super.key, this.editTO, this.user});

  @override
  State<CreateTO> createState() => _CreateTOState();
}

class _CreateTOState extends State<CreateTO>
    with SingleTickerProviderStateMixin {
  bool _justSuccess = false;
  double TongKhoiLuong = 0;
  String station = "";
  String _stationBanDau = ""; // Lưu station của đơn hàng đầu tiên
  String result = "";
  String type = "";
  final List<ScannedItem> scannedCodes = [];
  late String packer;
  late String toId;
  String _originalStatus = 'Packing';
  late DateTime _createdAt;
  DateTime? _completedAt;
  late AnimationController animationController;
  late Animation<double> animation;

  // Scroll + input animation helpers
  final ScrollController listScrollController = ScrollController();
  final FocusNode inputFocus = FocusNode();
  String animatedText = "";

  String? centerMessage;
  Color? centerMessageColor;
  Timer? _messageTimer;

  String? _lastScannedCode;
  DateTime _lastScannedAt = DateTime.fromMillisecondsSinceEpoch(0);

  final TextEditingController inputController = TextEditingController();
  final AudioPlayer player = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    returnImage: false,
    formats: [BarcodeFormat.qrCode, BarcodeFormat.ean13, BarcodeFormat.code128],
  );

  /// Sinh mã TO ID: TO + ngày hiện tại ddMMyy + 4 ký tự ngẫu nhiên (chữ + số)
  /// Ví dụ: TO150326AB1X
  String _generateTOId() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyMMdd').format(now);
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final rand = String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
    return 'TO$dateStr$rand';
  }

  /// Cập nhật TO trong database mỗi khi có thay đổi (quét mã, xóa mã, đổi địa chỉ)
  Future<void> _updateTOInDatabase() async {
    // ❗ CHẶN SQLite trên Web
    if (kIsWeb) {
      print("🌐 Web → bỏ qua SQLite");
      return;
    }
    try {
      final updated = TOModel(
        maTO: toId,
        danhSachGoiHang: scannedCodes.map((item) => item.code).toList(),
        diaDiemGiaoHang: station,
        trangThai: _originalStatus,
        totalWeight: TongKhoiLuong,
        ngayTao: _createdAt,
        completeTime: _completedAt,
      );
      print("💾 Lưu DB local");
      await TODatabase.instance.updateTO(updated);
    } catch (e) {
      // ❗ KHÔNG cho crash lan ra ngoài
      print("⚠️ Lỗi SQLite nhưng bỏ qua: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    packer = widget.user?['username'] ?? 'unknown'; // ✅ lấy user
    final editTO = widget.editTO;
    if (editTO != null) {
      // Chế độ chỉnh sửa → load dữ liệu cũ
      toId = editTO.maTO;
      _originalStatus = editTO.trangThai;
      _createdAt = editTO.ngayTao;
      _completedAt = editTO.completeTime;
      _stationBanDau = editTO.diaDiemGiaoHang;
      station = editTO.diaDiemGiaoHang;
      TongKhoiLuong = editTO.totalWeight;
      scannedCodes.addAll(
        editTO.danhSachGoiHang.asMap().entries.map((entry) {
          int idx = entry.key;
          String code = entry.value;
          return ScannedItem(
            code: code,
            timestamp: DateTime.now().subtract(Duration(seconds: idx)),
            weight: 0,
          );
        }),
      );
    } else {
      // Chế độ tạo mới → sinh TO ID mới + lưu vào database
      toId = _generateTOId();
      _createdAt = DateTime.now();
      TODatabase.instance.addTO(
        TOModel(
          maTO: toId,
          danhSachGoiHang: [],
          diaDiemGiaoHang: '',
          trangThai: 'Packing',
          packer: packer,
          totalWeight: 0,
          ngayTao: _createdAt,
        ),
      );
    }

    // Lắng nghe thay đổi địa chỉ → cập nhật TO

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    animation = Tween<double>(begin: 0, end: 1).animate(animationController);
  }

  /// Kiểm tra định dạng mã gói hàng nhỏ: SPXVN06 + 8-10 chữ số (linh hoạt)
  /// Ví dụ hợp lệ: SPXVN061234567890 hoặc SPXVN0612345678
  bool isValidSPX(String code) {
    final regex = RegExp(r'^SPXVN06\d{8,10}$', caseSensitive: false);
    if (!regex.hasMatch(code.trim())) {
      print('❌ Format lỗi: "$code" không khớp SPXVN06 + 8-10 chữ số');
      return false;
    }
    print('✅ Format hợp lệ: "$code"');
    return true;
  }

  /// Animation: hiển thị dần mã quét vào input để người dùng thấy
  Future<void> _animateScanText(String code) async {
    if (!mounted) return;
    inputFocus.requestFocus();

    final batchSize = 2;
    final stepDelay = const Duration(milliseconds: 25);
    for (int end = batchSize; end <= code.length; end += batchSize) {
      if (!mounted) return;
      final nowText = code.substring(0, end);
      inputController.text = nowText;
      inputController.selection = TextSelection(baseOffset: 0, extentOffset: nowText.length);
      setState(() {
        animatedText = nowText;
      });
      await Future.delayed(stepDelay);
    }

    if (!mounted) return;
    inputController.text = code;
    inputController.selection = TextSelection(baseOffset: 0, extentOffset: code.length);
    setState(() {
      animatedText = code;
    });
  }

  Future<void> _playBeep() async {
    try {
      await player.stop();
      await player.play(AssetSource('beep.mp3'));
    } catch (_) {
      // ignore audio errors
    }
  }

  Future<void> _playErrorSound() async {
    try {
      await player.stop();
      await player.play(AssetSource('error.mp3'));
    } catch (_) {
      // ignore audio errors
    }
  }

  bool isProcessing = false;

  void _showCenterMessage(
      String text,
      Color color, {
        Duration duration = const Duration(milliseconds: 900),
      }) {
    print("📢 SHOW MESSAGE: $text");
    _messageTimer?.cancel();
    setState(() {
      centerMessage = text;
      centerMessageColor = color;
    });

    _messageTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        centerMessage = null;
      });
    });
  }

  /// Xử lý mã được quét hoặc nhập tay:
  /// 1. Kiểm tra định dạng SPXVN06 hợp lệ
  /// 2. Kiểm tra mã có trong database
  /// 3. Kiểm tra station (địa điểm) - phải cùng với đơn hàng đầu tiên
  /// 4. Kiểm tra mã đã quét trước đó (trùng lặp)
  /// 5. Kiểm tra trọng lượng không vượt 10KG
  /// 6. Kiểm tra không vượt 5 kiện
  Future<void> _processCode(String code, String codeType) async {
    code = code.trim().toUpperCase();
    print('\n🔍 === BẮT ĐẦU XỬ LÝ MÃ ===');
    print('📝 Mã quét: "$code"');
    // print('📊 Type: $codeType');

    if (code.isEmpty) {
      _showCenterMessage('Mã trống, vui lòng quét lại.', Colors.orange);
      print('❌ Lý do: Mã trống');
      return;
    }

    if (!isValidSPX(code)) {
      _showCenterMessage('Mã không hợp lệ, vui lòng quét lại.', Colors.red);
      await _playErrorSound();
      print('❌ Lý do: Định dạng không hợp lệ (phải SPXVN06 + 8-10 chữ số)');
      return;
    }

    // Kiểm tra mã đã quét trước đó
    if (scannedCodes.any((item) => item.code == code)) {
      _showCenterMessage('Mã đã quét rồi!', Colors.red);
      await _playErrorSound();
      print('❌ Lý do: Mã đã quét trước đó (trùng lặp)');
      return;
    }

    print('🌐 Tìm kiếm mã qua API...');
    final order = await ApiService.getOrder(code);
    //tìm log trả về
    print("🌐 API RESPONSE: $order");
    print("TYPE: ${order.runtimeType}");

    if (order == null) {
      _showCenterMessage('Không tìm thấy đơn hàng này!', Colors.red);
      await _playErrorSound();
      print('❌ Lý do: Mã không tồn tại trong server');
      return;
    }

    print("API raw data: $order");

    final orderStation = order['station']?.toString().trim() ?? "";
    final itemWeight = double.tryParse(order['weight'].toString()) ?? 0.0;

    print('📍 Station của mã: "$orderStation"');
    print('⚖️ Trọng lượng: $itemWeight kg');

    // 🔴 Kiểm tra station - nếu là đơn hàng đầu tiên → lưu station
    if (_stationBanDau.isEmpty) {
      _stationBanDau = orderStation;
      station = orderStation;
      print('✅ Đặt station ban đầu: "$_stationBanDau"');
      setState(() {});
    }

    // 🔴 Kiểm tra station khác nhau → TỪCHỐI (không nhận đơn, không tạo TO mới)
    if (orderStation != _stationBanDau) {
      _showCenterMessage(
        'Khác Sort. Thử lại',
        Colors.red,
      );
      await _playErrorSound();
      print('❌ Lý do: Station khác nhau - Từ chỗi đơn');
      print('   - Station mã này: $orderStation');
      print('   - Station TO hiện tại: $_stationBanDau');
      print('   - TO này chỉ nhận đơn đi: $_stationBanDau');
      return;
    }

    // 🔴 Kiểm tra trọng lượng không vượt 10KG
    print(
      '⚖️ Kiểm tra trọng lượng: $TongKhoiLuong + $itemWeight = ${TongKhoiLuong + itemWeight} / ${TOModel.maxWeight}',
    );
    if (TongKhoiLuong + itemWeight > TOModel.maxWeight) {
      _showCenterMessage('Thêm mã này sẽ vượt 10KG! TO đầy rồi.', Colors.red);
      await _playErrorSound();
      print('❌ Lý do: Vượt trọng lượng tối đa (10 kg)');
      print('   - Trọng lượng hiện tại: $TongKhoiLuong kg');
      print('   - Trọng lượng mã này: $itemWeight kg');
      print('   - Tổng sẽ là: ${TongKhoiLuong + itemWeight} kg (> 10 kg)');
      return;
    }

    // 🔴 Kiểm tra đã đạt tối đa 5 gói hàng chưa
    print(
      '📦 Kiểm tra số lượng: ${scannedCodes.length} / ${TOModel.maxGoiHang}',
    );
    if (scannedCodes.length >= TOModel.maxGoiHang) {
      _showCenterMessage(
        'Đã đạt tối đa ${TOModel.maxGoiHang} gói hàng! TO đầy rồi.',
        Colors.red,
      );
      await _playErrorSound();
      print('❌ Lý do: Đạt tối đa số lượng kiện (5 kiện)');
      return;
    }

    // ✅ Tất cả checks pass → thêm mã vào list
    print('✅✅✅ MÃ HỢP LỆ! Thêm vào TO...');

    // Hiệu ứng show mã vào ô input giống quét
    await _animateScanText(code);

    setState(() {
      result = code;
      type = codeType;
      TongKhoiLuong += itemWeight;
      // Thêm mã mới lên trên cùng
      scannedCodes.insert(
        0,
        ScannedItem(code: code, timestamp: DateTime.now(), weight: itemWeight),
      );
    });

    print('📝 Cập nhật trạng thái:');
    print(
      '   - Số lượng hiện tại: ${scannedCodes.length} / ${TOModel.maxGoiHang}',
    );
    print(
      '   - Trọng lượng hiện tại: $TongKhoiLuong / ${TOModel.maxWeight} kg',
    );

    // Cuộl lên đầu (mã mới) nếu có thể
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (listScrollController.hasClients) {
        listScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    // Cập nhật TO vào database
    await _updateTOInDatabase();

    // 🔴 Kiểm tra xem đã đủ 5 kiện hay 10KG chưa → tự động đóng TO
    if (scannedCodes.length >= TOModel.maxGoiHang ||
        TongKhoiLuong >= TOModel.maxWeight) {
      _showCenterMessage('TO đã đầy! Tự động đóng TO.', Colors.green);
      print('⚠️ TO đã đầy! Tự động đóng TO hiện tại');
      await Future.delayed(const Duration(milliseconds: 500));

      // Đóng TO hiện tại
      await _completeAndCloseTo();
      return;
    }

    await _playBeep();
    _justSuccess = true; // 🔥 thêm dòng này
    _showCenterMessage('Thêm mã thành công', Colors.green);
    print('✅ Hoàn tất! Mã được thêm thành công');
    print('🔍 === KẾT THÚC XỬ LÝ MÃ ===\n');

    Future.delayed(const Duration(milliseconds: 500), () {
      _justSuccess = false;
    });
  }


  /// Hàm đóng TO và trở lại màn hình trước
  Future<void> _completeAndCloseTo() async {
    if (scannedCodes.isEmpty) {
      _showCenterMessage('Chưa quét gói hàng nào!', Colors.orange);
      return;
    }

    _originalStatus = 'Packed';
    _completedAt = DateTime.now();

    final toComplete = TOModel(
      maTO: toId,
      danhSachGoiHang: scannedCodes.map((item) => item.code).toList(),
      diaDiemGiaoHang: station,
      trangThai: _originalStatus,
      packer: packer,
      totalWeight: TongKhoiLuong,
      ngayTao: _createdAt,
      completeTime: _completedAt,
    );

    print(
      'DEBUG: completeAndClose-> ${toComplete.maTO}, status=${toComplete.trangThai}, complete=${toComplete.completeTime}, daytao=${toComplete.ngayTao}',
    );

    await TODatabase.instance.updateTO(toComplete);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// Callback khi camera phát hiện barcode
  /// Chống quét liên tục bằng cờ isProcessing + delay 900ms
  void _handleBarcode(BarcodeCapture capture) async {
    if (isProcessing) return;

    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final newValue = barcode.rawValue?.trim() ?? "";

    if (newValue.isEmpty) return;

    final now = DateTime.now();
    if (newValue == _lastScannedCode &&
        now.difference(_lastScannedAt).inMilliseconds < 800) {
      return;
    }
    _lastScannedCode = newValue;
    _lastScannedAt = now;

    isProcessing = true;
    try {
      await _processCode(newValue, barcode.format.name);
    } catch (error, stack) {
      print("❌ ERROR: $error");
      // ❗ nếu vừa success thì bỏ qua lỗi
      if (!_justSuccess) {
        _showCenterMessage('Lỗi quét mã, thử lại.', Colors.red);
        await _playErrorSound();
      } else {
        print("⚠️ Bỏ qua lỗi vì vừa success");
      }
    } finally {
      // Giữ 600ms trước khi cho phép scan tiếp để tránh quét trùng
      await Future.delayed(const Duration(milliseconds: 600));
      isProcessing = false;
    }
  }

  /// Quét mã từ ảnh trong gallery (đọc mã barcode từ file ảnh)
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
          await _processCode(newValue, barcode.format.name);
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
    await player.stop();
    await player.play(AssetSource('error.mp3'));
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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header cam với logo SPX ──
                Container(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Quay lại',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.photo_library,
                                color: Colors.white,
                              ),
                              onPressed: _scanFromGallery,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inventory_2,
                              size: 50,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'SPX Express',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Nội dung chính (scrollable) ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TO ID: $toId',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            Text(
                              'Số lượng: ${scannedCodes.length}/${TOModel.maxGoiHang}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sort: $station',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            Text(
                              'Khối lượng: ${TongKhoiLuong.toStringAsFixed(2)}/${TOModel.maxWeight} kg',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Packer: $packer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ── Dữ liệu input cùng hàng ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                             Text(
                              'Dữ liệu input:',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: inputController,
                                focusNode: inputFocus,
                                decoration: InputDecoration(
                                  hintText: 'Nhập dữ liệu...', //de goi y noi dung nhap trong textfield
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.black,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed:  () async { //quan ly nut bam
                                final text = inputController.text.trim();
                                if (text.isNotEmpty) {
                                  FocusScope.of(context).unfocus();
                                  isProcessing = true;
                                  await _processCode(text, 'Manual Input');
                                  inputController.clear();
                                  isProcessing = false;
                                } else {
                                  _showCenterMessage(
                                    'Vui lòng nhập mã vào ô trống.',
                                    Colors.orange,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 6,
                                shadowColor: Colors.orange.withOpacity(0.5),
                              ),
                              child: const Text(
                                'Confirm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Camera preview (khung cam) ──
                        Center(
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.orange[600]!,
                                width: 4,
                              ),
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
                                                Colors.orange.withValues(
                                                  alpha: 0,
                                                ),
                                                Colors.orange,
                                                Colors.orange.withValues(
                                                  alpha: 0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 60,
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                         Center(
                          child: Text(
                            'Quét Mã',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Dữ liệu quét ──
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Container(
                              height: 260,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
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
                                  const Text(
                                    'Mã đơn',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: const [
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            'Mã',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,

                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Thời gian',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Khối lượng',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 24),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: scannedCodes.isEmpty
                                        ? Center(
                                      child: Text(
                                        'Đưa camera vào mã để quét...',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                        : ListView.builder(
                                      controller: listScrollController,
                                      itemCount: scannedCodes.length,
                                      itemBuilder: (context, index) {
                                        final item = scannedCodes[index];
                                        final timeStr = DateFormat(
                                          'HH:mm:ss',
                                        ).format(item.timestamp);
                                        return Padding(
                                          padding:
                                          const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                flex: 4,
                                                child: SelectableText(
                                                  item.code,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  timeStr,
                                                  textAlign:
                                                  TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '${item.weight.toStringAsFixed(2)} kg',
                                                  textAlign:
                                                  TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    TongKhoiLuong -=
                                                        item.weight;
                                                    scannedCodes.removeAt(
                                                      index,
                                                    );
                                                  });
                                                  _updateTOInDatabase();
                                                },
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                    left: 8,
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 18,
                                                    color:
                                                    Colors.red[400],
                                                  ),
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
                        ),
                        const SizedBox(height: 24),

                        // ── Nút Complete ──
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _completeAndCloseTo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                              shadowColor: Colors.orange.withOpacity(0.6),
                            ),
                            child: const Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: centerMessage == null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: centerMessage == null ? 0.0 : 1.0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
