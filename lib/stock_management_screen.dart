import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';


import 'package:shared_preferences/shared_preferences.dart';


class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});


  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}


class _StockManagementScreenState extends State<StockManagementScreen>
    with SingleTickerProviderStateMixin {
  // ✅ ថ្មី
  String userId = '';
  bool _isLoading = true;
  String _searchQuery = '';
  // ✅ ថ្មី — ដូរ late TabController មក TabController?
  TabController? _tabController;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // ✅ init មុន
    _loadUser();
  }


  @override
  void dispose() {
    _tabController?.dispose(); // ✅ បន្ថែម ?
    super.dispose();
  }


  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_uid') ?? '';


    if (uid.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }


    if (mounted) {
      setState(() {
        userId = uid;
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: const Text(
          'គ្រប់គ្រងស្តុកទំនិញ',
          style: TextStyle(fontFamily: 'Siemreap', fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'ស្តុក'),
            Tab(icon: Icon(Icons.history), text: 'ប្រវត្តិ'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStockTab(), _buildHistoryTab()],
      ),
    );
  }


  // ===================== STOCK TAB =====================
  Widget _buildStockTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'ស្វែងរកទំនិញ...',
              hintStyle: const TextStyle(fontFamily: 'Siemreap'),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),


        // Stock list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('stock_items')
                .orderBy('updatedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }


              var docs = snapshot.data!.docs.where((doc) {
                final name = (doc['name'] ?? '').toString().toLowerCase();
                return _searchQuery.isEmpty || name.contains(_searchQuery);
              }).toList();


              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'មិនទាន់មានទំនិញ\nចុច + ដើម្បីបន្ថែម',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontFamily: 'Siemreap',
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }


              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildStockCard(data, doc.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildStockCard(Map<String, dynamic> data, String docId) {
    int quantity = (data['quantity'] ?? 0).toInt();
    int minAlert = (data['minAlert'] ?? 5).toInt();
    bool isLow = quantity <= minAlert;
    bool isOut = quantity == 0;


    Color statusColor = isOut
        ? Colors.red
        : isLow
        ? Colors.orange
        : Colors.green;


    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLow
            ? Border.all(color: statusColor.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // រូបភាព
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: data['imageUrl'] != null && data['imageUrl'].isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: data['imageUrl'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[100],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                errorWidget: (_, __, ___) => _buildPlaceholderImage(),
              )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 12),


            // ព័ត៌មាន
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Siemreap',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (data['category'] != null &&
                      data['category'].toString().isNotEmpty)
                    Text(
                      data['category'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontFamily: 'Siemreap',
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (data['price'] != null)
                        Text(
                          '${_formatNumber(data['price'])} ៛',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (data['price'] != null) const SizedBox(width: 8),
                      // ស្ថានភាព
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOut
                              ? '❌ អស់ស្តុក'
                              : isLow
                              ? '⚠️ ជិតអស់'
                              : '✅ មាន',
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontFamily: 'Siemreap',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),


            // ចំនួន + ប៊ូតុង
            Column(
              children: [
                // ចំនួនស្តុក
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$quantity ${data['unit'] ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontFamily: 'Siemreap',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ប៊ូតុង + -
                Row(
                  children: [
                    _buildQtyButton(
                      icon: Icons.remove,
                      color: Colors.red,
                      onTap: () => _showAdjustDialog(data, docId, false),
                    ),
                    const SizedBox(width: 8),
                    _buildQtyButton(
                      icon: Icons.add,
                      color: Colors.green,
                      onTap: () => _showAdjustDialog(data, docId, true),
                    ),
                    const SizedBox(width: 8),
                    _buildQtyButton(
                      icon: Icons.more_vert,
                      color: Colors.grey,
                      onTap: () => _showItemOptions(data, docId),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.inventory_2, color: Colors.grey[400], size: 28),
    );
  }


  Widget _buildQtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }


  // ===================== HISTORY TAB =====================
  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('stock_history')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }


        final docs = snapshot.data!.docs;


        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'មិនទាន់មានប្រវត្តិ',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'Siemreap',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }


        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildHistoryCard(data);
          },
        );
      },
    );
  }


  Widget _buildHistoryCard(Map<String, dynamic> data) {
    int change = (data['changeAmount'] ?? 0).toInt();
    bool isAdd = change > 0;
    DateTime? time;
    if (data['timestamp'] != null) {
      time = (data['timestamp'] as Timestamp).toDate();
    }


    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAdd
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAdd ? Icons.add : Icons.remove,
              color: isAdd ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['itemName'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Siemreap',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (data['reason'] != null &&
                    data['reason'].toString().isNotEmpty)
                  Text(
                    data['reason'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Siemreap',
                    ),
                  ),
                if (time != null)
                  Text(
                    DateFormat('dd MMM yyyy  hh:mm a').format(time),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
              ],
            ),
          ),
          Text(
            '${isAdd ? '+' : ''}$change',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isAdd ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }


  // ===================== DIALOGS =====================


  // ✅ Dialog បន្ថែមទំនិញថ្មី
  void _showAddItemDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final priceCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'កញ្ចប់');
    final categoryCtrl = TextEditingController();
    final minAlertCtrl = TextEditingController(text: '5');
    File? imageFile;
    String? imageUrl;


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'បន្ថែមទំនិញថ្មី',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Siemreap',
                  ),
                ),
                const SizedBox(height: 20),


                // រូបភាព
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                      );
                      if (file != null) {
                        setModalState(() => imageFile = File(file.path));
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: imageFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(imageFile!, fit: BoxFit.cover),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'រូបភាព',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontFamily: 'Siemreap',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),


                _buildTextField(
                  nameCtrl,
                  'ឈ្មោះទំនិញ *',
                  Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        qtyCtrl,
                        'ចំនួន',
                        Icons.numbers,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        unitCtrl,
                        'ឯកតា',
                        Icons.straighten,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        priceCtrl,
                        'តម្លៃ (៛)',
                        Icons.monetization_on_outlined,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        categoryCtrl,
                        'ប្រភេទ',
                        Icons.category_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  minAlertCtrl,
                  'ព្រមានបើស្តុកដល់',
                  Icons.warning_amber_outlined,
                  isNumber: true,
                ),
                const SizedBox(height: 24),


                // ប៊ូតុង Save
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        _showSnack('សូមបញ្ចូលឈ្មោះទំនិញ', Colors.red);
                        return;
                      }


                      try {
                        File uploadFile = imageFile!;


                        // ✅ ដាក់ getTemporaryDirectory ក្នុង try
                        final dir = await getTemporaryDirectory();
                        final targetPath =
                            '${dir.path}/stock_${DateTime.now().millisecondsSinceEpoch}.jpg';


                        final compressed =
                        await FlutterImageCompress.compressAndGetFile(
                          imageFile!.path,
                          targetPath,
                          quality: 60,
                        );


                        if (compressed != null &&
                            await File(compressed.path).exists()) {
                          uploadFile = File(compressed.path);
                        }


                        final ref = FirebaseStorage.instance.ref().child(
                          'stock_images/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                        );
                        await ref.putFile(uploadFile);
                        imageUrl = await ref.getDownloadURL();
                      } catch (e) {
                        debugPrint('Image upload error: $e');
                        try {
                          final ref = FirebaseStorage.instance.ref().child(
                            'stock_images/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );
                          await ref.putFile(imageFile!);
                          imageUrl = await ref.getDownloadURL();
                        } catch (e2) {
                          debugPrint('Upload original error: $e2');
                        }
                      }


                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('stock_items')
                          .add({
                        'name': nameCtrl.text.trim(),
                        'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                        'unit': unitCtrl.text.trim(),
                        'price': double.tryParse(priceCtrl.text) ?? 0,
                        'category': categoryCtrl.text.trim(),
                        'minAlert': int.tryParse(minAlertCtrl.text) ?? 5,
                        'imageUrl': imageUrl ?? '',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });


                      Navigator.pop(context);
                      _showSnack('✅ បានបន្ថែមទំនិញ', Colors.green);
                    },
                    child: const Text(
                      'រក្សាទុក',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Siemreap',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ✅ Dialog បន្ថែម/កាត់ស្តុក
  void _showAdjustDialog(Map<String, dynamic> data, String docId, bool isAdd) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();


    final reasons = isAdd
        ? ['ទិញបន្ថែម', 'ទទួលពីបរទេស', 'ត្រឡប់ពីអតិថិជន', 'ផ្សេងៗ']
        : ['លក់', 'ខូច/បាត់', 'ប្រើប្រាស់', 'ផ្សេងៗ'];


    String selectedReason = reasons[0];


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      isAdd ? Icons.add_circle : Icons.remove_circle,
                      color: isAdd ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAdd ? 'បន្ថែមស្តុក' : 'កាត់ស្តុក',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Siemreap',
                        color: isAdd ? Colors.green : Colors.red,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${data['name']}',
                      style: const TextStyle(
                        fontFamily: 'Siemreap',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),


                // ចំនួន
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'ចំនួន',
                    labelStyle: const TextStyle(fontFamily: 'Siemreap'),
                    prefixIcon: Icon(
                      Icons.numbers,
                      color: isAdd ? Colors.green : Colors.red,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isAdd ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),


                // មូលហេតុ
                const Text(
                  'មូលហេតុ',
                  style: TextStyle(fontFamily: 'Siemreap', fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: reasons.map((r) {
                    bool selected = selectedReason == r;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedReason = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? (isAdd ? Colors.green : Colors.red)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            fontFamily: 'Siemreap',
                            fontSize: 13,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),


                // ចំណាំបន្ថែម
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'ចំណាំបន្ថែម (ជម្រើស)',
                    labelStyle: const TextStyle(fontFamily: 'Siemreap'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),


                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdd
                          ? Colors.green[700]
                          : Colors.red[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      int amount = int.tryParse(amountCtrl.text) ?? 0;
                      if (amount <= 0) {
                        _showSnack('សូមបញ្ចូលចំនួន', Colors.orange);
                        return;
                      }


                      int currentQty = (data['quantity'] ?? 0).toInt();
                      int newQty = isAdd
                          ? currentQty + amount
                          : currentQty - amount;


                      if (newQty < 0) {
                        _showSnack('ស្តុកមិនគ្រប់គ្រាន់!', Colors.red);
                        return;
                      }


                      final batch = FirebaseFirestore.instance.batch();
                      final itemRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('stock_items')
                          .doc(docId);
                      final historyRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('stock_history')
                          .doc();


                      batch.update(itemRef, {
                        'quantity': newQty,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });


                      batch.set(historyRef, {
                        'itemId': docId,
                        'itemName': data['name'],
                        'changeAmount': isAdd ? amount : -amount,
                        'reason': reasonCtrl.text.isNotEmpty
                            ? reasonCtrl.text
                            : selectedReason,
                        'timestamp': FieldValue.serverTimestamp(),
                      });


                      await batch.commit();
                      Navigator.pop(context);
                      _showSnack(
                        isAdd
                            ? '✅ បន្ថែម $amount ${data['unit'] ?? ''}'
                            : '✅ កាត់ $amount ${data['unit'] ?? ''}',
                        isAdd ? Colors.green : Colors.orange,
                      );
                    },
                    child: Text(
                      isAdd ? 'បន្ថែមស្តុក' : 'កាត់ស្តុក',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Siemreap',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ✅ Options (កែ / លុប)
  void _showItemOptions(Map<String, dynamic> data, String docId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'កែប្រែ',
                  style: TextStyle(fontFamily: 'Siemreap'),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(data, docId);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'លុបទំនិញ',
                  style: TextStyle(fontFamily: 'Siemreap', color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(docId, data['name']);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ✅ Edit Dialog
  void _showEditDialog(Map<String, dynamic> data, String docId) {
    final nameCtrl = TextEditingController(text: data['name']);
    final priceCtrl = TextEditingController(text: '${data['price'] ?? ''}');
    final unitCtrl = TextEditingController(text: data['unit'] ?? '');
    final categoryCtrl = TextEditingController(text: data['category'] ?? '');
    final minAlertCtrl = TextEditingController(
      text: '${data['minAlert'] ?? 5}',
    );


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'កែប្រែទំនិញ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Siemreap',
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                nameCtrl,
                'ឈ្មោះទំនិញ',
                Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(unitCtrl, 'ឯកតា', Icons.straighten),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      categoryCtrl,
                      'ប្រភេទ',
                      Icons.category_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      priceCtrl,
                      'តម្លៃ (៛)',
                      Icons.monetization_on_outlined,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      minAlertCtrl,
                      'ព្រមានបើស្តុកដល់',
                      Icons.warning_amber_outlined,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('stock_items')
                        .doc(docId)
                        .update({
                      'name': nameCtrl.text.trim(),
                      'unit': unitCtrl.text.trim(),
                      'category': categoryCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text) ?? 0,
                      'minAlert': int.tryParse(minAlertCtrl.text) ?? 5,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                    _showSnack('✅ បានកែប្រែ', Colors.blue);
                  },
                  child: const Text(
                    'រក្សាទុក',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Siemreap',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }


  void _confirmDelete(String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'លុបទំនិញ?',
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        content: Text(
          'តើអ្នកចង់លុប "$name" ចេញ?',
          style: const TextStyle(fontFamily: 'Siemreap'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'បោះបង់',
              style: TextStyle(fontFamily: 'Siemreap'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('stock_items')
                  .doc(docId)
                  .delete();
              _showSnack('បានលុប "$name"', Colors.red);
            },
            child: const Text(
              'លុប',
              style: TextStyle(color: Colors.white, fontFamily: 'Siemreap'),
            ),
          ),
        ],
      ),
    );
  }


  // ===================== HELPERS =====================
  Widget _buildTextField(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool isNumber = false,
      }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Siemreap', fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[700]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
    );
  }


  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final n = double.tryParse(value.toString()) ?? 0;
    return NumberFormat('#,##0').format(n);
  }


  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontFamily: 'Siemreap'),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}



