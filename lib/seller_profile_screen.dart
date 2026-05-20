import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:my_app/edit_shopscreen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'product_detail.dart';
import 'chat_screen.dart';


class SellerProfileScreen extends StatelessWidget {
  final String sellerId;
  final String sellerName;


  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildSellerInfoCard(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ទំនិញដាក់លក់',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('seller_id', isEqualTo: sellerId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = snapshot.hasData
                          ? snapshot.data!.docs.length
                          : 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count ទំនិញ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildProductsGrid(context),
        ],
      ),
    );
  }


  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      floating: false,
      backgroundColor: Colors.green[700],
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        // ✅ Share button
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            Share.share('មើលហាង $sellerName នៅក្នុង Sesan App!');
          },
        ),
        // ✅ Edit button — បង្ហាញតែម្ចាស់ហាង
        FutureBuilder<String>(
          future: _getCurrentUid(),
          builder: (context, snapshot) {
            if (snapshot.data == sellerId) {
              return IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: Icon(Icons.edit, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditShopScreen(),
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildDefaultCover();
            }


            var userData = snapshot.data!.data() as Map<String, dynamic>?;
            String coverUrl = userData?['coverUrl'] ?? '';
            String photoUrl = userData?['photoUrl'] ?? '';
            String name = userData?['name'] ?? sellerName;


            return Stack(
              fit: StackFit.expand,
              children: [
                coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildShimmerCover(),
                  errorWidget: (context, url, error) =>
                      _buildDefaultCover(),
                )
                    : _buildDefaultCover(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Hero(
                        tag: 'seller_avatar_$sellerId',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: photoUrl.isNotEmpty
                                ? CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 40),
                              ),
                              errorWidget: (context, url, error) =>
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                    ),
                                  ),
                            )
                                : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.person, size: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('products')
                                  .where('seller_id', isEqualTo: sellerId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                int count = snapshot.hasData
                                    ? snapshot.data!.docs.length
                                    : 0;
                                return Text(
                                  '$count ទំនិញ • កំពុងលក់',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  // ✅ ទាញ uid ពី SharedPreferences
  Future<String> _getCurrentUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_uid') ?? '';
  }


  Widget _buildSellerInfoCard(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox.shrink();
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        String followers = (userData?['followers_count'] ?? 0).toString();
        String rating = (userData?['rating'] ?? 5.0).toString();
        String joinDate = userData?['join_date'] ?? 'ថ្មីៗនេះ';


        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(Icons.star, rating, 'រង្វាស់'),
                  _buildDivider(),
                  _buildStatItem(Icons.people, followers, 'អ្នកតាមដាន'),
                  _buildDivider(),
                  _buildStatItem(Icons.access_time, joinDate, 'ថ្ងៃចូលរួម'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              seller_id: sellerId,
                              receiver_id: sellerId,
                              productName: 'ហាងរបស់ $sellerName',
                              productId: 'general',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('ឆាតឥឡូវនេះ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.person_add, color: Colors.green[700]),
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[700], size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }


  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[200]);
  }


  Widget _buildProductsGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('seller_id', isEqualTo: sellerId)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[300], size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'មិនអាចផ្ទុកទំនិញបាន',
                      style: TextStyle(color: Colors.red[300], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }


        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: _buildShimmerGrid());
        }


        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey[300],
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'មិនទាន់មានទំនិញលក់នៅឡើយ',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }


        var products = snapshot.data!.docs;


        return SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              var data = products[index].data() as Map<String, dynamic>;


              // ✅ រូបភាព
              String imageUrl = '';
              if (data['image_urls'] != null &&
                  (data['image_urls'] as List).isNotEmpty) {
                imageUrl = data['image_urls'][0];
              } else if (data['image_url'] != null) {
                imageUrl = data['image_url'];
              }


              String productName = data['product_name'] ?? 'គ្មានឈ្មោះ';


              // ✅ Format តម្លៃ
              String priceString = data['price']?.toString() ?? '0';
              double priceValue =
                  double.tryParse(priceString.replaceAll(',', '')) ?? 0.0;
              String formattedPrice = NumberFormat('#,###').format(priceValue);
              String currency = data['currency']?.toString() ?? '៛';


              bool isAvailable = data['is_available'] ?? true;


              return GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('last_product_id', products[index].id);
                  await prefs.setString('current_seller_id', sellerId);


                  var productData =
                  products[index].data() as Map<String, dynamic>;
                  productData['id'] = products[index].id;


                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(product: productData),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ រូបភាព
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    Container(
                                      color: Colors.grey[100],
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[400],
                                        size: 40,
                                      ),
                                    ),
                              )
                                  : Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                              ),
                            ),
                            if (!isAvailable)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ដាច់ស្តុក',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if (data['discount'] != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-${data['discount']}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),


                      // ✅ ព័ត៌មាន
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                              Row(
                                children: [
                                  // ✅ formattedPrice ត្រឹមត្រូវ
                                  Text(
                                    '$formattedPrice $currency',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (data['likes'] != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          color: Colors.red[300],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${data['likes']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: products.length),
          ),
        );
      },
    );
  }


  Widget _buildDefaultCover() {
    return Container(
      color: Colors.green[700],
      child: Center(
        child: Icon(
          Icons.store,
          size: 80,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }


  Widget _buildShimmerCover() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }


  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }
}



