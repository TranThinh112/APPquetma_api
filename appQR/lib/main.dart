  // =============================================================
/// File: main.dart
/// Mô tả: Điểm khởi chạy ứng dụng SPX Express.
///        Hiển thị màn hình chính (HomeScreen) với lưới 4 chức năng:
///        - Phân Loại: quản lý bao hàng (TO)
///        - Tra cứu đơn hàng
///        - Quản lý đơn hàng
///        - Cài đặt
/// =============================================================
  // thu vien cung cap UI co ban
import 'package:flutter/material.dart';
//goi cac file lien qyan
import 'PhanLoai/PhanLoaiScreen.dart';
import 'TraCuu/TraCuuScreen.dart';
import 'Login/LoginScreen.dart';
import 'QuanLy/QuanLyscreen.dart';
import 'TaoDon/TaoDonScreen.dart';
import 'data/api_service.dart';
import 'Setting/SettingScreen.dart';

//lam viec voi he thong: copy/ paste, xoay man hinh
import 'package:flutter/services.dart';

//luu trang thai darkmode
  import 'package:shared_preferences/shared_preferences.dart';

//setup moi turong
Future<void> main() async{
// tao lien ket Flutter framework và engine
  WidgetsFlutterBinding.ensureInitialized();
  //chay app. Di tu widget goc MyApp -> build full UI
  runApp(const MyApp());

  // gọi API chạy nền
  ApiService.getOrders().then((orders) {
    debugPrint("API OK");
    debugPrint("Tổng số đơn trong server: ${orders.length}");
  }).catchError((e) {
    debugPrint("API lỗi: $e");
  });
}
//witget goc
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

//witget goc
class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  //luu trang thai darkmode
  Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  //lay lai trang thai isDark khi mo app
  Future<bool> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false; // default: light
  }

  //goi khi mo app -> khi mo app -> load status cu
  @override
  void initState() {
    super.initState();
    loadTheme().then((value) {
      setState(() {
        isDarkMode = value;
      });
    });
  }
  //doi theme ngay lap tuc va luu lai
  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
    saveTheme(value); // lưu lại
  }
//định nghĩa màu
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      debugShowCheckedModeBanner: false,

      // LIGHT MODE
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.orange,          // màu chính SPX
          secondary: Colors.orangeAccent,
          surface: Colors.white// màu phụ
        ),
      ),

      // DARK MODE
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.orange,        //  màu chính
          secondary: Colors.orangeAccent,

          surface: Colors.black,    // nền tối chuẩn
          onSurface: Colors.white,       // chữ
        ),
      ),

      //  quyet dinh app dang sang hay toi
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: const LoginPage(),

      routes: {
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final user =
          args is Map<String, dynamic> ? args : <String, dynamic>{};
          return HomeScreen(user: user);
        },
      },
    );
  }
}
//giao dien chinh gom 4 chuc nang
class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

//hien thi 1 card co mau nen + hieu ung
  Widget buildCard(
    Color color,
    IconData? icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      //InkWell: lam cho bat cu thu gi co the click
      child: InkWell(
        onTap: onTap,

        // hien thi card
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            // hieu ung do bong
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),

          // noi dung trong card tu tren xuong, can giua theo chieu doc
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

                Icon(icon, size: 40, color: Colors.black54),
                const SizedBox(height: 10),
                // hien thi text
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500 ,color: Colors.black),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
//build 4 nut bam
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(height: 50),
            // Grid menu - centered on full screen
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    buildCard(
                      Colors.blue[100]!,
                      Icons.category,
                      "Phân Loại",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  PhanLoaiScreen(user: user ),
                          ),
                        );
                      },
                    ),
                    buildCard(
                      Colors.green[100]!,
                      Icons.search,
                      "Tra cứu đơn hàng",
                      onTap: (){
                        Navigator.push(
                          context,
                          //route chuyen trang
                          MaterialPageRoute(
                            builder: (context) => const TraCuuScreen(),
                          ),
                        );
                      }
                    ),
                    buildCard(
                      Colors.purple[100]!,
                      Icons.folder,
                      "Quản lý đơn hàng",
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const QuanLyScreen(),
                          ),
                        );
                      }
                    ),
                    // Ô màu vàng nhạt trống, không hiển thị icon/tiêu đề
                    buildCard(
                      Colors.yellow[100]!,
                      Icons.add_box,
                     "Tạo đơn ",
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaoDonScreen(),
                            ),
                          );
                        }
                    ),
                  ],
                ),
              ),
            ),

            // Header - AppBar
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius:const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2, size: 50, color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          'SPX Express',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar người dùng ở góc trái trên (dưới thanh thời gian)
                  Positioned(
                    left: 16,
                    top: 16,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        final username = user['username'] ?? 'Unknown';
                        final rawCreatedAt = (user['created_at'] ?? '') as String;
                        final createdAt = rawCreatedAt.isNotEmpty
                            ? (DateTime.tryParse(rawCreatedAt)?.toLocal().toString().split('.').first ?? rawCreatedAt)
                            : 'Chưa xác định';
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Thông tin người dùng'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tên: $username'),
                                const SizedBox(height: 8),
                                Text('Ngày tạo: $createdAt'),
                              ],
                            ),
                            actionsAlignment: MainAxisAlignment.center,
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Biểu tượng cài đặt (bánh răng) ở góc phải trên
            Positioned(
              right: 16,
              top: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(user: user),
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
