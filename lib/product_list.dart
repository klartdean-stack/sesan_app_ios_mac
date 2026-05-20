import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/auction_main_screen.dart';
import 'package:my_app/qr_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_app/wanted_detail_screen.dart';
import 'main.dart';
import 'product_detail.dart';
import 'edit_product.dart';


/// 🎯 Service យក User ID (Firebase Auth ឬ SharedPreferences)
class UserService {
  static String? _cachedUserId;


  static Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;


    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _cachedUserId = firebaseUser.uid;
      return _cachedUserId;
    }


    final prefs = await SharedPreferences.getInstance();
    _cachedUserId =
        prefs.getString('user_uid') ??
            prefs.getString('uid') ??
            prefs.getString('user_id');


    return _cachedUserId;
  }


  static void clearCache() => _cachedUserId = null;
}


// ─────────────────────────────────────────────────────────────
// ProductListScreen
// ─────────────────────────────────────────────────────────────
class ProductListScreen extends StatefulWidget {
  final String category;
  const ProductListScreen({super.key, required this.category});


  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}


class _ProductListScreenState extends State<ProductListScreen> {
  String _currentSearch = "";


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Siemreap',
          ),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _currentSearch = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  // 💡 ដក const ចេញ
                  hintText: 'ស្វែងរកទំនិញក្នុងប្រភេទនេះ...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  // ✅ បន្ថែមប៊ូតុងស្កែននៅខាងស្តាំ
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QrScannerScreen(),
                        ),
                      );
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuctionMainScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  // ✨ ពណ៌មាសដេញ (Gold Gradient) ឱ្យមើលទៅមានតម្លៃ និងទាក់ទាញ
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    // ប្រើ Icon តាមដែលមេផ្ញើមក (Icons.trending_up_rounded)
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.black,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "ចូលដេញថ្លៃ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900, // ដាក់ឱ្យដិតខ្លាំង
                        fontSize: 12,
                        fontFamily: 'Siemreap',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ProductGridView(
        category: widget.category,
        searchQuery: _currentSearch,
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// ProductGridView
// ─────────────────────────────────────────────────────────────
class ProductGridView extends StatefulWidget {
  final String category;
  final String searchQuery;
  final bool isHome;


  const ProductGridView({
    super.key,
    required this.category,
    this.searchQuery = "",
    this.isHome = false,
  });


  @override
  State<ProductGridView> createState() => _ProductGridViewState();
}


class _ProductGridViewState extends State<ProductGridView> {
  final ScrollController _scrollController = ScrollController();
  final int _batchSize = 35; // ✅ ប្ដូរពី 35 → 100


  List<DocumentSnapshot> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  String? _currentUserId;


  @override
  void initState() {
    super.initState();
    _initUserAndFetch();
    if (!widget.isHome) {
      _scrollController.addListener(_onScroll);
    }
  }


  Future<void> _initUserAndFetch() async {
    _currentUserId = await UserService.getUserId();
    // ✅ រង់ចាំ build ចប់ ទើប fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchProducts();
    });
  }


  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchProducts();
    }
  }


  // ── FETCH PRODUCTS ──────────────────────────────────────
  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore || _currentUserId == null)
      return; // 🎯 ថែម _isLoading ត្រង់នេះ


    setState(() => _isLoading = true);
    try {
      if (widget.category == "ទំនិញរបស់ខ្ញុំ") {
        await _fetchMyProducts();
      } else {
        await _fetchByCategory();
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }


    setState(() => _isLoading = false);
  }


  Future<void> _fetchMyProducts() async {
    final futures = await Future.wait([
      FirebaseFirestore.instance
          .collection('products')
          .where('seller_id', isEqualTo: _currentUserId)
          .orderBy('created_at', descending: true)
          .get(),
      FirebaseFirestore.instance
          .collection('wanted_products')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get(),
    ]);


    final combined = <DocumentSnapshot>[];
    combined.addAll(futures[0].docs);
    combined.addAll(futures[1].docs);


    combined.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final timeA = dataA['created_at'] ?? dataA['savedAt'] ?? Timestamp.now();
      final timeB = dataB['created_at'] ?? dataB['savedAt'] ?? Timestamp.now();
      return (timeB as Timestamp).compareTo(timeA as Timestamp);
    });


    if (mounted) {
      setState(() {
        _products.clear();
        _products.addAll(combined);
        _hasMore = false;
      });
    }
  }


  Future<void> _fetchByCategory() async {
    Query query = FirebaseFirestore.instance.collection('products');


    if (widget.category != "ទាំងអស់") {
      query = query.where('category', isEqualTo: widget.category);
    }


    // ✅ ទាញច្រើន ដើម្បីទំហំ filter ក្រោយ
    query = query
        .orderBy('created_at', descending: true)
        .limit(35); // ✅ limit ធំ


    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }


    final snapshot = await query.get();


    if (snapshot.docs.isEmpty) {
      if (mounted) setState(() => _hasMore = false);
      return;
    }


    _lastDoc = snapshot.docs.last;


    if (mounted) {
      setState(() {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();


          // ✅ filter ចេញ auction/exhibition ក្រោយទាញ
          if (status == 'exhibition' || status == 'auction') continue;


          if (!_products.any((e) => e.id == doc.id)) {
            _products.add(doc);
          }
        }
        if (snapshot.docs.length < 35) _hasMore = false;
      });
    }
  }


  // ── BUILD ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['product_name'] ?? data['productName'] ?? '')
          .toString()
          .toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      return query.isEmpty || name.contains(query);
    }).toList();


    if (filtered.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          "មិនមានទំនិញដែលអ្នករកទេ",
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
      );
    }


    // កែសម្រួលផ្នែក GridView.builder ឱ្យរលូនជាងមុន
    return GridView.builder(
      key: const PageStorageKey('productGrid'),
      controller: widget.isHome ? null : _scrollController,
      shrinkWrap: widget.isHome,
      // 🎯 បន្ថែម RepaintBoundary ដើម្បីកុំឱ្យ Widget គូរឡើងវិញផ្ដេសផ្ដាសពេលអូស
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: true,
      physics: widget.isHome
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filtered.length + (_hasMore && !widget.isHome ? 1 : 0),
      itemBuilder: (context, index) {
        if (!widget.isHome && index >= filtered.length) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }
        // 🎯 ប្រើ RepaintBoundary ព័ទ្ធជុំវិញ Card
        return RepaintBoundary(child: _buildProductCard(filtered[index]));
      },
    );
  }


  // ── PRODUCT CARD ────────────────────────────────────────
  Widget _buildProductCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String docId = doc.id;


    final bool isWanted =
        doc.reference.path.contains('wanted_products') ||
            data.containsKey('savedAt');


    // 🎯 កំណត់តម្លៃចាក់សោដំបូង
    bool currentLockStatus = data['is_locked'] ?? false;


    final String name = isWanted
        ? (data['productName'] ?? 'គ្មានឈ្មោះ')
        : (data['product_name'] ?? 'គ្មានឈ្មោះ');
    final String price = (data['price'] ?? '0').toString();
    final String location = (data['location'] ?? 'ភ្នំពេញ').toString();
    final dynamic timestamp =
        data['created_at'] ?? data['savedAt'] ?? data['createdAt'];


    String imageUrl = "";
    final urls = data['imageUrls'] ?? data['image_urls'];
    if (urls is List && urls.isNotEmpty) {
      imageUrl = urls[0].toString();
    } else if (data['imageUrl'] != null) {
      imageUrl = data['imageUrl'].toString();
    }


    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallCard = constraints.maxWidth < 200;


        return GestureDetector(
          onTap: () => _onProductTap(docId, data, isWanted),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼 ផ្នែករូបភាព
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // 🎯 ថែម ២ ជួរនេះដើម្បីឱ្យអូសរលូន (Lag Fix)
                          memCacheHeight: 350,
                          maxWidthDiskCache: 500,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[100]),
                          errorWidget: (context, url, error) =>
                          const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        )
                            : Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),


                    // 📝 ផ្នែកព័ត៌មានអត្ថបទ
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallCard ? 12 : 14,
                              fontFamily: 'Siemreap',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 10,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatTimeAgo(timestamp),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                  fontFamily: 'Siemreap',
                                ),
                              ),
                              const Text(
                                " • ",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                    fontFamily: 'Siemreap',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$price ៛",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (!isWanted)
                                _buildCartButton(data, currentLockStatus)
                              else
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),


                // 🔘 ផ្នែក Switch ស្ទីល iOS (បៃតង=បើក, ប្រផេះ=បិទ) + Snackbars
                if (widget.category == "ទំនិញរបស់ខ្ញុំ")
                  Positioned(
                    top: 8,
                    left: 8,
                    child: StatefulBuilder(
                      builder: (context, setLocalState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // បង្ហាញអក្សរ បើក ឬ បិទ នៅខាងលើ Switch
                            Text(
                              currentLockStatus ? "បើក" : "បិទ",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: currentLockStatus
                                    ? Colors.green
                                    : Colors.grey[600],
                                fontFamily: 'Siemreap',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Transform.scale(
                              scale: 0.75, // ទំហំសមល្មមសម្រាប់ Card
                              child: Switch.adaptive(
                                value: currentLockStatus,
                                // 🎯 បើបើកសោរ (True) ចេញពណ៌បៃតង, បើបិទ (False) ចេញពណ៌ប្រផេះ
                                activeColor: Colors.green,
                                activeTrackColor: Colors.green.withOpacity(0.3),
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey[400],
                                onChanged: (bool newValue) async {
                                  // ១. Update UI ភ្លាមៗ
                                  setLocalState(
                                        () => currentLockStatus = newValue,
                                  );
                                  data['is_locked'] = newValue;


                                  try {
                                    // ២. Update ទៅ Firebase
                                    await FirebaseFirestore.instance
                                        .collection(
                                      isWanted
                                          ? 'wanted_products'
                                          : 'products',
                                    )
                                        .doc(docId)
                                        .update({'is_locked': newValue});


                                    // ៣. បង្ហាញ Snackbar តាមមេចង់បាន
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          newValue
                                              ? "បើកលក់តាមកន្ត្រក់"
                                              : "បិទការលក់តាមកន្ត្រក់",
                                          style: const TextStyle(
                                            fontFamily: 'Siemreap',
                                          ),
                                        ),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: newValue
                                            ? Colors.green
                                            : Colors.grey[700],
                                      ),
                                    );
                                  } catch (e) {
                                    setLocalState(
                                          () => currentLockStatus = !newValue,
                                    );
                                    data['is_locked'] = !newValue;
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                // 🛠 ផ្នែកប៊ូតុង កែប្រែ/លុប (បង្ហាញរហូតក្នុង Screen នេះ មិនបាច់ឆែកលក្ខខណ្ឌនាំភ្លាត់)
                if (widget.category == "ទំនិញរបស់ខ្ញុំ")
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ១. ប៊ូតុង Edit (ពណ៌ខៀវ)
                        if (!isWanted) // បើទំនិញធម្មតា ទើបឱ្យកែ
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProductScreen(
                                    productId: docId,
                                    productData: data,
                                    isWanted: isWanted,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),


                        // ២. ប៊ូតុង Delete (ពណ៌ក្រហម)
                        GestureDetector(
                          onTap: () => _showDeleteConfirm(docId, isWanted),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 3),
                              ],
                            ),
                            child: const Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ── CART BUTTON ─────────────────────────────────────────
  Widget _buildCartButton(Map<String, dynamic> data, bool isLocked) {
    return GestureDetector(
      onTap: isLocked ? null : () => _fastAddToCart(data),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey[200] : Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.add_shopping_cart,
          color: isLocked ? Colors.grey : Colors.green,
          size: 22,
        ),
      ),
    );
  }


  // ── LOCK SWITCH ─────────────────────────────────────────
  Widget _buildLockSwitch(
      String docId,
      Map<String, dynamic> data,
      bool isWanted,
      bool isLocked,
      ) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              size: 14,
              color: isLocked ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 35,
              height: 20,
              child: Switch(
                value: !isLocked,
                onChanged: (value) =>
                    _toggleLock(docId, data, isWanted, isLocked),
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.red[200],
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _toggleLock(
      String docId,
      Map<String, dynamic> data,
      bool isWanted,
      bool currentStatus,
      ) async {
    setState(() {
      data['is_locked'] = !currentStatus;
    });


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !currentStatus ? "🔒 ចាក់សោរទំនិញរួចរាល់" : "🔓 បើកសោរវិញរួចរាល់",
          style: const TextStyle(fontFamily: 'Siemreap'),
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );


    try {
      await FirebaseFirestore.instance
          .collection(isWanted ? 'wanted_products' : 'products')
          .doc(docId)
          .update({'is_locked': !currentStatus});
    } catch (e) {
      setState(() => data['is_locked'] = currentStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ការតភ្ជាប់មានបញ្ហា! សូមព្យាយាមម្តងទៀត")),
      );
    }
  }


  // ── OWNER TOOLS ─────────────────────────────────────────
  Widget _buildOwnerTools(
      String docId,
      Map<String, dynamic> data,
      bool isWanted,
      ) {
    return Positioned(
      top: 8,
      right: 8,
      child: Row(
        children: [
          if (!isWanted)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(
                      productId: docId,
                      productData: data,
                      isWanted: isWanted,
                      currentUserId: _currentUserId,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showDeleteConfirm(docId, isWanted),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }


  void _onProductTap(String docId, Map<String, dynamic> data, bool isWanted) {
    final productWithId = Map<String, dynamic>.from(data);
    productWithId['id'] = docId;
    productWithId['isWanted'] = isWanted;


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => isWanted
            ? WantedDetailScreen(data: productWithId)
            : ProductDetailScreen(product: productWithId),
      ),
    );
  }


  void _showDeleteConfirm(String docId, bool isWanted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("លុបទំនិញ"),
        content: const Text("តើបងពិតជាចង់លុបទំនិញនេះមែនទេ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ទេ"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(isWanted ? 'wanted_products' : 'products')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("លុបទំនិញជោគជ័យ!")));
            },
            child: const Text("លុប", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  // ── ADD TO CART ─────────────────────────────────────────
  Future<void> _fastAddToCart(Map<String, dynamic> product) async {
    if (_currentUserId == null) return;


    final String finalImageUrl =
        product['image_url'] ??
            (product['image_urls'] != null &&
                (product['image_urls'] as List).isNotEmpty
                ? product['image_urls'][0]
                : "");


    try {
      await FirebaseFirestore.instance.collection('carts').add({
        'product_id': product['id'] ?? '',
        'product_name': product['product_name'] ?? 'គ្មានឈ្មោះ',
        'price': product['price'] ?? 0,
        'currency': product['currency'] ?? '៛',
        'image_url': finalImageUrl,
        'quantity': 1,
        'customer_id': _currentUserId,
        'created_at': FieldValue.serverTimestamp(),


        // --- ផ្នែកព័ត៌មានអ្នកលក់ដែលមេបន្ថែម ---
        'seller_id': product['seller_id'] ?? '',
        'seller_name':
        product['seller_name'] ?? 'អាជីវករ សេសាន', // 🎯 ថែមឈ្មោះអ្នកលក់
        'seller_phone': product['seller_phone'] ?? product['phone1'] ?? '',
        'seller_photo': product['seller_photo'] ?? '', // 🎯 ថែមរូបថតអ្នកលក់
      });


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ បន្ថែមទៅកន្ត្រករួចរាល់!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Add to Cart Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ បរាជ័យ: $e")));
      }
    }
  }


  // ── FORMAT TIME AGO (នៅក្នុង class ឥឡូវ) ─────────────────
  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return "មុននេះបន្តិច";


    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return "មុននេះបន្តិច";
    }


    final Duration diff = DateTime.now().difference(date);


    if (diff.inMinutes < 1) return "មុននេះបន្តិច";
    if (diff.inMinutes < 60) return "${diff.inMinutes} នាទីមុន";
    if (diff.inHours < 24) return "${diff.inHours} ម៉ោងមុន";
    if (diff.inDays < 7) return "${diff.inDays} ថ្ងៃមុន";
    return "${date.day}/${date.month}/${date.year}";
  }


  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}



