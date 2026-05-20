import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          "ប្រវត្តិលក់ និងភស្តុតាង",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'KHMEROS',
          ),
        ),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ១. ប្រអប់ Search ស្វែងរកតាមឈ្មោះអតិថិជន
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "ស្វែងរកតាមឈ្មោះអតិថិជន...",
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
            ),
          ),

          // ២. បង្ហាញបញ្ជីប្រវត្តិ
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_confirm_history')
                  .where('status', isEqualTo: 'confirmed')
                  .orderBy('confirm_date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("មានបញ្ហា៖ ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("មិនទាន់មានប្រវត្តិលក់ទេ"));
                }

                // Filter តាមឈ្មោះអតិថិជន (ការពារ Null)
                var docs = snapshot.data!.docs.where((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  String name = (data['customer_name'] ?? "ភ្ញៀវមិនស្គាល់")
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("រកមិនឃើញឈ្មោះនេះទេ"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data =
                        docs[index].data()
                            as Map<
                              String,
                              dynamic
                            >; // កែសម្រួលការបង្ហាញថ្ងៃខែឱ្យស្អាត
                    String formattedDate = "មិនមានម៉ោង";
                    if (data['confirm_date'] != null) {
                      formattedDate = DateFormat(
                        'dd-MMM-yyyy HH:mm',
                      ).format((data['confirm_date'] as Timestamp).toDate());
                    }

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo[50],
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.indigo,
                          ),
                        ),
                        title: Text(
                          data['product_name'] ?? "ទំនិញមិនស្គាល់",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "អ្នកទិញ៖ ${data['customer_name'] ?? 'មិនស្គាល់ឈ្មោះ'}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        children: [
                          _buildDetailSection(context, data, formattedDate),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    Map<String, dynamic> data,
    String date,
  ) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person,
            "ឈ្មោះអ្នកទិញ:",
            data['customer_name'] ?? "គ្មានឈ្មោះ",
          ),
          _buildInfoRow(
            Icons.phone,
            "លេខទូរស័ព្ទ:",
            data['customer_phone'] ?? "គ្មានលេខ",
          ),
          _buildInfoRow(
            Icons.store,
            "អ្នកលក់:",
            data['seller_name'] ?? "គ្មានឈ្មោះ",
          ),
          _buildInfoRow(
            Icons.badge,
            "អត្តសញ្ញាណអ្នកលក់:",
            data['seller_id'] ?? "មិនស្គាល់",
          ),
          _buildInfoRow(
            Icons.phone_android,
            "លេខទូរស័ព្ទអ្នកលក់:",
            data['seller_phone'] ?? "គ្មានលេខ",
          ),
          _buildInfoRow(
            Icons.attach_money,
            "តម្លៃសរុប:",
            "${currencyFormat.format(data['amount'] ?? 0)} ៛",
          ),
          _buildInfoRow(Icons.access_time, "ម៉ោងបញ្ជាក់:", date),
          const Divider(height: 30),

          // បង្ហាញរូបភាពភស្តុតាង (បុងបង់ប្រាក់)
          if (data['receipt_image'] != null && data['receipt_image'] != "")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ភស្តុតាងនៃការបង់ប្រាក់៖",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _showFullImage(context, data['receipt_image']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      data['receipt_image'],
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            const Text(
              "មិនមានរូបភាពភស្តុតាងទេ",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // ឱ្យ Icon នៅជួរលើបង្អស់
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 10),

          // ១. កំណត់ទទឹងសម្រាប់ Label (កុំឱ្យ Label វែងពេករុញ Value)
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),

          const SizedBox(width: 10),

          // ២. ប្រើ Expanded ដើម្បីឱ្យ Value ធ្លាក់ជួរស្វ័យប្រវត្តិ (បាត់ Overflow ភ្លាម)
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right, // ឱ្យអត្ថបទនៅកៀនខាងស្តាំ
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              softWrap: true, // ឱ្យធ្លាក់ជួរដោយស្វ័យប្រវត្តិ
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InteractiveViewer(child: Image.network(url)),
        ),
      ),
    );
  }
}
