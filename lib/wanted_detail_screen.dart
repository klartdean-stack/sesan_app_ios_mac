import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';

class WantedDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const WantedDetailScreen({super.key, required this.data});

  @override
  State<WantedDetailScreen> createState() => _WantedDetailScreenState();
}

class _WantedDetailScreenState extends State<WantedDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    // 🎯 ទាញយក List រូបភាពចេញពី Key ថ្មី (imageUrls)
    final List<dynamic> images = d['imageUrls'] ?? [];

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "លម្អិតការប្រកាសទិញ",
            style: TextStyle(fontFamily: 'Siemreap'),
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                String firstImg = images.isNotEmpty
                    ? images[0]
                    : "https://sesan-farm.com";
                Clipboard.setData(ClipboardData(text: firstImg));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ចម្លង Link រូបភាពរួចរាល់!")),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                String firstImg = images.isNotEmpty ? images[0] : "";
                Share.share(
                  "ត្រូវការទិញ: ${d['productName']}\nតម្លៃ: ${d['price']} ${d['currency']}\nមើលរូបភាព: $firstImg",
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
            child: Column(
              children: [
              // 🎯 បង្ហាញរូបភាពជា Slide (PageView) ព្រោះវាជា List
              SizedBox(
              height: 300,
              width: double.infinity,
              child: images.isNotEmpty
                  ? PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                  );
                },
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 50),
              ),
            ),

            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                d['productName'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${d['price']} ${d['currency']}",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 30),
                _infoTile(
                  Icons.shopping_bag,
                  "ចំនួនត្រូវការ",
                  "${d['quantity']} ${d['unit']}",
                ),
                _infoTile(
                  Icons.location_on,"ទីតាំង",
                  d['location'] ?? "មិនបញ្ជាក់",
                ),
                    _infoTile(Icons.phone, "លេខទូរស័ព្ទ", d['phone'] ?? "មិនមាន"),
                    const SizedBox(height: 20),
                    const Text(
                      "ការរៀបរាប់បន្ថែម:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      d['description'] ?? "មិនមានការរៀបរាប់...",
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
            ),
              ],
            ),
        ),
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
        ),
        child: Row(
          children: [
            _bottomActionIcon(Icons.chat, Colors.orange, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    productId: d['id'] ?? '',
                    productName: d['productName'] ?? '',
                    seller_id: d['userId'] ?? '',
                    receiver_id: d['userId'] ?? '',
                  ),
                ),
              );
            }),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse("tel:${d['phone']}");
                  if (await canLaunchUrl(url)) await launchUrl(url);
                },
                icon: const Icon(Icons.phone),
                label: const Text(
                  "តេទៅភ្លាម",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _bottomActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}