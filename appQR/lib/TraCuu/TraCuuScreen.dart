import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/to_model.dart';
import '../data/to_database.dart';
// import 'tao_bao_hang_screen.dart';

class TraCuuScreen extends StatefulWidget{
    const TraCuuScreen({super.key});

    @override
    _TraCuuScreenState createState() => _TraCuuScreenState();
}

class _TraCuuScreenState extends State<TraCuuScreen> {
  final TextEditingController searchController = TextEditingController();
  List<TOModel> allTOs = [];
  List<TOModel> filteredList = [];
  final Set<String> _selectedTOs = {};

  void _search(String keyword) {
    setState(() {
      filteredList = _searchID(allTOs, keyword);
    });
  }

  List<TOModel> _searchID(List<TOModel> list, String keyword) {
    if (keyword.isEmpty) return list;
    final upper = keyword.toUpperCase();
    return list.where((to) => to.maTO.toUpperCase().contains(upper)).toList();
  }

  Future<void> _scanToSearch() async {
    final scanController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      returnImage: false,
      formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
    );
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Quét mã đơn hàng'),
          content: SizedBox(
            width: 280,
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: scanController,
                onDetect: (capture) {
                  if (capture.barcodes.isEmpty) return;
                  final code = capture.barcodes.first.rawValue?.trim() ?? '';
                  if (code.isNotEmpty) {
                    searchController.text = code.toUpperCase();
                    _search(code.toUpperCase());
                    scanController.dispose();
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                scanController.dispose();
                Navigator.pop(ctx);
              },
              child : const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Quay lại',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 50,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SPX Express',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Row(
                  children: [
                    const Text(
                      'Nhập mã đơn: ',
                      style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 220),
                    //nut quet mau cam
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      onPressed: _scanToSearch,
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  ],
                  ),
                  SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10), //thu vien 2 bên
                    child: SizedBox(
                      height: 200,
                      child:  TextField(
                        maxLines: 5,
                        // minLines: null,
                        maxLength: 1000,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              width: 3,
                              color: Colors.black,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              width: 3, // 👈 dày
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                Row(
                  children: [
                    SizedBox(width: 10),
                     SizedBox(
                      width: 100, // 👈 full ngang
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white70, // màu
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // bo góc
                          ),
                        ),
                        onPressed: () {
                          print("gaf!");
                        },
                        child: Text(
                          "Xem",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10), //khoang cach giua cac nut
                    SizedBox(
                      width: 100,
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white70, // màu
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // bo góc
                          ),
                        ),
                        onPressed: () {
                          print("gaf!");
                        },
                        child: Text(
                          "In",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 150, // 👈 full ngang
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[400], // màu
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // bo góc
                          ),
                        ),
                        onPressed: () {
                          print("not!");
                        },
                        child: Text(
                          "Confirm",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

