import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail.dart'; // ដើម្បីឱ្យវាស្គាល់ទំព័រ Detail ពេលចុចទៅ

class RelatedProductsWidget extends StatelessWidget {
  final String category;
  final String currentProductId;

  const RelatedProductsWidget({
    super.key,
    required this.category,
    required this.currentProductId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            "ទំនិញស្រដៀងគ្នា",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('category', isEqualTo: category)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            // ចម្រោះមិនយកទំនិញដែលកំពុងមើលស្រាប់
            var relatedItems = snapshot.data!.docs
                .where((doc) => doc.id != currentProductId)
                .toList();

            if (relatedItems.isEmpty) return const SizedBox();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: relatedItems.length,
              itemBuilder: (context, index) {
                // ✅ ថ្មី
                var item = relatedItems[index].data() as Map<String, dynamic>;
                item['id'] = relatedItems[index].id;
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(product: item),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                  // ១. ថែមអក្សរ s ឱ្យទៅជា image_urls
                                  // ២. ថែម [0] ដើម្បីទាញយករូបទី១ ចេញពីក្នុង Array (បញ្ជីរូបភាព)
                                  (item['image_urls'] != null &&
                                          (item['image_urls'] as List)
                                              .isNotEmpty)
                                      ? item['image_urls'][0]
                                      : 'https://via.placeholder.com/150',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            item['product_name'] ?? 'គ្មានឈ្មោះ',
                            maxLines: 1, // បន្ថែមដើម្បីកុំឱ្យធ្លាក់ជួរវែងពេក
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            // កែសម្រួល Syntax ឱ្យត្រឹមត្រូវ៖ លុបសញ្ញា } ដែលលើសចេញ
                            "${item['price'] ?? '0'} ${item['currency'] ?? '\$'}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
