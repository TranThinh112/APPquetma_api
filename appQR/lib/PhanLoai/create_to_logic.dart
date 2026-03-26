/// =============================================================
/// File: create_to_logic.dart
/// Mô tả: Logic xử lý cho màn hình "Create TO" (Tạo bao hàng).
///        Tách riêng khỏi UI để dễ quản lý & tái sử dụng.
/// =============================================================
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/to_model.dart';
import '../data/to_database.dart';
import '../data/api_service.dart';

/// Model cho 1 item đã quét (mã đơn hàng)
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

/// Kết quả trả về sau khi xử lý mã quét
enum ScanResult {
  success,          // Quét thành công
  empty,            // Mã trống
  invalidFormat,    // Sai định dạng
  duplicate,        // Trùng mã đã quét
  notFound,         // Không tìm thấy trên server
  wrongStation,     // Sai trạm / sort
  maxItems,         // Đạt tối đa số kiện
  autoComplete,     // Tự động đóng TO (đủ 10kg hoặc 5/5)
  overWeightNewTO,  // Vượt cân → đóng TO cũ + tạo TO mới chứa đơn này
  alreadyInTO,      // Mã đã nằm trong TO khác rồi
}

/// Logic chính cho Create TO
class CreateTOLogic {
  // ── State ──
  final List<ScannedItem> scannedCodes = [];
  double tongKhoiLuong = 0;
  String station = "";
  String _stationBanDau = "";
  late String toId;
  late String packer;
  String originalStatus = 'Packing';
  late DateTime createdAt;
  DateTime? completedAt;

  /// Lưu user info để tạo TO mới khi cần
  Map<String, dynamic>? _user;

  // Constructor
  CreateTOLogic({required Map<String, dynamic>? user, TOModel? editTO}) {
    _user = user;
    packer = user?['username'] ?? 'unknown';

    if (editTO != null) {
      // Chế độ chỉnh sửa
      toId = editTO.maTO;
      originalStatus = editTO.trangThai;
      createdAt = editTO.ngayTao;
      completedAt = editTO.completeTime;
      _stationBanDau = editTO.diaDiemGiaoHang;
      station = editTO.diaDiemGiaoHang;
      tongKhoiLuong = editTO.totalWeight;
      scannedCodes.addAll(
        editTO.danhSachGoiHang.asMap().entries.map((entry) {
          return ScannedItem(
            code: entry.value,
            timestamp: DateTime.now().subtract(Duration(seconds: entry.key)),
            weight: 0,
          );
        }),
      );
    } else {
      // Tạo mới
      toId = _generateTOId();
      createdAt = DateTime.now();
      _saveTOToDatabase(isNew: true);
    }
  }

  /// Sinh mã TO: TO + yyMMdd + 4 ký tự ngẫu nhiên
  String _generateTOId() {
    final dateStr = DateFormat('yyMMdd').format(DateTime.now());
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final rand = String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
    return 'TO$dateStr$rand';
  }

  /// Validate mã SPX: phải khớp SPXVN06 + 8-10 chữ số
  bool isValidSPX(String code) {
    final regex = RegExp(r'^SPXVN06\d{8,10}$', caseSensitive: false);
    return regex.hasMatch(code.trim());
  }

  /// Xử lý mã quét — trả về kết quả để UI phản hồi
  ///
  /// Logic trọng lượng:
  ///   - Vừa đủ 10kg → thêm vào + đóng TO
  ///   - Vượt 10kg → đóng TO hiện tại + tạo TO mới + nhét đơn vào TO mới
  ///   - 5/5 kiện → đóng TO
  Future<ScanResult> processCode(String code) async {
    code = code.trim().toUpperCase();

    if (code.isEmpty) return ScanResult.empty;
    if (!isValidSPX(code)) return ScanResult.invalidFormat;
    if (scannedCodes.any((item) => item.code == code)) return ScanResult.duplicate;

    // Kiểm tra mã đã nằm trong TO khác chưa (trong database)
    final existingTO = await _isCodeInAnyTO(code);
    if (existingTO != null) return ScanResult.alreadyInTO;

    // Gọi API tìm đơn hàng
    final order = await ApiService.getOrder(code);
    if (order == null) return ScanResult.notFound;

    // Đọc dữ liệu từ API — field names: noiNhan (nơi nhận), soKi (số kí)
    final orderStation = order['noiNhan']?.toString().trim() ?? "";
    final itemWeight = double.tryParse(order['soKi'].toString()) ?? 0.0;

    // Kiểm tra station — đơn đầu tiên set station, các đơn sau phải cùng station
    if (_stationBanDau.isEmpty) {
      _stationBanDau = orderStation;
      station = orderStation;
    }
    if (orderStation != _stationBanDau) return ScanResult.wrongStation;

    // Kiểm tra đã đạt tối đa 5 kiện chưa
    if (scannedCodes.length >= TOModel.maxGoiHang) return ScanResult.maxItems;

    // ── Kiểm tra trọng lượng ──
    if (tongKhoiLuong + itemWeight > TOModel.maxWeight) {
      // VƯỢT CÂN → đóng TO hiện tại (nếu có đơn) + tạo TO mới chứa đơn này
      if (scannedCodes.isNotEmpty) {
        await completeTO();
      }
      // Reset state → tạo TO mới
      _resetForNewTO();
      // Giữ station cũ (cùng trạm)
      station = _stationBanDau;
      // Thêm đơn hàng vào TO mới
      tongKhoiLuong = itemWeight;
      scannedCodes.insert(
        0,
        ScannedItem(code: code, timestamp: DateTime.now(), weight: itemWeight),
      );
      await _updateTOInDatabase();
      return ScanResult.overWeightNewTO;
    }

    // ✅ Hợp lệ → thêm vào danh sách
    tongKhoiLuong += itemWeight;
    scannedCodes.insert(
      0,
      ScannedItem(code: code, timestamp: DateTime.now(), weight: itemWeight),
    );

    // Lưu vào DB
    await _updateTOInDatabase();

    // Kiểm tra đã đầy chưa → auto complete (đúng 10kg hoặc 5/5)
    if (scannedCodes.length >= TOModel.maxGoiHang ||
        tongKhoiLuong >= TOModel.maxWeight) {
      await completeTO();
      return ScanResult.autoComplete;
    }

    return ScanResult.success;
  }

  /// Reset state để tạo TO mới (giữ packer và station)
  void _resetForNewTO() {
    scannedCodes.clear();
    tongKhoiLuong = 0;
    originalStatus = 'Packing';
    completedAt = null;
    toId = _generateTOId();
    createdAt = DateTime.now();
    _saveTOToDatabase(isNew: true);
  }

  /// Xóa 1 item — nếu xóa hết → tự xóa TO khỏi hệ thống
  Future<void> removeItem(int index) async {
    if (index < 0 || index >= scannedCodes.length) return;
    tongKhoiLuong -= scannedCodes[index].weight;
    scannedCodes.removeAt(index);

    if (scannedCodes.isEmpty) {
      // Xóa TO khỏi database khi không còn đơn hàng nào
      await _deleteTOFromDatabase();
    } else {
      await _updateTOInDatabase();
    }
  }

  /// Kiểm tra mã đơn hàng đã nằm trong TO nào chưa (trừ TO hiện tại) bằng dữ liệu server
  Future<String?> _isCodeInAnyTO(String code) async {
    try {
      final serverData = await ApiService.getAllTOsFromServer();
      final allTOs = serverData.map((e) => TOModel.fromJson(e)).toList();
      for (final to in allTOs) {
        if (to.maTO == toId) continue; // Bỏ qua TO hiện tại
        if (to.danhSachGoiHang.contains(code)) {
          return to.maTO; // Trả về mã TO chứa đơn này
        }
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra trùng từ server: $e');
    }
    return null;
  }

  /// Xóa TO khỏi server
  Future<void> _deleteTOFromDatabase() async {
    try {
      await ApiService.deleteTOOnServer(toId);
      debugPrint('TO $toId đã xóa (không còn đơn hàng)');
    } catch (e) {
      debugPrint('Lỗi xóa TO: $e');
    }
  }

  /// Đóng TO (hoàn thành bao hàng)
  Future<bool> completeTO() async {
    if (scannedCodes.isEmpty) return false;

    // final wasPacked = (originalStatus == 'Packed'); // Không cần thiết nữa vì mọi thứ đã đồng bộ lưu trên server

    originalStatus = 'Packed';
    // Chỉ set completedAt một lần khi đóng lần đầu
    completedAt ??= DateTime.now();

    final toComplete = _buildTOModel();
    await _updateTOInDatabase(); // Chạy thẳng lệnh Update lên server
    
    return true;
  }

  // ── Private helpers ──

  TOModel _buildTOModel() {
    return TOModel(
      maTO: toId,
      danhSachGoiHang: scannedCodes.map((item) => item.code).toList(),
      diaDiemGiaoHang: station,
      trangThai: originalStatus,
      packer: packer,
      totalWeight: tongKhoiLuong,
      ngayTao: createdAt,
      completeTime: completedAt,
    );
  }

  Future<void> _saveTOToDatabase({bool isNew = false}) async {
    try {
      if (isNew) {
        await ApiService.uploadTO(_buildTOModel());
      } else {
        await ApiService.updateTOOnServer(_buildTOModel());
      }
    } catch (e) {
      debugPrint("Lỗi upload tạo TO: $e");
    }
  }

  Future<void> _updateTOInDatabase() async {
    try {
      final model = _buildTOModel();
      await ApiService.updateTOOnServer(model);
    } catch (e) {
      debugPrint("Lỗi update thay đổi: $e");
    }
  }
}


