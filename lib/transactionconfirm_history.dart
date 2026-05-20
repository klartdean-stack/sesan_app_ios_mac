import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionConfirmHistory extends StatelessWidget {
  const TransactionConfirmHistory({super.key});

  @override
  Widget build(BuildContext context) {
    // ចាប់យក ID របស់អ្នកដែលកំពុងបើក App
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // ខ្ញុំដាក់ UID របស់មេចូលឱ្យស្រេចតែម្ដង មិនបាច់កែទៀតទេ
    const String adminUID = "WBdQVvrgEIPBTcgIlumu6bAZGUl2";
    bool isAdmin = (currentUserId == adminUID);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin ? "ប្រវត្តិបាញ់លុយឱ្យអ្នកលក់" : "ប្រវត្តិដកប្រាក់របស់ខ្ញុំ",
          style: const TextStyle(fontFamily: 'KHMEROS', fontSize: 18),
        ),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        // Logic ទាញទិន្នន័យ៖ បើជាមេ Admin គឺឃើញទាំងអស់ បើអ្នកលក់ឃើញតែរបស់ខ្លួនឯង
        stream: isAdmin
            ? FirebaseFirestore.instance
                  .collection('withdraw_requests')
                  .where('status', isEqualTo: 'success')
                  .orderBy('approved_at', descending: true)
                  .snapshots()
            : FirebaseFirestore.instance
                  .collection('withdraw_requests')
                  .where('seller_id', isEqualTo: currentUserId)
                  .where('status', isEqualTo: 'success')
                  .orderBy('approved_at', descending: true)
                  .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("សូមបង្កើត Index ក្នុង Firebase Console ឱ្យវាដើរ..."),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("មិនទាន់មានប្រវត្តិជោគជ័យទេ"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              String dateStr = "មិនមានម៉ោង";
              if (data['approved_at'] != null) {
                dateStr = DateFormat(
                  'dd-MM-yyyy HH:mm',
                ).format((data['approved_at'] as Timestamp).toDate());
              }

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                  title: Text(
                    "ចំនួន៖ ${data['amount']} ៛",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.green,
                    ),
                  ),
                  subtitle: Text(
                    isAdmin
                        ? "អ្នកលក់៖ ${data['account_name']}"
                        : "កាលបរិច្ឆេទ៖ $dateStr",
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          _buildDetailRow(
                            "ឈ្មោះគណនី:",
                            "${data['account_name']}",
                          ),
                          _buildDetailRow(
                            "លេខគណនី:",
                            "${data['account_number']}",
                          ),
                          _buildDetailRow("ម៉ោងអនុម័ត:", dateStr),
                          const SizedBox(height: 15),
                          const Text(
                            "ភស្តុតាងបាញ់លុយ (Admin Receipt)៖",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (data['admin_receipt'] != null)
                            InkWell(
                              onTap: () => _viewFullImage(
                                context,
                                data['admin_receipt'],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  data['admin_receipt'],
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                ),
                              ),
                            )
                          else
                            const Text(
                              "មិនមានរូបភាពភស្តុតាង",
                              style: TextStyle(color: Colors.red, fontSize: 12),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _viewFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) =>
          Dialog(child: InteractiveViewer(child: Image.network(url))),
    );
  }
}
