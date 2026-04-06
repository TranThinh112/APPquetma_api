import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/to_model.dart';
import '../PhanLoai/create_TO/create_to_screen.dart';
import '../models/BillTo.dart';
import '../PhanLoai/PhanLoaiScreen.dart';
//ko witget
class TOResultScreen extends StatelessWidget {
  final TOModel to;
  final Map<String, dynamic> user; //truyen user

  const TOResultScreen({super.key, required this.to, required this.user});

  @override
  Widget build(BuildContext context) {
    final ScrollController listScrollController = ScrollController();
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final style = TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: textColor);
    return Scaffold(
      body: Column(
        children: [
          buildHeader(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                child: Column(
                  children: [
                    const SizedBox (height: 40),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TO ID: ${to.maTO}',style: style),
                          Text('Số lượng: ${to.soLuongDonHang}/${TOModel.maxGoiHang}',style: style),
                        ],
                      ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Station: ${to.diaDiemGiaoHang}',style: style),
                      Text(
                          'Khối lượng: ${to.totalWeight.toStringAsFixed(2)}/${TOModel.maxWeight} kg',style: style,
                      ),
                    ],
                  ),
                   Row(children: [Text('Packer: ${to.packer}', style: style)]),
              ],
            ),
            ),
             SizedBox(height: 20),
             Row(
               children: [
                 SizedBox(width: 10),
                 SizedBox(
                   height: 30,
                   width: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        )
                      ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ReOpen",
                      style: TextStyle(
                        fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold
                      ),
                      ),
                    ),
                 ),
                 SizedBox(width: 20),
                 SizedBox(
                   height: 30,
                   width: 100,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.white70,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(10),
                           )
                        ),
                       onPressed: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context)=> BillTO(TO: to),
                            ),
                        );
                       },
                       child: const Text("View",
                       style: TextStyle(
                           fontSize: 12, color: Colors.black, fontWeight:  FontWeight.bold
                         ),
                       )
                   ),
                 ),
                 SizedBox(width: 20),
                 SizedBox(
                   height: 30,
                   width: 100,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.orange,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadiusGeometry.circular(10),
                       )
                     ),
                       onPressed: (){
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_)=> CreateTOScreen(user: user)),
                        );
                       },
                       child: const Text("Tạo mới",
                         style: TextStyle(
                           fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12
                         ),
                       )
                   ),
                 )
               ],
             ),

             SizedBox(height: 40),
             Center(
               child: ConstrainedBox(
                 constraints: const BoxConstraints(maxWidth: 360),
                 child: Container(
                   height: 260,
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                   decoration: BoxDecoration(
                     color: Colors.grey[50],
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.grey[300]!),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.grey.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
              child: Row(
              children: const [
                  Expanded(
                    flex: 3,
                    child: Text('Mã đơn',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
                  Expanded(
                    flex: 2,
                    child: Text('Khối lượng',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))
                    ),
                  ],
                ),
              ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: to.danhSachGoiHang.length,
                    itemBuilder: (_, index) {
                      final item = to.danhSachGoiHang[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(item['code']),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "${item['weight']} kg",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
          ],
        ),
      ),
        ),
      ]
    ),
    );
  }
  Widget buildHeader(BuildContext context) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    //pushandremove: di trang moi va xoa het duong di
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhanLoaiScreen(user: user!),
                      ),
                          (route) => route.isFirst, // ✅ giữ màn đầu
                    );
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text('Quay lại',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: const [
                Icon(Icons.inventory_2, size: 50, color: Colors.white),
                SizedBox(height: 8),
                Text('SPX Express',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
//apbar
