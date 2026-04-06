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
  final _formkey = GlobalKey<FormState>();
  final _formkeyForgot = GlobalKey<FormState>();
  final TextEditingController forgotUsernameController = TextEditingController();
  bool _isResettingPassword = false;
  String? loginError;
  String? forgotError;
  String? forgotOK;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    forgotUsernameController.dispose();
    super.dispose();
  }

  // Hàm xử lý Đăng nhập với Database
  void login() async {
    final String uName = username.text.trim();
    final String pass = password.text.trim();
    //kiem tra co rỗng ko
    if(!_formkey.currentState!.validate ()){
        return;
    }
    // 2) Fallback API
    final user = await ApiService.getUser(uName, password: pass);
      print("user: $uName");
        print("pass: $pass");
    if (user != null) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: user,
      );
    } else {
     setState(() {
       loginError = "Sai tài khoản hoặc mật khẩu";
     });
    }
  }
//ham xu ly UI reset mat kahu
  Future<void> _requestPasswordReset(Function setStateSheet) async {
    final String uName = forgotUsernameController.text.trim();

    if (!_formkeyForgot.currentState!.validate()) return;

    setStateSheet(() {
      forgotError = null;
      forgotOK = null;
    });

    try {
      final user = await ApiService.getUser(uName);

      if (user == null || user["username"] == null) {
        setStateSheet(() {
          forgotError = "Không tìm thấy tài khoản";
        });
        _formkeyForgot.currentState!.validate();
        return;
      }

      // 🔥 bật loading
      setStateSheet(() {
        _isResettingPassword = true;
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 🔥 GỌI API TRƯỚC
      final bool serverUpdated =
      await ApiService.updateUserPasswordOnServer(uName, '123456');

      // 🔥 đóng dialog SAU khi xong
      if (mounted) Navigator.of(context).pop();
      setStateSheet(() {
        _isResettingPassword = false;
      });

      if (serverUpdated && mounted) {
        setStateSheet(() {
          forgotOK = "Đã reset mật khẩu cho $uName";
        });
      } else {
        setStateSheet(() {
          forgotError = "Reset thất bại";
        });
      }
      print("OK MESSAGE: $forgotOK");

    } catch (e) {
      // _showTopSnackBar("Lỗi: $e");
    } finally {
      if (mounted) {
        setStateSheet(() {
          _isResettingPassword = false;
        });
      }
      print("_isResettingPassword: $_isResettingPassword");
    }
  }
  void _showForgotPasswordSheet() {
    forgotUsernameController.clear();
    forgotError = null;
    forgotOK = null;
    _isResettingPassword = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
          builder: (context, setStateSheet){
            return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20, right: 20, top: 30,
                ),
                child: Form(
                  key: _formkeyForgot,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      const Text(
                        "Nhập tên tài khoản để xác thực",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                          controller: forgotUsernameController,
                          onChanged: (_) {
                            if (forgotError != null || forgotOK != null) {
                              setStateSheet(() {
                                forgotError = null;
                                forgotOK = null;
                              });
                            }
                          },
                          enabled: !_isResettingPassword,
                          decoration: InputDecoration(
                            hintText: "Nhập tên tài khoản",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return "Vui lòng nhập tài khoản";
                            }
                            if( forgotError != null){
                              return forgotError;
                            }
                            return null;
                          }
                      ),
                      if (forgotOK != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            forgotOK!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
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
                          onPressed: _isResettingPassword ? null : () => _requestPasswordReset(setStateSheet),
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
                )
            );
            },
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
            //form dăng nhập
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Form(
                key: _formkey,
                child: Column(
                children: [
                  const Text(
                    "Đăng Nhập",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  
                  // Username field
                  TextFormField(
                    controller: username,
                    decoration: InputDecoration(
                      labelText: "Tài Khoản",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: loginError,
                    ),
                    validator: (value){
                      if(value == null  || value.isEmpty){
                        return 'Tài khoản không được để trống';
                      }
                      return null;
                    }
                  ),
                  const SizedBox(height: 20),
                  
                  // Password field
                  TextFormField(
                    controller: password,
                      obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Mật Khẩu",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.lock_outline),

                      errorText:  loginError,
                    ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Mật khẩu không được để trống';
                      }
                      return null;
                    }
                  ),
                    const SizedBox(height: 10,),
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

                  const SizedBox(height: 10),

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
              ),
            )
          ],
        ),
      ),
    );
  }
}