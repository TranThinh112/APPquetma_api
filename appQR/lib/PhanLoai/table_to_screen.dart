/// =============================================================
/// File: table_to_screen.dart
/// Mô tả: UI (giao diện) cho màn hình "Table TO" - Danh sách bao hàng.
///        Logic xử lý nằm trong table_to_logic.dart.
/// =============================================================
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/to_model.dart';
import 'create_to_screen.dart';
import 'table_to_logic.dart';

class TableTOScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const TableTOScreen({super.key, this.user});

  @override
  State<TableTOScreen> createState() => _TableTOScreenState();
}

class _TableTOScreenState extends State<TableTOScreen> {
  final TableTOLogic logic = TableTOLogic();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshList();
  }

  Future<void> _refreshList() async {
    await logic.refreshList();
    logic.search(searchController.text);
    setState(() {});
  }

  void _search(String keyword) {
    logic.search(keyword);
    setState(() {});
  }

  /// Mở CreateTOScreen ở chế độ chỉnh sửa
  void _editTO(TOModel to) async {
    final isAdmin = widget.user?['username'] == 'admin';
    final isPacked = to.trangThai == 'Packed';

    // Chỉ admin mới sửa được TO đã đóng (Packed)
    if (isPacked && !isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ Admin mới được sửa bao TO đã đóng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTOScreen(editTO: to, user: widget.user),
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
                  final code =
                      capture.barcodes.first.rawValue?.trim() ?? '';
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
            Expanded(child: _buildTable()),
            if (logic.isDeleteMode) _buildDeleteActions(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // UI Components
  // ══════════════════════════════════════

  Widget _buildHeader() {
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
                if (widget.user?['username'] == 'admin')
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white),
                    onPressed: () {
                      setState(() => logic.toggleDeleteMode());
                    },
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
                    Icon(Icons.search, color: Colors.orange[600]),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.orange[600]!, width: 2),
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
              color: Colors.orange[700],
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

  Widget _buildTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: Colors.grey[400]!, width: 1),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          columnWidths: {
            if (logic.isDeleteMode) 0: const FixedColumnWidth(40),
            (logic.isDeleteMode ? 1 : 0): const FixedColumnWidth(170),
            (logic.isDeleteMode ? 2 : 1): const FixedColumnWidth(90),
            (logic.isDeleteMode ? 3 : 2): const FixedColumnWidth(120),
            (logic.isDeleteMode ? 4 : 3): const FixedColumnWidth(95),
            (logic.isDeleteMode ? 5 : 4): const FixedColumnWidth(80),
            (logic.isDeleteMode ? 6 : 5): const FixedColumnWidth(120),
            (logic.isDeleteMode ? 7 : 6): const FixedColumnWidth(120),
            (logic.isDeleteMode ? 8 : 7): const FixedColumnWidth(120),
            (logic.isDeleteMode ? 9 : 8): const FixedColumnWidth(70),
          },
          children: [
            // Header row
            _buildHeaderRow(),
            // Data rows
            ...logic.filteredList.map((to) => _buildDataRow(to)),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    const headerStyle = TextStyle(
        fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black);
    return TableRow(
      decoration: BoxDecoration(color: Colors.orange[100]),
      children: [
        if (logic.isDeleteMode)
          const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(width: 20)),
        const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Mã TO',
                style: headerStyle, textAlign: TextAlign.center)),
        const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Số lượng',
                style: headerStyle, textAlign: TextAlign.center)),
        const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Station',
                style: headerStyle, textAlign: TextAlign.center)),
        const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Trạng thái',
                style: headerStyle, textAlign: TextAlign.center)),
        const Padding(
            padding: EdgeInsets.all(10),
            child: Text('KG',
                style: headerStyle, textAlign: TextAlign.center)),
        const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Packer',
                style: headerStyle, textAlign: TextAlign.center)),
        const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Create time',
                style: headerStyle, textAlign: TextAlign.center)),
        const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Complete time',
                style: headerStyle, textAlign: TextAlign.center)),
        const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Sửa',
                style: headerStyle, textAlign: TextAlign.center)),
      ],
    );
  }

  TableRow _buildDataRow(TOModel to) {
    final isPacked = to.trangThai == 'Packed';
    return TableRow(
      children: [
        if (logic.isDeleteMode)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => logic.toggleSelect(to.maTO));
                },
                borderRadius: BorderRadius.circular(4),
                splashColor: Colors.blue.withOpacity(0.3),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: logic.selectedTOs.contains(to.maTO)
                          ? Colors.red
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: logic.selectedTOs.contains(to.maTO)
                        ? Colors.red
                        : Colors.transparent,
                  ),
                  child: logic.selectedTOs.contains(to.maTO)
                      ? const Icon(Icons.check,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Text(to.maTO,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13))),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Text('${to.soLuongDonHang}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13))),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
                to.diaDiemGiaoHang.isEmpty ? '—' : to.diaDiemGiaoHang,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12))),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPacked ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(to.trangThai,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Text('${to.totalWeight.toStringAsFixed(1)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13))),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Text(to.packer.isEmpty ? '—' : to.packer,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13))),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Text(logic.formatTime(to.ngayTao),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12))),
        Padding(
            padding: const EdgeInsets.all(10),
            child: Text(logic.formatTime(to.completeTime),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12))),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _editTO(to),
              borderRadius: BorderRadius.circular(20),
              splashColor: Colors.orange.withOpacity(0.3),
              child: Icon(Icons.edit,
                  color: Colors.orange[600], size: 22),
            ),
          ),
        ),
      ],
    );
  }

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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 6,
                shadowColor: Colors.red.withOpacity(0.5),
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
