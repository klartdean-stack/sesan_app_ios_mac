import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // កុំភ្លេច add intl ក្នុង pubspec.yaml

class SackHistoryScreen extends StatelessWidget {
  const SackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text("ប្រវត្តិថ្លឹងបាវ"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ទាញយកទិន្នន័យទាំងអស់របស់ User ម្នាក់ហ្នឹង ដោយរៀបតាមថ្ងៃខែថ្មីបំផុតនៅខាងលើ
        stream: FirebaseFirestore.instance
            .collection('rice_records')
            .where('seller_id', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("មានបញ្ហាទាញទិន្នន័យ!"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("មិនទាន់មានប្រវត្តិនៅឡើយ។"));

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              List<dynamic> sacks = data['sacks_data'] ?? [];
              DateTime date = (data['created_at'] as Timestamp).toDate();
              String formattedDate = DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(date);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.green),
                  // ដូរត្រង់ title ក្នុង ListView.builder នៃទំព័រប្រវត្តិ
                  title: Text(
                    data['note'] ?? "បញ្ជីគ្មានឈ្មោះ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "សរុប: ${data['total_sacks']} បាវ | ${data['total_weight']} គីឡូ",
                    style: TextStyle(color: Colors.green[800]),
                  ),
                  // 🎯 ពេលចុចលើ Card វានឹងពន្លាតបង្ហាញទម្ងន់បាវនីមួយៗឱ្យមើលតែម្ដង
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      color: Colors.grey[50],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ទម្ងន់បាវលម្អិត៖",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: sacks.asMap().entries.map((entry) {
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Text(
                                    "${entry.key + 1}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                label: Text("${entry.value} គីឡូ"),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.green),
                              );
                            }).toList(),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "ទឹកប្រាក់សរុប:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${data['total_price']} ${data['currency']}",
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
