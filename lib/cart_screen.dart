import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/order_history_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'receipt_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'order_tracking_screen.dart'; // Import ឈ្មោះ File ថ្មីដែលមេបានបង្កើត

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final NumberFormat currencyFormat = NumberFormat("#,###", "en_US");

  // ១. មុខងារប្តូរចំនួនទំនិញក្នុងកន្ត្រក់
  void _updateQuantity(String docId, int newQty) {
    if (newQty < 1) return;
    FirebaseFirestore.instance.collection('carts').doc(docId).update({
      'quantity': newQty,
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          "កន្ត្រករបស់ខ្ញុំ",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
              size: 28,
              color: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderHistoryScreen(),
              ),
            ),
          ),
          IconButton(
            // ប្រើរូបឡានដឹកអីវ៉ាន់ ដើម្បីឱ្យភ្ញៀវដឹងថាជាកន្លែងតាមដាន
            icon: const Icon(Icons.local_shipping_rounded, color: Colors.white),
            onPressed: () {
              // ចុចទៅវាបើកទៅកាន់ "ការិយាល័យតាមដានថ្មី" របស់មេ
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderTrackingScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8), // បន្ថែមគម្លាតបន្តិចពីគែមអេក្រង់
        ],
      ),
      body: Column(
        children: [
          _buildOrderTracking(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('carts')
                  .where('customer_id', isEqualTo: user?.uid)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return _buildEmptyCart();

                var docs = snapshot.data!.docs;
                double total = docs.fold(0, (sum, doc) {
                  double price =
                      double.tryParse(
                        doc['price'].toString().replaceAll(',', ''),
                      ) ??
                      0;
                  int qty =
                      int.tryParse(doc['quantity']?.toString() ?? '1') ?? 1;
                  return sum + (price * qty);
                });

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: docs.length,
                        itemBuilder: (context, index) =>
                            _buildModernCartItem(docs[index]),
                      ),
                    ),
                    _buildCheckoutButton(total, docs),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCartItem(QueryDocumentSnapshot item) {
    int qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    double price =
        double.tryParse(item['price'].toString().replaceAll(',', '')) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          // រូបភាពទំនិញ
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item['image_url'] != null && item['image_url'] != ""
                ? Image.network(
                    item['image_url'],
                    width: 55, // ✅ កំណត់ខ្នាត 55 តាមមេចង់បាន
                    height: 55,
                    fit: BoxFit.cover,
                    // 🛡️ ការពារផ្ទាំងក្រហម (Error: No host specified)
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 55,
                      height: 55,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 25,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    // กรณีไม่มี URL เลย ให้โชว์กล่องสีเทาแทน
                    width: 55,
                    height: 55,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 25,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? 'គ្មានឈ្មោះ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${currencyFormat.format(price)} ៛",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // 🎯 ផ្នែកវាយចំនួនដោយដៃ និងបូកដក
                Row(
                  children: [
                    _qtyBtn(
                      Icons.remove,
                      () => _updateQuantity(item.id, qty - 1),
                    ),

                    // ប្រអប់វាយលេខដៃក្នុងកន្ត្រក
                    Container(
                      width: 60,
                      height: 35,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        // បង្ហាញចំនួនបច្ចុប្បន្ន
                        controller: TextEditingController(text: "$qty")
                          ..selection = TextSelection.collapsed(
                            offset: "$qty".length,
                          ),
                        onSubmitted: (value) {
                          int? newQty = int.tryParse(value);
                          if (newQty != null && newQty > 0) {
                            _updateQuantity(
                              item.id,
                              newQty,
                            ); // Update ទៅ Firebase
                          }
                        },
                      ),
                    ),

                    _qtyBtn(Icons.add, () => _updateQuantity(item.id, qty + 1)),
                  ],
                ),
              ],
            ),
          ),

          // បង្ហាញតម្លៃសរុបក្នុងមួយមុខ (តម្លៃ x ចំនួន)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${currencyFormat.format(price * qty)} ៛",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () => item.reference.delete(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  // ២. ប៊ូតុង Checkout ដែលនឹងបាញ់កាលបរិច្ឆេទទៅឱ្យ Seller
  Widget _buildCheckoutButton(double total, List<QueryDocumentSnapshot> docs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () {
            // ពេលផ្ញើទៅ ReceiptScreen យើងនឹងផ្ញើទាំងម៉ោងបច្ចុប្បន្នទៅជាមួយ
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceiptScreen(
                  cartDocs: docs,
                  // កន្លែងនេះ ReceiptScreen ត្រូវទទួលយក Field នេះទៅដាក់ក្នុង orders collection
                ),
              ),
            );
          },
          child: Text(
            "បន្តទៅការទូទាត់ (${currencyFormat.format(total)} ៛)",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Widget ជំនួយ (Tracking, EmptyCart...) មេអាចប្រើកូដចាស់មេបាន
  Widget _buildEmptyCart() {
    return const Center(
      child: Text(
        "មិនទាន់មានទំនិញក្នុងកន្ត្រកទេ",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildOrderTracking() {
    // កូដ Tracking របស់មេ...
    return const SizedBox();
  }
}
