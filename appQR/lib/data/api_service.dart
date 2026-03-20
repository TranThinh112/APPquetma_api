import 'dart:convert';
import 'package:http/http.dart' as http;

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
  
  // tìm user theo ID
  static Future<Map<String, dynamic>?> getUsers(String username, String password) async {

    final response = await http.get(
      Uri.parse("$baseUrl/users/$username/$password"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // ✅ FIX CHUẨN 2 TRƯỜNG HỢP
      if (data == null) return null;
      // nếu backend trả object
      if (data is Map<String, dynamic>) {
        return data;
      }
      // nếu backend trả list
      if (data is List && data.isNotEmpty) {
        return data[0];
      }

      return null;
    }
    print("RESPONSE: ");
    print(response.body);
    return null;
  }

  /// Tìm user trên server theo username (không cần pass)
  static Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      // 1) ưu tiên route lookup mới
      final lookupResponse = await http.get(
        Uri.parse('$baseUrl/users/lookup/$username'),
      );

      if (lookupResponse.statusCode == 200) {
        final data = jsonDecode(lookupResponse.body);
        if (data is Map<String, dynamic> && data.isNotEmpty) {
          return data;
        }
      }

      // 2) thử route /users/:username nếu có
      final byNameResponse = await http.get(Uri.parse('$baseUrl/users/$username'));
      if (byNameResponse.statusCode == 200) {
        final data2 = jsonDecode(byNameResponse.body);
        if (data2 is Map<String, dynamic> && data2.isNotEmpty) {
          return data2;
        }
      }

      // 3) fallback chung nếu backend chưa có /users/lookup hoặc /users/:username
      final allResponse = await http.get(Uri.parse('$baseUrl/users'));
      if (allResponse.statusCode == 200) {
        final all = jsonDecode(allResponse.body);
        if (all is List) {
          final user = all.cast<Map<String, dynamic>>().firstWhere(
                (item) => item['username']?.toString().toLowerCase() == username.toLowerCase(),
                orElse: () => {},
              );
          if (user.isNotEmpty) {
            return user;
          }
        }
      }

      return null;
    } catch (e) {
      print('Server getUserByUsername exception: $e');
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

      print('Server update failed status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return false;
    } catch (e) {
      print('Server update exception: $e');
      return false;
    }
  }

}