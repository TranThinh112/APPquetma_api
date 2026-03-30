import 'dart:convert';
import 'package:http/http.dart' as http;
import '../QuanLy/QuanLyscreen.dart';
import '../models/to_model.dart';
import '../models/Oders_model.dart';
class ApiService {

  static const String baseUrl = "https://server-production-fdce.up.railway.app";

  /// lấy tất cả orders để đếm SL
  static Future<List<dynamic>> getOrders() async {

    final response = await http.get(
      Uri.parse("$baseUrl/orders"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load orders");
  }

  /// tìm order theo ID
  static Future<Map<String, dynamic>?> getOrder(String id) async {

    final response = await http.get(
      Uri.parse("$baseUrl/orders/$id"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
  //ấy dữ liệu cho page quản lý
  static Future<List<OrderModel>> getOrderQL() async {
    final response = await http.get(
      Uri.parse("$baseUrl/orders"),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => OrderModel.fromJson(e)).toList();
    }

    throw Exception("Failed to load orders");
  }
  //lay don theo trang thai
  static Future<List<Map<String, dynamic>>> getStatusOrders(String trangThai) async{
    final response = await http.get(
        Uri.parse("$baseUrl/orders/status/trangThai"),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>(); //
    }
    return [];
  }
  //upload trang thai don hang
  static Future<bool> updateOrderField(String code, String field, String value) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/orders/$code/$field/${Uri.encodeComponent(value)}',
      );
      final response = await http.put(uri);
      return response.statusCode == 200;
    } catch (e) {
      print('Update error: $e');
      return false;
    }
  }
  // update trạng thái
  // update trạng thái
  static Future<bool> updatStatusOrders(String code, String status) {
    return updateOrderField(code, "status", status);
    //https://server-production-fdce.up.railway.app/orders/SPXVN06104737773/status/Inbound
  }

// update time scan
  static Future<bool> updateTimeScanOrders(String code, String time) {
    return updateOrderField(code, "timedong", time);
    // https://server-production-fdce.up.railway.app/orders/SPXVN06104737773/timedong/2026-03-23 18:35:47

  }

    //////////////     USER ////////////////
  // tìm user theo ID
  static Future<Map<String, dynamic>?> getUser(
      String username, {
        String? password,
      }) async {
    try {
      // 🔥 build URL theo trường hợp
      String url = "$baseUrl/login/users/$username";

      // 🔐 nếu có password → login
      if (password != null && password.isNotEmpty) {
        url += "/$password";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null) return null;

        // nếu backend trả object
        if (data is Map<String, dynamic>) {
          return data;
        }

        // nếu backend trả list
        if (data is List && data.isNotEmpty) {
          return data[0];
        }
      }
      print("RESPONSE: ${response.body}");
      return null;
    } catch (e) {
      print("getUser error: $e");
      return null;
    }
  }

  /// Cập nhật mật khẩu user trên server (nếu endpoint hỗ trợ)
  static Future<bool> updateUserPasswordOnServer(String username, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/login/users/$username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': newPassword}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      if (response.statusCode == 404) {
        print('Server update: user not found $username');
        return false;
      }

      return false;
    } catch (e) {
      print('Server update exception: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════
      //////////////// TO_orders — Push TO lên server /////////////////////////////////////////
  // ═══════════════════════════════════════════
  /// Upload 1 TO lên server (bảng TO_orders)
  static Future<bool> uploadTO(TOModel to) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/TO_orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': to.maTO, // Truyền luôn id = maTO để json-server dễ quản lý
          'maTO': to.maTO,
          'danhSachGoiHang': to.danhSachGoiHang.join(','),
          'diaDiemGiaoHang': to.diaDiemGiaoHang,
          'trangThai': to.trangThai,
          'packer': to.packer,
          'ngayTao': to.ngayTao.toIso8601String(),
          'completeTime': to.completeTime?.toIso8601String(),
          'totalWeight': to.totalWeight,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Cập nhật TO trên server (dùng maTO làm ID)
  static Future<bool> updateTO(TOModel to) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/TO_orders/${to.maTO}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'maTO': to.maTO,
          'danhSachGoiHang': to.danhSachGoiHang.join(','),
          'diaDiemGiaoHang': to.diaDiemGiaoHang,
          'trangThai': to.trangThai,
          'packer': to.packer,
          'ngayTao': to.ngayTao.toIso8601String(),
          'completeTime': to.completeTime?.toIso8601String(),
          'totalWeight': to.totalWeight,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Lấy tất cả TO từ server
  static Future<List<Map<String, dynamic>>> getAllTOsFromServer() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/TO_orders'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  //lay To theo trang tahi
static Future<List<Map<String, dynamic>>> getTOStatus (String trangThai) async{
    final response = await http.get(Uri.parse("$baseUrl/TO_orders/status/$trangThai"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>(); //
    }
    return [];
}
  /// Xóa TO trên server (dùng maTO làm ID)
  static Future<bool> deleteTOOnServer(String maTO) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/TO_orders/$maTO'),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}