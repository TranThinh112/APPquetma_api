/// =============================================================
/// File: phan_loai_screen.dart
/// Mô tả: Màn hình menu "Phân Loại" - điều hướng đến 3 chức năng:
///        1. Create TO  → Tạo bao hàng mới (đóng bao)
///        2. Scan TO    → Quét mã TO để kiểm tra
///        3. Created TO → Xem danh sách bao hàng đã tạo
/// =============================================================
import 'package:flutter/material.dart';
import 'Scan_to/scan_to_screen.dart';
import 'danhsach-TO/table_to_screen.dart';
import 'create_TO/create_to_screen.dart';
import '../models/appbar_logo.dart';


class PhanLoaiScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const PhanLoaiScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Buttons centered on full screen
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuButton(
                      icon: Icons.add_circle_outline,
                      label: 'Create TO',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateTOScreen(user: user),
                          ),
                        );
                      },
                    ),
                    // const SizedBox(height: 18),
                    // _buildMenuButton(
                    //   icon: Icons.qr_code_scanner,
                    //   label: 'Scan TO',
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const ScanTOScreen(),
                    //       ),
                    //     );
                    //   },
                    // ),
                    const SizedBox(height: 18),
                    _buildMenuButton(
                      icon: Icons.list_alt,
                      label: 'Table TO',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TableTOScreen(user: user),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Top: header cam bao gồm nút quay lại + logo
            HeaderWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.4),
        highlightColor: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.orange[600],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
