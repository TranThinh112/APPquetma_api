  import '../data/api_service.dart';
import '../data/order_dtb.dart';
import 'package:flutter/material.dart';

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

  // Hàm xử lý Đăng nhập với Database
  Future login() async {
    final String uName = username.text.trim();
    final String pass = password.text.trim();

    if (uName.isEmpty || pass.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ tài khoản và mật khẩu");
      return;
    }

    // 1) Thử login local DB
    final localUser = await OrderDatabase.instance.login(uName, pass);
    if (localUser != null) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: localUser,
      );
      return;
    }

    // 2) Fallback API
    final user = await ApiService.getUsers(uName, pass);

    if (user != null) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: user,
      );
    } else {
      _showSnackBar("Sai tài khoản hoặc mật khẩu");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _requestPasswordReset() async {
    final String uName = forgotUsernameController.text.trim();

    if (uName.isEmpty) {
      _showSnackBar("Vui lòng nhập tên tài khoản");
      return;
    }

    setState(() {
      _isResettingPassword = true;
    });

    try {
      final localUser = await OrderDatabase.instance.getUserByUsername(uName);
      var user = localUser;

      // Nếu không có local, thử tìm trên server
      if (user == null) {
        user = await ApiService.getUserByUsername(uName);
      }

      if (user == null) {
        // Hiển thị thông báo lớn giữa màn hình cho dễ thấy
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Không tìm thấy tài khoản'),
            content: const Text('Vui lòng kiểm tra lại tên đăng nhập và thử lại.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
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

      final int id = user['id'] as int;

      if (localUser == null) {
        // Nếu user chỉ có server, chèn vào local và đổi pass
        await OrderDatabase.instance.upsertUser(uName, '123456');
      } else {
        // user đã có local, update pass local
        await OrderDatabase.instance.updateUserPasswordById(id, '123456');
      }

      // Đồng bộ lên server
      final bool serverUpdated = await ApiService.updateUserPasswordOnServer(uName, '123456');
      if (serverUpdated) {
        _showSnackBar("Đã đổi mật khẩu thành 123456 cho $uName (server OK)");
      } else {
        _showSnackBar("Đã đổi password local thành công, nhưng server chưa cập nhật");
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar("Lỗi khi lấy lại mật khẩu: $e");
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