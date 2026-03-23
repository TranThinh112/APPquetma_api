  import '../data/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController forgotUsernameController = TextEditingController();
  bool _isResettingPassword = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    forgotUsernameController.dispose();
    super.dispose();
  }
  void _showTopSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating, // 👈 để nổi lên
        margin: const EdgeInsets.only(
          top: 50,
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Hàm xử lý Đăng nhập với Database
  Future login() async {
    final String uName = username.text.trim();
    final String pass = password.text.trim();

    if (uName.isEmpty || pass.isEmpty) {
      _showTopSnackBar("Vui lòng nhập đầy đủ tài khoản và mật khẩu");
      return;
    }
    // 2) Fallback API
    final user = await ApiService.getUser(uName, password: pass);

    if (user != null) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: user,
      );
    } else {
      _showTopSnackBar("Sai tài khoản hoặc mật khẩu");
    }
  }

  Future<void> _requestPasswordReset() async {
    final String uName = forgotUsernameController.text.trim();

    if (uName.isEmpty) {
      _showTopSnackBar("Vui lòng nhập tên tài khoản");
      return;
    }

    setState(() {
      _isResettingPassword = true;
    });

    try {
      final localUser = await ApiService.getUser(uName);
      var user = localUser;

      //  tìm trên server
      if (user == null) {
        _showTopSnackBar("Không tìm thấy tài khoản");
        return;
      }
      // Hiển thị dialog loading 2s khi xác thực thành công
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pop();

      // Đồng bộ lên server
      final bool serverUpdated = await ApiService.updateUserPasswordOnServer(uName, '123456');

      if (serverUpdated) {
        _showTopSnackBar("Đã reset mật khẩu: 123456 cho $uName");
      } else {
        _showTopSnackBar("Đã đổi password local thành công, nhưng server chưa cập nhật");
      }

    } catch (e) {
      _showTopSnackBar("Lỗi khi lấy lại mật khẩu: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  void _showForgotPasswordSheet() {
    forgotUsernameController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Nhập tên tài khoản để xác thực",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: forgotUsernameController,
              enabled: !_isResettingPassword,
              decoration: InputDecoration(
                hintText: "Nhập tên tài khoản",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isResettingPassword ? null : _requestPasswordReset,
                child: _isResettingPassword
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Xác thực và đặt lại",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header SPX Express
            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_2, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "SPX Express",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                children: [
                  const Text(
                    "Đăng Nhập",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  
                  // Username field
                  TextField(
                    controller: username,
                    decoration: InputDecoration(
                      labelText: "Tài Khoản",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Password field
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Mật Khẩu",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),

                  // Nút Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordSheet,
                      child: Text(
                        "Quên mật khẩu?",
                        style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: login,
                      child: const Text(
                        "ĐĂNG NHẬP",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}