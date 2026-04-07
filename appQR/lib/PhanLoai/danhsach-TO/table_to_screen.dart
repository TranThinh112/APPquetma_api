/// =============================================================
/// File: table_to_screen.dart
/// Mô tả: UI (giao diện) cho màn hình "Table TO" - Danh sách bao hàng.
///        Logic xử lý nằm trong table_to_logic.dart.
/// =============================================================
import 'package:appqr1/data/api_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/to_model.dart';
import '../create_TO/create_to_screen.dart';
import 'table_to_logic.dart';
import '../../BILL/BillTo.dart';
import '../ketqua_to_Screen.dart';

class TableTOScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const TableTOScreen({super.key, required this.user});

  @override
  State<TableTOScreen> createState() => _TableTOScreenState();
}
//Dùng cho tiêu đề cột (header row)
class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
// Dùng cho dữ liệu trong bảng (data row)
class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: SelectableText(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableTOScreenState extends State<TableTOScreen> {
  final TableTOLogic logic = TableTOLogic();
  // List<TOModel> filteredList = [];
  final TextEditingController searchController = TextEditingController();
  int tongTO =0;
  int toPacked = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }
  //xuat UI toan bo TO dang co
  @override
  Future<void> loadData() async {
    await logic.refreshList();
    final total = await sumTO();
    final packed = await packedTO();

    setState(() {
      tongTO = total;
      toPacked = packed;
    });
  }
  //ham load lai page
  Future<void> _refreshList() async {
    await logic.refreshList();
    logic.search(searchController.text);
    setState(() {});
  }
//ham serch dung cho thanh Textfield
  void _search(String keyword) {
    logic.search(keyword);
    setState(() {});
  }
  /// Format thời gian hiển thị
  String formatTime(DateTime? time) {
    if (time == null) return '';
    final year = (time.year % 100).toString().padLeft(2,'0');
    return "$year/${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  /// Mở CreateTOScreen ở chế độ chỉnh sửa
  void _editTO(TOModel to) async {
    final fullTO = await ApiService.getOneTO(to.maTO);

    if(fullTO == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTOScreen(
            // to: fullTO,
            editTO: fullTO,
            user: widget.user
        ),
      ),
    );
    _refreshList();
  }

  /// Quét mã TO để tìm kiếm
  Future<void> _scanToSearch() async {
    final scanController = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: CameraFacing.back,
      returnImage: false,
      formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Quét mã bao hàng'),
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
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(isDark),
            _buildTextTong(),
            Expanded(child: _buildTable()),
            if (logic.isDeleteMode) _buildDeleteActions(),
          ],
        ),
      ),
    );
  }

  //build header
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:  Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text('Quay lại',
                      style:
                          TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const Spacer(),
                // if (widget.user?['username'] == 'admin')
                //   IconButton(
                //     icon: const Icon(Icons.delete_outline,
                //         color: Colors.white),
                //     onPressed: () {
                //       setState(() => logic.toggleDeleteMode());
                //     },
                //   ),
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
//thanh timf kieems vaf nut quet ma
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Tìm mã TO...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon:
                    Icon(Icons.search, color:  Theme.of(context).colorScheme.primary),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.black!, width: 2),
                ),
                filled: true,
                fillColor:
                    isDark ? Colors.grey[850] : Colors.grey[50],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color:  Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _scanToSearch,
              icon: const Icon(Icons.qr_code_scanner,
                  color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );

}
//build text tong
 Widget _buildTextTong(){
    return Padding(
       padding: const EdgeInsets.all(12),
     child: Row(
       children: [
         Text("Tổng TO: ${tongTO}"),
         const Spacer(),
         Text("Đã Complete: ${toPacked}/${tongTO}"),
       ],
     ),
   );
 }
 //build danh sach bang
  Widget _buildTable() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _refreshList,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // QUAN TRỌNG
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: isDark ? Colors.white! : Colors.black!, width: 1),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            columnWidths: {
              if (logic.isDeleteMode) 0: const FixedColumnWidth(30),
              (logic.isDeleteMode ? 1 : 0): const FixedColumnWidth(160),//ma TO
              (logic.isDeleteMode ? 2 : 1): const FixedColumnWidth(80),//SL
              (logic.isDeleteMode ? 3 : 2): const FixedColumnWidth(65),//Den
              (logic.isDeleteMode ? 4 : 3): const FixedColumnWidth(90),
              (logic.isDeleteMode ? 5 : 4): const FixedColumnWidth(55),
              (logic.isDeleteMode ? 6 : 5): const FixedColumnWidth(70),
              (logic.isDeleteMode ? 7 : 6): const FixedColumnWidth(120),
              (logic.isDeleteMode ? 8 : 7): const FixedColumnWidth(120),
              (logic.isDeleteMode ? 9 : 8): const FixedColumnWidth(55),
              (logic.isDeleteMode ? 10 : 9): const FixedColumnWidth(50),
            },
            children: [
              _buildHeaderRow(),
              ...logic.filteredList.map((t) => _buildTableRow(t)),
            ],
          ),
        ),
      ),
    );
  }
  //build header
  TableRow _buildHeaderRow() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TableRow(
      decoration: BoxDecoration(color: isDark ? Colors.orange[500] : Colors.orange[200],),
      children: [
        if (logic.isDeleteMode) const SizedBox(),
        _Header('Mã TO'),
        _Header('SL'),
        _Header('Đến'),
        _Header('Status'),
        _Header('KG'),
        _Header('Packer'),
        _Header('Thời Gian Tạo'),
        _Header('T/Gian Đóng'),
        _Header('View'),
        _Header('Sửa'),
      ],
    );
  }
  //build cot
TableRow _buildTableRow(TOModel t) {
  return TableRow(
    children: [
      if (logic.isDeleteMode)
        Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () {
              setState(() => logic.toggleSelect(t.maTO));
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: logic.selectedTOs.contains(t.maTO)
                      ? Colors.red
                      : Colors.grey,
                ),
                color: logic.selectedTOs.contains(t.maTO)
                    ? Colors.red
                    : Colors.transparent,
              ),
              child: logic.selectedTOs.contains(t.maTO)
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
        ),

      _Cell(t.maTO),
      _Cell('${t.soLuongDonHang}'),
      _Cell(t.diaDiemGiaoHang),

      Padding(
        padding: const EdgeInsets.all(6),
        child: t.trangThai.isEmpty
            ? const SizedBox()
            : Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: t.trangThai == 'Packed'
                ? Colors.green
                : Colors.red,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            t.trangThai,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),

      _Cell(t.totalWeight.toStringAsFixed(1)),
      _Cell(t.packer.isEmpty ? '—' : t.packer),
      _Cell(formatTime(t.ngayTao)),
      _Cell(t.completeTime != null
          ? formatTime(t.completeTime!)
          : '—'),
      Container(
        alignment: Alignment.center,
        child: IconButton(
          icon: Icon(Icons.visibility, color: Colors.blue),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BillTO(TO: t),
              ),
            );
          },
        ),
      ),
//inkWell: lam cho bat ki thu gi click dc, di chung voi onTap. IconButton: chi su dung cho icon, di chung voi onPressed
      Container(
        alignment: Alignment.center,
        child: IconButton(
          icon:  Icon(Icons.edit, color: Colors.orange),
          onPressed: () => _editTO(t),
        ),
      ),
    ],
  );
}
  // nut delete
  Widget _buildDeleteActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: logic.selectedTOs.isEmpty
                  ? null
                  : () async {
                await logic.deleteSelectedTOs();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:  Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 6,
                shadowColor:  Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              child: Text(
                'Xác nhận xóa (${logic.selectedTOs.length})',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                setState(() => logic.cancelDeleteMode());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Hủy',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
