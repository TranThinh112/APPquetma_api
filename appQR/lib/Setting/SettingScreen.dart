import 'package:appqr1/Login/LoginScreen.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../Login/LoginScreen.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String language = "Tiếng Việt";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt"),
        backgroundColor: Colors.orange[700],
      ),
      body: ListView(
        children: [
          // ================= TÀI KHOẢN =================
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Tài khoản",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Thông tin người dùng"),
            onTap: () {
              final username = widget.user['username'] ?? 'Unknown';
              final createdAt = widget.user['created_at'] ?? '';

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Thông tin"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Tên: $username"),
                      Text("Ngày tạo: $createdAt"),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đóng"),
                    )
                  ],
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Đổi mật khẩu"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Chưa làm chức năng này")),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            },
          ),

          const Divider(),

          // ================= GIAO DIỆN =================
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Giao diện",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text("Dark Mode"),
            value: isDarkMode,
            onChanged: (value) {
              setState(() {
                isDarkMode = value;
              });

              MyApp.of(context)?.toggleTheme(value);
            },
          ),

          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Ngôn ngữ"),
            subtitle: Text(language),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text("Tiếng Việt"),
                      onTap: () {
                        setState(() => language = "Tiếng Việt");
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text("English"),
                      onTap: () {
                        setState(() => language = "English");
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}