import 'dart:convert';
import 'package:http/http.dart' as http;
import '../QuanLy/QuanLyscreen.dart';
import '../models/to_model.dart';
import '../models/Oders_model.dart';
class ApiService {

  static const String baseUrl = "https://server-production-7598.up.railway.app";

  /// lấy tất cả orders để đếm SL
  static Future<List<dynamic>> getOrders() async {

    final response = await http.get(
      Uri.parse("$baseUrl/orders/getIn4"),
    );
    if (response.statusCode == 200) {
      final json =jsonDecode(response.body);
      return json['data'];
    }

    throw Exception("Failed to load orders");
  }

  /// tìm order theo ID
  static Future<Map<String, dynamic>?> getOrder(String id) async {

    final response = await http.get(
      Uri.parse("$baseUrl/orders/getIn4?id=$id"),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) return null;

      //  nếu trả list → lấy phần tử đầu
      final order = (data is Map && data['data'] != null && data['data'].isNotEmpty)
          ? data['data'][0]
          : null;
      return order;
    }
    return null;
  }
  //ấy dữ liệu cho page quản lý/ tonhg don, lay du lieu theo page: 10d/1 page, search don hang
  static Future<Map<String, dynamic>> getOrderQL(int page, String keyword) async {
    final res = await http.get(Uri.parse("$baseUrl/orders/getIn4?page=$page&limit=10&keyword=$keyword"));

    if (res.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(res.body);

      final List data = json['data']; // 🔥 lấy đúng key
      final int total = json['total'];
      final int inbound =json['inbound'];
      return {
        "orders": data.map((e) => OrderModel.fromJson(e)).toList(),
        "total": total,
        "inbound" : inbound,
      };
    }
    return {
      "orders": [],
      "total": 0,
    };
  }
  //lay don theo trang thai
  static Future<List<Map<String, dynamic>>> getStatusOrders(String trangThai) async{
    final response = await http.get(
        Uri.parse("$baseUrl/orders/getIn4?trangThai=$trangThai"),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>(); //
    }
    return [];
  }

  //upload trang thai don hang, thoi gian quet, maTO
  static Future<Map<String, dynamic>> scanOrder({
    required String id,
    required String maTO,
  }) async {
    final url = Uri.parse("$baseUrl/orders/scan/$id");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"maTO": maTO}),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    try {
      final data = jsonDecode(response.body);

      // ✅ chuẩn hóa response
      if (response.statusCode == 200) {
        return {
          "success": true,
          ...data,
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? 'Lỗi server',
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Lỗi parse JSON",
      };
    }
  }

  //removedon hang
  static Future<bool> removeOrder({required String id, required String maTO,}) async {
    final url = Uri.parse("$baseUrl/orders/remove/$id");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 200;
  }

  // taoj dodwn
  static Future<OrderModel?> createOrder(OrderModel o) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(o.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        //  parse thành object
        return OrderModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print("API error: $e");
      return null;
    }
  }

    //////////////     USER ////////////////
  // tìm user theo ID
  static Future<Map<String, dynamic>?> getUser(String username, {String? password,}) async {
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

        if(response.statusCode != 200 ) return null;

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
        Uri.parse('$baseUrl/repass/users/$username'),
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
        Uri.parse('$baseUrl/TO'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': to.maTO, // Truyền luôn id = maTO để json-server dễ quản lý
          'maTO': to.maTO,
          'danhSachGoiHang': to.danhSachGoiHang,
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
        Uri.parse('$baseUrl/TO/${to.maTO}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'maTO': to.maTO,
          'danhSachGoiHang': to.danhSachGoiHang,
          'diaDiemGiaoHang': to.diaDiemGiaoHang,
          'trangThai': to.trangThai,
          'packer': to.packer,
          'ngayTao': to.ngayTao.toIso8601String(),
          'completeTime': to.completeTime?.toIso8601String(),
          'totalWeight': to.totalWeight,
        }),

      );
      print("TO RAW: ${to.danhSachGoiHang}");
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Lấy tất cả TO từ server
  static Future<List<Map<String, dynamic>>> getAllTOsFromServer() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/TO'));
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
    final response = await http.get(Uri.parse("$baseUrl/TO?trangThai=$trangThai"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>(); //
    }
    return [];
}

//cap nhat trang thai Packing khi reopen
  static Future<void> reopenTO(String maTO) async {
    await http.put(
      Uri.parse("$baseUrl/TO/$maTO/reopen"),
      headers: {"Content-Type": "application/json"},
    );
  }
//lay theo ma TO
  static Future<TOModel?> getOneTO(String maTO) async {
    final res = await http.get(Uri.parse("$baseUrl/TO?maTO=$maTO"));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      print("BODY lay tu server: $body");

      // ✅ nếu là List
      if (body is List && body.isNotEmpty) {
        return TOModel.fromJson(body[0]);
      }
      // ✅ nếu là Map
      if (body is Map<String, dynamic>) {
        return TOModel.fromJson(body);
      }
    }

    return null;
  }
  /// Xóa TO trên server (dùng maTO làm ID)
  static Future<bool> deleteTOOnServer(String maTO) async {
    try {
      final uri = Uri.parse('$baseUrl/TO/$maTO');
      final response = await http.delete(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}