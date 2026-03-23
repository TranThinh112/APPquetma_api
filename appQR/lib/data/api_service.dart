import 'dart:convert';
import 'package:http/http.dart' as http;
import '../QuanLy/QuanLyscreen.dart';

class ApiService {

  static const String baseUrl = "https://server-production-fdce.up.railway.app";

  /// lấy tất cả orders để đếm SL
  static Future<List<dynamic>> getOrders() async {

    final response = await http.get(
      Uri.parse("$baseUrl/orders"),
    );
    print("STATUS: ${response.statusCode}");

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
    throw Exception("Failed to load orders");
    return null;
  }
  //ấy dữ liệu cho page quản lý
  static Future<List<OrderModel>> getOrderQL() async {
    final response = await http.get(
      Uri.parse("$baseUrl/orders"),
    );

    print("STATUS: ${response.statusCode}");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => OrderModel.fromJson(e)).toList();
    }

    throw Exception("Failed to load orders");
  }
  // tìm user theo ID
  static Future<Map<String, dynamic>?> getUser(
      String username, {
        String? password,
      }) async {
    try {
      // 🔥 build URL theo trường hợp
      String url = "$baseUrl/users/$username";

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
        Uri.parse('$baseUrl/users/$username'),
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

}