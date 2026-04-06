/// =============================================================
/// File: create_to_logic.dart
/// Mô tả: Logic xử lý cho màn hình "Create TO" (Tạo bao hàng).
///        Tách riêng khỏi UI để dễ quản lý & tái sử dụng.
/// =============================================================
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/to_model.dart';
import '../../data/api_service.dart';

/// Model cho 1 item đã quét (mã đơn hàng)
class ScannedItem {
  final String code;
  final DateTime timestamp;
  double weight;

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
  overWeightNewTO,  // Vượt cân → đóng TO cũ + tạo TO mới chứa đơn này
  alreadyInTO,      // Mã đã nằm trong TO khác rồi
}

/// Logic chính cho Create TO
class CreateTOLogic {
  // ── State ──
  final List<ScannedItem> scannedCodes = [];
  final Set<String> scannedSet = {};
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
          final item = entry.value;
          return ScannedItem(
            code: item['orderID'] ?? '',
            timestamp: DateTime.now().subtract(Duration(seconds: entry.key)),
            weight: (item['soKI'] ?? 0).toDouble(),
          );
        }),
      );
    } else {
      // Tạo mới
      // _initNewTO();
      // toId = _generateTOId();
      // createdAt = DateTime.now();
      // _saveTOToDatabase(isNew: true);
    }
  }

  Future<void> initNewTO() async {
    toId = _generateTOId();
    createdAt = DateTime.now();

    await _saveTOToDatabase(isNew: true); // luu to vao data
  }
  /// Sinh mã TO: TO + yyMMdd + 4 ký tự ngẫu nhiên
  String _generateTOId() {
    final dateStr = DateFormat('yyMMdd').format(DateTime.now());
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final rand = String.fromCharCodes(
      Iterable.generate(5, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
    );
    return 'TO$dateStr$rand';
  }


  // nhan date tu BE
  void loadFromServer(TOModel to) {
    scannedCodes.clear();

    scannedCodes.addAll(
      to.danhSachGoiHang.reversed.map((e) {
        return ScannedItem(
          code: e['orderId'] ?? '',
          weight: (e['soKi'] ?? 0).toDouble(),
          timestamp: DateTime.tryParse(e['thoiGianScan'] ?? '') ?? DateTime.now(),
        );
      }),
    );

    tongKhoiLuong = to.totalWeight ?? 0;
    station = to.diaDiemGiaoHang ?? "";
  }
  /// Xử lý mã quét — trả về kết quả để UI phản hồi
  ///
  /// Logic trọng lượng:
  ///   - Vừa đủ 10kg → thêm vào + đóng TO
  ///   - Vượt 10kg → đóng TO hiện tại + tạo TO mới + nhét đơn vào TO mới
  ///   - 5/5 kiện → đóng TO

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
  Future<TOModel?> removeItem(int index) async {
    if (index < 0 || index >= scannedCodes.length) return null;

    final xoaStatus = scannedCodes[index];

    final res = await ApiService.removeOrder(
      id: xoaStatus.code,
      maTO: toId,
    );

    if (res == true) {
      await Future.delayed(const Duration(milliseconds: 100)); // tránh race

      return await ApiService.getOneTO(toId); // ✅ luôn trả data mới
    }

    return null;
  }

  /// Kiểm tra mã đơn hàng đã nằm trong TO nào chưa (trừ TO hiện tại) bằng dữ liệu server

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
      danhSachGoiHang: scannedCodes.map((item) => {
        'code': item.code,
        'weight': item.weight,
      }).toList(),
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
      print("API create TO: ${toId}");
      if (isNew) {
        await ApiService.uploadTO(_buildTOModel());
      } else {
        await ApiService.updateTO(_buildTOModel());
      }
      print("tao thanh cong");
    } catch (e) {
      print("Lỗi upload tạo TO: $e");
    }
  }

  Future<void> _updateTOInDatabase() async {
    try {
      final model = _buildTOModel();
      await ApiService.updateTO(model);
    } catch (e) {
      debugPrint("Lỗi update thay đổi: $e");
    }
  }
  TOModel buildTOForView() {
    return TOModel(
      maTO: toId,
      danhSachGoiHang: scannedCodes.map((item) => {
        'code': item.code,
        'weight': item.weight,
      }).toList(),
      diaDiemGiaoHang: station,
      trangThai: 'Packed',
      packer: packer,
      totalWeight: tongKhoiLuong,
      ngayTao: createdAt,
      completeTime: DateTime.now(),
    );
  }
}
