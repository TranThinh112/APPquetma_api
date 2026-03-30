import 'dart:convert';
/// =============================================================
/// File: to_model.dart
/// Mô tả: Model dữ liệu cho bao hàng (Transfer Order - TO).
///
/// Thuộc tính:
///   - maTO           : Mã TO (VD: TO2603AB1X) - định dạng TO2603 + 4 ký tự ngẫu nhiên
///   - danhSachGoiHang : Danh sách mã gói hàng nhỏ trong bao
///   - diaDiemGiaoHang : Địa điểm giao hàng
///   - trangThai      : Trạng thái bao hàng (Packing / Packed)
///   - ngayTao        : Ngày tạo bao hàng
///   - totalWeight    : Tổng trọng lượng (KG) của bao hàng
///   - soLuongDonHang : Getter - số gói hàng trong bao
///   - maxGoiHang     : Hằng số - tối đa 5 gói hàng / bao
///   - maxWeight      : Hằng số - tối đa 20 KG / bao
/// =============================================================
///
class TOModel {
  final String maTO; // Mã TO
  final  List<Map<String, dynamic>> danhSachGoiHang; // Danh sách mã gói hàng
  final String diaDiemGiaoHang; // Địa điểm giao
  final String trangThai; // Packing / Packed
  final DateTime ngayTao; // Thời gian tạo
  final DateTime? completeTime; // Thời gian hoàn thành
  final String packer; // Người đóng gói
  final double totalWeight; // Tổng KG

  TOModel({
    required this.maTO,
    required this.danhSachGoiHang,
    this.diaDiemGiaoHang = '',
    this.trangThai = 'Packing',
    this.packer = '',
    this.totalWeight = 0.0,
    DateTime? ngayTao,
    this.completeTime,
  }) : ngayTao = ngayTao ?? DateTime.now();

  int get soLuongDonHang => danhSachGoiHang.length;

  static const int maxGoiHang = 5; // Tối đa 5 kiện hàng
  static const double maxWeight = 10.0; // Tối đa 10 KG

  factory TOModel.fromJson(Map<String, dynamic> json) {
    var rawDsg = json['danhSachGoiHang'];
    List<Map<String, dynamic>> listGoiHang = [];

    // 🔥 CASE 1: STRING
    if (rawDsg is String) {
      String cleaned = rawDsg.trim();

      // TH1: JSON chuẩn
      if (cleaned.startsWith('[')) {
        try {
          final decoded = jsonDecode(cleaned);
          listGoiHang = decoded.map<Map<String, dynamic>>((e) {
            return {
              'code': e['code'],
              'weight': (e['weight'] ?? 0).toDouble(),
            };
          }).toList();
        } catch (e) {
          listGoiHang = [];
        }
      }
      // format lỗi {code:..., weight:...}
      else if (cleaned.contains('code') && cleaned.contains('weight')) {
        final regex = RegExp(r'code:\s*([A-Z0-9]+).*?weight:\s*(\d+\.?\d*)');

        final matches = regex.allMatches(cleaned);

        listGoiHang = matches.map((m) {
          return {
            'code': m.group(1),
            'weight': double.parse(m.group(2)!),
          };
        }).toList();
      }

      // ⚠️ TH3: DB cực cũ "SPX1,SPX2"
      else {
        listGoiHang = cleaned.isEmpty
            ? []
            : cleaned.split(',').map((e) {
          return {
            'code': e.trim(),
            'weight': 0.0,
          };
        }).toList();
      }
    }

    // 🔥 CASE 2: LIST
    else if (rawDsg is List) {
      listGoiHang = rawDsg.map<Map<String, dynamic>>((e) {
        if (e is Map) {
          return {
            'code': e['code'],
            'weight': (e['weight'] ?? 0).toDouble(),
          };
        } else {
          return {
            'code': e.toString(),
            'weight': 0.0,
          };
        }
      }).toList();
    }

    return TOModel(
      maTO: json['maTO'] ?? '',
      danhSachGoiHang: listGoiHang,
      diaDiemGiaoHang: json['diaDiemGiaoHang'] ?? '',
      trangThai: json['trangThai'] ?? 'Packing',
      packer: json['packer'] ?? '',
      totalWeight: (json['totalWeight'] ?? 0.0).toDouble(),
      ngayTao: json['ngayTao'] != null
          ? DateTime.tryParse(json['ngayTao'].toString())
          : null,
      completeTime: json['completeTime'] != null
          ? DateTime.tryParse(json['completeTime'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maTO': maTO,
      'danhSachGoiHang': danhSachGoiHang,
      'diaDiemGiaoHang': diaDiemGiaoHang,
      'trangThai': trangThai,
      'packer': packer,
      'totalWeight': totalWeight,
      'ngayTao': ngayTao.toIso8601String(),
      'completeTime': completeTime?.toIso8601String(),
    };
  }
}