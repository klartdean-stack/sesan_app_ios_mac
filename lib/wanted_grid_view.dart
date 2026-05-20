import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/wanted_detail_screen.dart';

class WantedGridView extends StatelessWidget {
  const WantedGridView({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎯 Filter យកតែផុសក្នុងរង្វង់ ១៥ ថ្ងៃ
    DateTime fifteenDaysAgo = DateTime.now().subtract(const Duration(days: 15));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wanted_products')
          .where('createdAt', isGreaterThanOrEqualTo: fifteenDaysAgo)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text("មានបញ្ហាភ្ជាប់ទិន្នន័យ"));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text("មិនទាន់មានការប្រកាសទិញទេ"));

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: docs.length,
          // ✅ កូដដែលត្រឹមត្រូវ
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            data['id'] = docs[index].id;
            return _buildWantedCard(
              context,
              data,
            ); // 🎯 ថែម context ចូលទីនេះជាការស្រេច
          },
        );
      },
    );
  }

  Widget _buildWantedCard(BuildContext context, Map<String, dynamic> data) {
    // --- ១. Logic គណនាថ្ងៃផុតកំណត់ (រក្សាទុកដដែល) ---
    DateTime createdAt = (data['createdAt'] as Timestamp).toDate();
    DateTime expiryDate = createdAt.add(const Duration(days: 15));
    Duration remaining = expiryDate.difference(DateTime.now());
    int daysLeft = remaining.inDays;
    String countdownText = daysLeft > 0
        ? "នៅសល់ $daysLeft ថ្ងៃ"
        : "ជិតផុតកំណត់";

    return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WantedDetailScreen(data: data),
            ),
          );
        },
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.blue, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Expanded(
            child: Stack(
            children: [
              // 🎯 កន្លែងរូបភាពទំនិញ (កែឱ្យត្រូវនឹង List)
              Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                image: DecorationImage(
                  // 🎯 កែត្រង់នេះ៖ ទាញយករូបទី ១ ចេញពី List (imageUrls[0])
                  image:
                  (data['imageUrls'] != null &&
                      (data['imageUrls'] as List).isNotEmpty)
                      ? NetworkImage(
                    data['imageUrls'][0],
                  ) // យកតែរូបទី ១ មកបង្ហាញក្នុង Grid
                      : const AssetImage('assets/no_image.png')
                  as ImageProvider, // បើអត់រូប ឱ្យចេញរូបជំនួស
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
                top: 5,
                right: 5,
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8,
                      vertical: 4,
                    ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    countdownText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
            ),
            ],
            ),
            ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['productName'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "📅 ${createdAt.day}/${createdAt.month}/${createdAt.year}",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ត្រូវការ៖ ${data['quantity']} ${data['unit']}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "តម្លៃ៖ ${data['price']} ${data['currency']}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "📍 ${data['location']}",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
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