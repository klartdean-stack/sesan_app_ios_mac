import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'auction_admin_screen.dart';
import 'package:my_app/adminreport_screen.dart';
import 'admin_withdraw_list.dart';
import 'admin_history.dart';
import 'package:my_app/app_accountant_screen.dart';


class AdminConfirmPage extends StatelessWidget {
  const AdminConfirmPage({super.key});


  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');


    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          'បញ្ជាក់ការបង់ប្រាក់',
          style: TextStyle(
            fontFamily: 'Siemreap',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ── ប្រវត្តិ ────────────────────────────
          _buildAppBarBtn(
            icon: Icons.history_rounded,
            color: Colors.orangeAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHistoryPage()),
            ),
          ),


          // ── កណ្ដឹង Pending ─────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),


          // ── គណនេយ្យករ ───────────────────────────
          _buildAppBarBtn(
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppAccountantScreen()),
            ),
          ),


          // ── របាយការណ៍ ────────────────────────────
          _buildAppBarBtn(
            icon: Icons.bar_chart_rounded,
            color: Colors.lightBlueAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminReportScreen()),
            ),
          ),


          // ── ដេញថ្លៃ ──────────────────────────────
          _buildAppBarBtn(
            icon: Icons.gavel_rounded,
            color: Colors.pinkAccent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuctionAdminScreen()),
            ),
          ),


          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('មានបញ្ហាទាញទិន្នន័យ'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'មិនទាន់មានការកម្មង់ថ្មី',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontFamily: 'Siemreap',
                    ),
                  ),
                ],
              ),
            );
          }


          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var orderDoc = snapshot.data!.docs[index];
              var orderData = orderDoc.data() as Map<String, dynamic>;


              double totalPrice =
              (orderData['total_amount'] ?? orderData['total_price'] ?? 0)
                  .toDouble();
              String customerName =
                  orderData['customer_name'] ?? 'ភ្ញៀវមិនស្គាល់ឈ្មោះ';
              String phone = orderData['phone_number'] ?? 'មិនមានលេខ';
              String address =
                  orderData['shipping_address'] ?? 'មិនមានអាសយដ្ឋាន';
              String paymentImage =
                  orderData['payment_image'] ?? orderData['paymentProof'] ?? '';
              List items = orderData['items'] as List? ?? [];
              Timestamp timestamp = orderData['created_at'] ?? Timestamp.now();
              String formattedDate = DateFormat(
                'dd-MM-yyyy HH:mm',
              ).format(timestamp.toDate());


              return _buildOrderCard(
                context: context,
                format: currencyFormat,
                orderId: orderDoc.id,
                orderData: orderData,
                customerName: customerName,
                phone: phone,
                address: address,
                formattedDate: formattedDate,
                paymentImage: paymentImage,
                items: items,
                totalPrice: totalPrice,
              );
            },
          );
        },
      ),
    );
  }


  // ── AppBar Icon Button ────────────────────────────────────
  static Widget _buildAppBarBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 24),
      onPressed: onTap,
    );
  }


  // ── Order Card ────────────────────────────────────────────
  Widget _buildOrderCard({
    required BuildContext context,
    required NumberFormat format,
    required String orderId,
    required Map<String, dynamic> orderData,
    required String customerName,
    required String phone,
    required String address,
    required String formattedDate,
    required String paymentImage,
    required List items,
    required double totalPrice,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Customer Header ───────────────────────
          _buildCustomerHeader(customerName, formattedDate, phone, address),


          // ── Seller + Items ────────────────────────
          _buildSellerAndItemsSection(orderData, items),


          // ── Payment Proof ─────────────────────────
          if (paymentImage.isNotEmpty) ...[
            const Divider(height: 1),
            _buildPaymentProof(context, paymentImage),
          ],


          // ── Footer ────────────────────────────────
          _buildActionFooter(context, format, totalPrice, orderId, orderData),
        ],
      ),
    );
  }


  // ── Customer Header ───────────────────────────────────────
  Widget _buildCustomerHeader(
      String name,
      String date,
      String phone,
      String address,
      ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFFE8EAF6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF3949AB),
            radius: 22,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Siemreap',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '📅 $date',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  '📞 $phone',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  '📍 $address',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ── Seller + Items Section ────────────────────────────────
  // ── Seller + Items Section ────────────────────────────────
  Widget _buildSellerAndItemsSection(
      Map<String, dynamic> orderData,
      List items,
      ) {
    // 🎯 ១. ទាញទិន្នន័យអ្នកលក់ (ព្យាយាមទាញពី orderData បើអត់មាន ទាញពី Item ទី១)
    String sellerName =
        orderData['seller_name']?.toString() ??
            (items.isNotEmpty ? items[0]['seller_name']?.toString() : null) ??
            'មិនស្គាល់ឈ្មោះ';


    String sellerPhoto =
        orderData['seller_photo']?.toString() ??
            (items.isNotEmpty ? items[0]['seller_photo']?.toString() : null) ??
            '';


    String sellerPhone =
        orderData['seller_phone']?.toString() ??
            (items.isNotEmpty ? items[0]['seller_phone']?.toString() : null) ??
            'គ្មានលេខ';


    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.green.shade100,
                  backgroundImage: sellerPhoto.isNotEmpty
                      ? NetworkImage(sellerPhoto)
                      : null,
                  child: sellerPhoto.isEmpty
                      ? Icon(
                    Icons.storefront_rounded,
                    color: Colors.green[700],
                    size: 22,
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sellerName, // 🎯 បង្ហាញឈ្មោះអ្នកលក់ដែលទាញបាន
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Siemreap',
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android_rounded,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sellerPhone, // 🎯 បង្ហាញលេខទូរស័ព្ទ
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ... កូដផ្សេងៗទៀតរក្សាទុកដដែល
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🏪 អ្នកលក់',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 11,
                      fontFamily: 'Siemreap',
                    ),
                  ),
                ),
              ],
            ),
          ),


          const SizedBox(height: 12),
          Text(
            '📦 បញ្ជីទំនិញ (${items.length} ប្រភេទ)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'Siemreap',
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _buildItemRow(item)),
        ],
      ),
    );
  }


  // ── Item Row ──────────────────────────────────────────────
  Widget _buildItemRow(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
            item['image_url'] != null &&
                item['image_url'].toString().isNotEmpty
                ? Image.network(
              item['image_url'],
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImgPlaceholder(),
            )
                : _buildImgPlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? 'ទំនិញ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'Siemreap',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${NumberFormat('#,###').format(double.tryParse(item['price']?.toString() ?? '0') ?? 0)} ៛ / ចំនួន ${item['quantity'] ?? 1}',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'x${item['quantity'] ?? 1}',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildImgPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: Colors.grey[200],
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }


  // ── Payment Proof ─────────────────────────────────────────
  Widget _buildPaymentProof(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => _showFullImage(context, url),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🔍 ចុចពង្រីក',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'Siemreap',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ── Action Footer ─────────────────────────────────────────
  Widget _buildActionFooter(
      BuildContext context,
      NumberFormat format,
      double total,
      String orderId,
      Map<String, dynamic> orderData,
      ) {
    double commission = total * 0.07;
    double sellerEarns = total - commission;


    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Summary Row ───────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSummaryLine(
                  'ទឹកប្រាក់សរុប',
                  '${format.format(total)} ៛',
                  Colors.black87,
                  isBold: true,
                ),
                const Divider(height: 12),
                _buildSummaryLine(
                  'App Commission (7%)',
                  '${format.format(commission)} ៛',
                  Colors.orange,
                ),
                _buildSummaryLine(
                  'អ្នកលក់ទទួល (93%)',
                  '${format.format(sellerEarns)} ៛',
                  Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),


          // ── Buttons ───────────────────────────────
          Row(
            children: [
              // Reject
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleRejectOrder(context, orderId),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: const Text(
                    'បដិសេធ',
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'Siemreap',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Confirm
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _handleConfirmOrder(context, orderId, total),
                  icon: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'យល់ព្រមបូកលុយ',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Siemreap',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildSummaryLine(
      String label,
      String value,
      Color color, {
        bool isBold = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Siemreap',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              color: color,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  // ── Confirm Logic ─────────────────────────────────────────
  Future<void> _handleConfirmOrder(
      BuildContext context,
      String orderId,
      double totalOrderAmount,
      ) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      if (!docSnapshot.exists) return;


      final orderData = docSnapshot.data() as Map<String, dynamic>;
      List items = orderData['items'] as List? ?? [];
      String cName = orderData['customer_name'] ?? 'ភ្ញៀវមិនស្គាល់ឈ្មោះ';
      String cPhone = orderData['phone_number'] ?? 'មិនមានលេខ';
      String pImage =
          orderData['payment_image'] ?? orderData['paymentProof'] ?? '';


      bool? confirm = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '✅ បញ្ជាក់ការបង់ប្រាក់',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'បុងលេខ: ${orderId.substring(0, 8).toUpperCase()}\n\nតើបានពិនិត្យស្លីបរួចហើយមែន? លុយ 7% នឹងចូល Pending គណនេយ្យករ!',
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Siemreap',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ទេ', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'យល់ព្រម',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;


      WriteBatch batch = FirebaseFirestore.instance.batch();
      double totalAppCommission = 0;


      for (var item in items) {
        String currentSellerId = item['seller_id'] ?? '';
        if (currentSellerId.isEmpty) continue;


        final sellerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentSellerId)
            .get();
        String realSellerName = sellerDoc.data()?['name'] ?? 'មិនស្គាល់ឈ្មោះ';
        String realSellerPhone = sellerDoc.data()?['phone'] ?? 'គ្មានលេខ';


        double itemPrice = (item['price'] ?? 0).toDouble();
        int itemQty = (item['quantity'] ?? 1).toInt();
        double itemTotal = itemPrice * itemQty;
        double adminCommission = itemTotal * 0.07;
        double sellerNet = itemTotal - adminCommission;
        totalAppCommission += adminCommission;
        var refHistory = FirebaseFirestore.instance
            .collection('admin_confirm_history')
            .doc();
        batch.set(refHistory, {
          'order_id': orderId,
          'product_name': item['product_name'] ?? 'ទំនិញ',
          'amount': itemTotal,
          'seller_earnings': sellerNet,
          'customer_name': cName,
          'customer_phone': cPhone,
          'seller_id': currentSellerId,
          'seller_name': realSellerName,
          'seller_phone': realSellerPhone,
          'receipt_image': pImage,
          'confirm_date': FieldValue.serverTimestamp(),
          'status': 'confirmed',
        });
      }


      var walletRef = FirebaseFirestore.instance
          .collection('system_settings')
          .doc('wallet');
      batch.set(walletRef, {
        'pending_gross_100': FieldValue.increment(totalOrderAmount),
        'pending_commissions': FieldValue.increment(totalOrderAmount * 0.07),
      }, SetOptions(merge: true));


      batch.update(
        FirebaseFirestore.instance.collection('orders').doc(orderId),
        {
          'status': 'confirmed',
          'admin_confirmed_at': FieldValue.serverTimestamp(),
        },
      );


      await batch.commit();


      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            '✅ Admin បញ្ជាក់ជោគជ័យ!',
            style: TextStyle(fontFamily: 'Siemreap'),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Confirm Error: $e');
    }
  }


  // ── Reject Logic ──────────────────────────────────────────
  Future<void> _handleRejectOrder(BuildContext context, String orderId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '❌ បដិសេធការកម្មង់?',
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        content: const Text(
          'ករណីអស់ទំនិញ ឬកម្មង់ខ្យល់ — Order នេះនឹងត្រូវបានលុបចោល!',
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ទេ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('យល់ព្រម', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );


    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
          'status': 'rejected',
          'rejected_at': FieldValue.serverTimestamp(),
        });
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'បានបដិសេធ Order!',
              style: TextStyle(fontFamily: 'Siemreap'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        debugPrint('Reject Error: $e');
      }
    }
  }


  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(child: Image.network(url)),
      ),
    );
  }
}



