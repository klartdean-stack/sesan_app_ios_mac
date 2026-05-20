import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pre_order_detail_screen.dart';


class PreOrderGridView extends StatelessWidget {
  const PreOrderGridView({super.key});


  // ✅ static final - បង្កើតតែម្តង
  static final formatter = NumberFormat('#,###');


  bool isExpired(dynamic harvestDateData) {
    if (harvestDateData == null) return false;


    DateTime harvestDate;
    if (harvestDateData is Timestamp) {
      harvestDate = harvestDateData.toDate();
    } else {
      return false;
    }


    return DateTime.now().isAfter(harvestDate.add(const Duration(days: 1)));
  }


  // ✅ Format តម្លៃដោយកាត់ .0
  String formatPrice(dynamic price) {
    if (price == null) return '0';
    int priceInt = (price is double) ? price.toInt() : (price as num).toInt();
    return '${formatter.format(priceInt)} ៛';
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInfoCard(context),


        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pre_orders')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }


              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }


              // ✅ Filter ចោលផលិតផលដែលផុតកំណត់
              var docs = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                return !isExpired(data['harvest_date']);
              }).toList();


              if (docs.isEmpty) return _buildEmptyState();


              return GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String docId = docs[index].id;
                  return _buildPreOrderCard(context, data, docId);
                },
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade400],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "យល់ដឹងពីមុខងារ 'លក់មុន'",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Siemreap',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "មុខងារនេះផ្ដល់ឱកាសឱ្យម្ចាស់ចម្ការ និងសហគ្រិន បង្កើតការលក់ទុកជាមុន (Pre-order) ដើម្បីធានាបាននូវទីផ្សារ និងការកក់ពីអតិថិជនយ៉ាងច្បាស់លាស់ សូម្បីតែមុនពេលប្រមូលផល ឬចាប់ផ្ដើមផលិត។",
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'Siemreap',
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _showBenefitDialog(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              "🔍 អានអត្ថប្រយោជន៍បន្ថែម",
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showBenefitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "អត្ថប្រយោជន៍នៃការលក់មុន (Pre-order)",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _benefitItem(
                Icons.account_balance_wallet_rounded,
                "យុទ្ធសាស្ត្រសម្រាប់ម្ចាស់អាជីវកម្ម",
                "កាត់បន្ថយហានិភ័យនៃតុល្យភាពទីផ្សារ (Market Risk) ធានាបាននូវលំហូរទុនបង្វិល និងបង្កើនប្រសិទ្ធភាពក្នុងការគ្រប់គ្រងស្ដុកកសិផល។",
              ),
              _benefitItem(
                Icons.hub_rounded,
                "ដំណោះស្រាយសម្រាប់ម្ចាស់គម្រោង",
                "ពង្រឹងខ្សែចង្វាក់ផ្គត់ផ្គង់ (Supply Chain) ឱ្យមានស្ថេរភាព និងបង្កើតអំណាចចរចាទីផ្សារទុកជាមុនជូនដល់សមាជិកក្នុងបណ្ដាញផលិតកម្ម។",
              ),
              _benefitItem(
                Icons.stars_rounded,
                "អត្ថប្រយោជន៍សម្រាប់អតិថិជន",
                "ទទួលបានតម្លៃយុទ្ធសាស្ត្រ (Competitive Price) ធានាបាននូវប្រភពទំនិញពិតប្រាកដ និងកាត់បន្ថយភាពមិនច្បាស់លាស់នៃតម្លៃនៅលើទីផ្សារ។",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("បិទ", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }


  Widget _benefitItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ✅ កាតបង្ហាញទំនិញដែលបាន Fix
  Widget _buildPreOrderCard(
      BuildContext context,
      Map<String, dynamic> data,
      String docId,
      ) {
    // ✅ ទាញយករូបភាពពី array
    List<dynamic> images = data['images'] ?? [];
    String? firstImage = images.isNotEmpty ? images[0] : null;


    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PreOrderDetailScreen(data: data, documentId: docId),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Fix #2: បង្ហាញរូបភាពពិតប្រាកដ
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: firstImage != null
                    ? Image.network(
                  firstImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ឈ្មោះផលិតផល
                  Text(
                    data['product_name'] ?? 'មិនមានឈ្មោះ',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Siemreap',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // ✅ Fix #1: តម្លៃដែលបាន Format ត្រឹមត្រូវ
                  Text(
                    formatPrice(data['price']),
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ឯកតា
                  Text(
                    "/ ${data['unit'] ?? 'ឯកតា'}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontFamily: 'Siemreap',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "ផុសថ្ងៃ: ${_formatDate(data['created_at'])}", // បង្ហាញថ្ងៃផុស
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                  // Badge Pre-order
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Text(
                          "Pre-order",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // បង្ហាញថ្ងៃប្រមូលផល
                      if (data['harvest_date'] != null)
                        Text(
                          _formatShortDate(data['harvest_date']),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
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


  // ✅ Helper សម្រាប់ format ថ្ងៃខែខ្លី
  String _formatShortDate(dynamic dateData) {
    if (dateData is Timestamp) {
      return DateFormat('dd/MM').format(dateData.toDate());
    }
    return '';
  }


  // បន្ថែម Helper Function សម្រាប់ Format ថ្ងៃខែ
  String _formatDate(dynamic dateData) {
    if (dateData is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(dateData.toDate());
    }
    return '---';
  }


  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 50,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "មិនទាន់មានការប្រកាសលក់មុននៅឡើយទេ",
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Siemreap',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



