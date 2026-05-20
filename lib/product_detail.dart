import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart'
    show Get, ExtensionSnackbar, GetNavigation, ExtensionDialog, SnackPosition;
import 'package:intl/intl.dart';
import 'package:my_app/comment_section.dart';
import 'package:my_app/seller_profile_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'video_player_screen.dart';
import 'related_products_widget.dart';
import 'chat_screen.dart';
import 'cart_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';


// ✅ កែពី StatelessWidget ទៅជា StatefulWidget
class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});


  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}


class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentPage = 0; // 🎯 បន្ថែមសម្រាប់រាប់លេខរូបភាព
  int _tempQty = 1; // 🎯 ប្តូរពី static មកជា variable ធម្មតាវិញ
  bool isSaved = false; // ស្ថានភាពដំបូង
  String? _currentUserId;
  int _quantity = 1;


  @override
  void initState() {
    super.initState();
    _loadUid();
  }


  // ── Screenshot Controller ────────────────────────────────────────
  final ScreenshotController _screenshotController = ScreenshotController();


  // ── ២. Function បង្កើត Watermark (ជាប់ Logo និង QR ច្បាស់) ──────────────────
  Widget _buildWatermarkImage(
      String imageUrl,
      String sellerName,
      String sellerPhone,
      String productId,
      ) {
    return Container(
      width: 500, // កំណត់ទំហំឱ្យច្បាស់ដើម្បីកុំឱ្យបាត់ Logo
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // រូបភាពទំនិញ
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: 500,
            height: 500,
          ),
          // ផ្នែកខាងក្រោម (Watermark)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                // QR Code
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: // ✅ កូដថ្មី (ត្រូវទិសសម្រាប់ Sesan App)
                  QrImageView(
                    data: "product_id_${productId}",
                    size: 80.0,
                  ),
                ),
                const SizedBox(width: 16),
                // ព័ត៌មានអ្នកលក់
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "រក្សាសិទ្ធិដោយ៖ $sellerName",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                          fontFamily: 'Siemreap',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ទំនាក់ទំនង៖ $sellerPhone",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontFamily: 'Siemreap',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "ស្កេនដើម្បីមើលក្នុង Sesan App",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Siemreap',
                        ),
                      ),
                    ],
                  ),
                ),
                // Logo Sesan (ប្រើ Image.asset ផ្ទាល់ដើម្បីឱ្យជាប់រហូត)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/sesan_icon.jpg',
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _processWatermarkAction(
      String imageUrl, {
        bool isShare = false,
      }) async {
    try {
      // បង្ហាញ Loading
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        barrierDismissible: false,
      );


      // 📸 ថត Screenshot (ប្រើ delay បន្តិចដើម្បីឱ្យ Logo និងរូប Load ទាន់)
      final image = await _screenshotController.captureFromWidget(
        _buildWatermarkImage(
          imageUrl,
          widget.product['seller_name'] ?? 'អាជីវករ សេសាន',
          widget.product['phone1'] ?? '088xxxxxxx',
          widget.product['id'] ?? '',
        ),
        delay: const Duration(milliseconds: 800),
      );


      Get.back(); // បិទ Loading


      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/sesan_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(image);


      if (isShare) {
        await Share.shareXFiles([XFile(file.path)], text: 'Sesan App');
      } else {
        await Gal.putImage(file.path);
        Get.snackbar(
          "ជោគជ័យ!",
          "បានរក្សាទុកក្នុង Gallery រួចរាល់! ✅",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(15),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      }
    } catch (e) {
      Get.back();
      debugPrint("Error: $e");
    }
  }


  // ── Save Product with Watermark ──────────────────────────────────
  Future<void> _saveProductWithWatermark() async {
    try {
      // ១. ទាញរូបភាពទុកមុន (បាត់ Error displayImages)
      List<String> images = [];
      if (widget.product['image_urls'] != null) {
        images = List<String>.from(widget.product['image_urls']);
      } else if (widget.product['image_url'] != null) {
        images = [widget.product['image_url']];
      }
      if (images.isEmpty) return;


      // ២. បង្ហាញ Loading តូចមួយ (មិនឱ្យជាន់ UI របស់ Watermark)
      Get.rawSnackbar(
        message: "កំពុងរៀបចំរូបភាព...",
        showProgressIndicator: true,
        duration: const Duration(seconds: 2),
      );


      // ៣. ថតរូប Screenshot (បញ្ជូនទិន្នន័យ ID ឱ្យគ្រប់ដើម្បីបាត់ Error positional args)
      final image = await _screenshotController.captureFromWidget(
        _buildWatermarkImage(
          images[0], // រូបភាពទី១
          widget.product['seller_name'] ?? 'អាជីវករ​ សេសាន', // ឈ្មោះអ្នកលក់
          widget.product['phone1'] ?? '088xxxxxxx', // លេខទូរស័ព្ទ
          widget.product['id'] ?? '', // ID ផលិតផល
        ),
        delay: const Duration(milliseconds: 500),
      );


      // ៤. រក្សាទុក និង Share
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/sesan_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(image);


      // ✅ Save ចូល Gallery (ដោះស្រាយបញ្ហា Save អត់ចូល)
      await Gal.putImage(file.path);
      // ✅ បើកផ្ទាំង Share
      await Share.shareXFiles([XFile(file.path)], text: 'Sesan App');
    } catch (e) {
      debugPrint("Error: $e");
      // _showSnack('❌ កំហុស: $e', Colors.red);
      // 🎯 កូដសម្រាប់បង្ហាញសារ "បានរក្សាទុក" ឱ្យលោតពីលើចុះមក
      Get.snackbar(
        "ជោគជ័យ!", // ចំណងជើង
        "បានរក្សាទុកក្នុង Gallery រួចរាល់! ✅", // សារបង្ហាញ
        snackPosition: SnackPosition.TOP, // ឱ្យលោតពីខាងលើ
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        borderRadius: 15,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    }
  }


  // ── ៤. ប៊ូតុងជម្រើសពេលចុច Share ក្នុងអេក្រង់ដើម ───────────────────────────────
  void _showSaveOption(BuildContext context) {
    // ទាញយករូបទី១ ជា default
    String firstImage = "";
    if (widget.product['image_urls'] != null &&
        widget.product['image_urls'].isNotEmpty) {
      firstImage = widget.product['image_urls'][0];
    } else {
      firstImage = widget.product['image_url'] ?? "";
    }


    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "ជម្រើសរូបភាពទំនិញ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Siemreap',
                  ),
                ),
                const SizedBox(height: 20),
                _buildOptionTile(
                  icon: Icons.share,
                  color: Colors.blue,
                  title: "ចែករំលែក (មាន Watermark)",
                  subtitle: "ផ្ញើទៅកាន់ FB, Telegram ជាមួយ QR Code",
                  onTap: () {
                    Navigator.pop(context);
                    _processWatermarkAction(firstImage, isShare: true);
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  icon: Icons.download,
                  color: Colors.green,
                  title: "រក្សាទុក (ជាប់ Watermark)",
                  subtitle: "រក្សាទុកក្នុង Gallery សម្រាប់ប្រើប្រាស់",
                  onTap: () {
                    Navigator.pop(context);
                    _processWatermarkAction(firstImage, isShare: false);
                  },
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // ── ៥. ប៊ូតុងក្នុងអេក្រង់មើលរូបភាពធំ (Viewer) ឱ្យដើរតាម Index ──────────────────
  void _openImageViewer(
      BuildContext context,
      List<String> urls,
      int initialIndex,
      ) {
    int currentIndex = initialIndex;


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () => _processWatermarkAction(
                    urls[currentIndex],
                    isShare: false,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () => _processWatermarkAction(
                    urls[currentIndex],
                    isShare: true,
                  ),
                ),
              ],
            ),
            body: PhotoViewGallery.builder(
              itemCount: urls.length,
              pageController: PageController(initialPage: initialIndex),
              onPageChanged: (index) => setState(() => currentIndex = index),
              builder: (context, index) => PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(urls[index]),
                minScale: PhotoViewComputedScale.contained,
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ── Build Option Tile ────────────────────────────────────────────
  Widget _buildOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Siemreap',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
          fontFamily: 'Siemreap',
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }


  // ── Share Original Image ─────────────────────────────────────────
  Future<void> _shareOriginalImage() async {
    try {
      List<String> images = [];
      if (widget.product['image_urls'] != null &&
          widget.product['image_urls'] is List) {
        images = List<String>.from(widget.product['image_urls']);
      } else if (widget.product['image_url'] != null) {
        images = [widget.product['image_url']];
      }


      if (images.isEmpty) return;


      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );


      // Download image
      final response = await Dio().get(
        images[0],
        options: Options(responseType: ResponseType.bytes),
      );


      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/sesan_original_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(response.data);


      Get.back();


      // Share
      await Share.shareXFiles([
        XFile(file.path),
      ], text: '${widget.product['product_name'] ?? 'Sesan Product'}');
    } catch (e) {
      Get.back();
      _showSnack('❌ កំហុស: $e', Colors.red);
    }
  }


  // ── Load User ID ─────────────────────────────────────────────────
  Future<void> _loadUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _currentUserId = prefs.getString('user_uid'));
      }
    } catch (e) {
      debugPrint("Error loading UID: $e");
    }
  }


  // ── Submit Rating ────────────────────────────────────────────────
  Future<void> _submitRating(double rating) async {
    try {
      if (rating <= 0) {
        _showSnack('សូមជ្រើសរើសពិន្ទុ', Colors.orange);
        return;
      }


      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product['id']);


      await productRef.update({
        'avgRating': rating,
        'totalReviews': FieldValue.increment(1),
        'lastRatedAt': FieldValue.serverTimestamp(),
      });


      _showSnack('សូមអរគុណសម្រាប់ការផ្ដល់ពិន្ទុ! ✅', Colors.green);
    } catch (e) {
      debugPrint("Error submitting rating: $e");
      _showSnack('❌ ផ្ដល់ពិន្ទុមិនបានជោគជ័យ', Colors.red);
    }
  }


  // ── Share Current Image from Viewer ──────────────────────────────
  Future<void> _shareCurrentImage(String url) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );


      final response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );


      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/sesan_viewer_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(response.data);


      Get.back();


      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Sesan Store - មើលផលិតផលនេះក្នុង App');
    } catch (e) {
      Get.back();
      _showSnack('❌ កំហុស: $e', Colors.red);
    }
  }


  // ── Show Snack Bar ───────────────────────────────────────────────
  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Siemreap')),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    List<String> displayImages = [];
    if (widget.product['image_urls'] != null &&
        widget.product['image_urls'] is List) {
      displayImages = List<String>.from(widget.product['image_urls']);
    } else if (widget.product['image_url'] != null &&
        widget.product['image_url'] != "") {
      displayImages = [widget.product['image_url']];
    }


    final NumberFormat currencyFormat = NumberFormat("#,###", "en_US");


    for (var url in displayImages) {
      precacheImage(CachedNetworkImageProvider(url), context);
    }


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ), // ប្រើ arrow_back_ios មើលទៅ Premium ជាង
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.product['product_name'] ?? 'លម្អិតទំនិញ',
          style: const TextStyle(color: Colors.white), // ✅ បន្ថែម
        ),
        backgroundColor: Colors.blue,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookmarks')
            // ❌ ចាស់
                .where(
              'userId',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid,
            )
            // ✅ ថ្មី — ប្រើ _currentUserId ពី initState
                .where('userId', isEqualTo: _currentUserId)
            // កែពី widget.productId មកជា widget.product['id']
                .where('productId', isEqualTo: widget.product['id'])
                .snapshots(),
            builder: (context, snapshot) {
              bool alreadySaved =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;


              return IconButton(
                icon: Icon(
                  alreadySaved ? Icons.bookmark : Icons.bookmark_border,
                  color: alreadySaved ? Colors.yellowAccent : Colors.white,
                  size: 28,
                ),
                onPressed: () => _toggleSave(alreadySaved, context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              // 🎯 ប្រើ Link រូបភាពដំបូងរបស់ទំនិញដើម្បី Copy
              String shareLink = displayImages.isNotEmpty
                  ? displayImages[0]
                  : "https://sesan-store.web.app";
              Clipboard.setData(ClipboardData(text: shareLink));


              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "ចម្លង Link រួចរាល់!",
                    style: TextStyle(fontFamily: 'Siemreap'),
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 🎯 កែពី $productName ទៅជា ${widget.product['product_name']} វិញដើម្បីបាត់ក្រហម
              Share.share(
                'មើលទំនិញនេះក្នុង Sesan App៖ ${widget.product['product_name'] ?? 'ទំនិញ'} \nតម្លៃ៖ ${widget.product['price'] ?? '0'} \$ \nLink: ${displayImages.isNotEmpty ? displayImages[0] : ""}',
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ), // ឃាត់វាកុំឱ្យរីកហួសពី ១០០០px
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ១. រូបភាពស្លាយ
                // ១. រូបភាពស្លាយ (Square 1:1)
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1 / 1, // រាងការ៉េស្អាត
                      child: PageView.builder(
                        itemCount: displayImages.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            // 🎯 ១. ចុចសង្កត់ (Long Press) ដើម្បីបង្ហាញជម្រើស Save
                            onLongPress: () {
                              _showSaveOption(context);
                            },
                            // 🎯 ២. ចុចធម្មតា (Tap) ដើម្បីមើលរូបភាពធំ
                            onTap: () {
                              if (displayImages.isNotEmpty) {
                                _openImageViewer(context, displayImages, index);
                              }
                            },
                            child: CachedNetworkImage(
                              imageUrl: displayImages[index],
                              fit: BoxFit.cover, // ឱ្យវាពេញការ៉េស្អាត
                              maxWidthDiskCache: 1000,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // លេខរាប់រូបភាព
                    if (displayImages.length > 1)
                      Positioned(
                        bottom: 15,
                        right: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_currentPage + 1} / ${displayImages.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // ... កូដផ្នែកខាងក្រោមរបស់មេ
                // ... កូដផ្នែកខាងក្រោមរបស់មេ


                // ២. វីដេអូ
                if (widget.product['video_url'] != null &&
                    widget.product['video_url'] != "")
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(
                            videoUrl: widget.product['video_url'],
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "មើលវីដេអូបង្ហាញទំនិញ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),


                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.product['price'] ?? '0'} ${widget.product['currency'] ?? '៛'}",
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.product['product_name'] ?? 'គ្មានឈ្មោះ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),


                      RatingBar.builder(
                        initialRating: (widget.product['avgRating'] ?? 0.0)
                            .toDouble(), // ✅ កែត្រង់នេះ
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 25,
                        itemPadding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                        ),
                        itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (rating) {
                          _submitRating(rating);
                          setState(() {
                            // 🎯 Update តម្លៃក្នុង Local Map ភ្លាម ដើម្បីឱ្យ UI ប្តូរតាម
                            widget.product['avgRating'] = rating;
                          });
                        },
                      ),


                      const Divider(
                        height: 30,
                      ), // ៤. ចំនួនកម្ម៉ង់ និង តម្លៃសរុប
                      const Text(
                        "ជ្រើសរើសចំនួន៖",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StatefulBuilder(
                        builder: (context, setState) {
                          double unitPrice =
                              double.tryParse(
                                widget.product['price'].toString().replaceAll(
                                  ',',
                                  '',
                                ),
                              ) ??
                                  0;
                          double totalPrice = unitPrice * _tempQty;


                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _qtyActionBtn(Icons.remove, () {
                                    if (_tempQty > 1)
                                      setState(() => _tempQty--);
                                  }),
                                  Container(
                                    width: 100,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        contentPadding:
                                        const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      controller:
                                      TextEditingController(
                                        text: "$_tempQty",
                                      )
                                        ..selection =
                                        TextSelection.collapsed(
                                          offset: "$_tempQty".length,
                                        ),
                                      onChanged: (value) {
                                        int? val = int.tryParse(value);
                                        if (val != null && val > 0)
                                          setState(() => _tempQty = val);
                                      },
                                    ),
                                  ),
                                  _qtyActionBtn(
                                    Icons.add,
                                        () => setState(() => _tempQty++),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "ធាតុ",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "តម្លៃសរុប៖",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "${currencyFormat.format(totalPrice)} ${widget.product['currency'] ?? '៛'}",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),


                      const Divider(height: 30),
                      const Text(
                        "ការពិពណ៌នា៖",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.product['description'] ?? 'មិនមានការពិពណ៌នា...',
                        style: const TextStyle(fontSize: 16),
                      ),


                      // --- ផ្នែកព័ត៌មានអ្នកលក់ (Update ថ្មី អាចចុចចូលមើល Profile បាន) ---
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.storefront,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "ព័ត៌មានអ្នកលក់",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                // 🎯 ប៊ូតុង "ចូលមើលហាង"
                                TextButton.icon(
                                  onPressed: () {
                                    // ហៅទៅកាន់អេក្រង់ SellerProfileScreen ដែលមេបានបង្កើត
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SellerProfileScreen(
                                              sellerId:
                                              widget.product['seller_id'] ??
                                                  '',
                                              sellerName:
                                              widget
                                                  .product['seller_name'] ??
                                                  'អ្នកលក់',
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                  ),
                                  label: const Text("មើលហាង"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            // 🎯 ចុចលើ Profile ក៏អាចចូលទៅមើលបានដែរ
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SellerProfileScreen(
                                      sellerId:
                                      widget.product['seller_id'] ?? '',
                                      sellerName:
                                      widget.product['seller_name'] ??
                                          'អ្នកលក់',
                                    ),
                                  ),
                                );
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.green.shade100,
                                  backgroundImage:
                                  (widget.product['seller_photo'] != null &&
                                      widget.product['seller_photo'] != '')
                                      ? NetworkImage(
                                    widget.product['seller_photo'],
                                  )
                                      : null,
                                  child:
                                  (widget.product['seller_photo'] == null ||
                                      widget.product['seller_photo'] == '')
                                      ? const Icon(
                                    Icons.person,
                                    color: Colors.green,
                                    size: 30,
                                  )
                                      : null,
                                ),
                                title: Text(
                                  widget.product['seller_name'] ??
                                      'មិនមានឈ្មោះ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  widget.product['updated_at'] != null
                                      ? "ផុសនៅ៖ ${DateFormat('dd-MM-yyyy HH:mm').format((widget.product['updated_at'] as Timestamp).toDate())}"
                                      : "ម្ចាស់ចំការ / អ្នកលក់",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            // ... កូដផ្នែកលេខទូរស័ព្ទ និងទីតាំងរបស់មេទុកដដែល
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.phone,
                                color: Colors.orange,
                              ),
                              title: Text(
                                widget.product['phone1'] ?? 'អត់មានលេខ',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  final url = Uri.parse(
                                    "tel:${widget.product['phone1']}",
                                  );
                                  if (await canLaunchUrl(url))
                                    await launchUrl(url);
                                },
                              ),
                            ),
                            if (widget.product['phone2'] != null &&
                                widget.product['phone2'].toString().isNotEmpty)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.phone_android,
                                  color: Colors.orange,
                                ),
                                title: Text(
                                  widget.product['phone2'].toString(),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.call,
                                    color: Colors.green,
                                  ),
                                  onPressed: () async {
                                    final url = Uri.parse(
                                      "tel:${widget.product['phone2']}",
                                    );
                                    if (await canLaunchUrl(url))
                                      await launchUrl(url);
                                  },
                                ),
                              ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                              ),
                              title: Text(
                                widget.product['location'] ?? 'មិនមានទីតាំង',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 🎯 ដាក់ចូលក្នុងជួរ 598 (ចន្លោះ ListTile ទីតាំង និង RelatedProducts)
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "មតិយោបល់",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),


                      // ហៅ Widget Comment មកបង្ហាញតែ ១ ដូចដែលមេចង់បាន
                      // កុំឱ្យវាហៅ CommentSection បើអត់មាន ID ពិតប្រាកដ
                      if (widget.product['id'] != null &&
                          widget.product['id'].toString().isNotEmpty)
                        CommentSection(
                          productId: widget.product['id'],
                          sellerId: widget.product['seller_id'] ?? '',
                          currentUserId: _currentUserId, // ✅ បន្ថែមអង្គនេះ
                        )
                      else
                        const Center(child: Text("មិនមានទិន្នន័យផលិតផល")),
                      const SizedBox(height: 30),
                      // ៦. Related Products
                      RelatedProductsWidget(
                        category: widget.product['category'] ?? '',
                        currentProductId: widget.product['id'] ?? '',
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),


      // ៧. Bottom Bar
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
        ),
        child: Row(
          children: [
            _actionIcon(Icons.chat, Colors.orange, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    productId: widget.product['id'] ?? '',
                    productName: widget.product['product_name'] ?? '',
                    seller_id: widget.product['seller_id'] ?? '',
                    receiver_id: '',
                  ),
                ),
              );
            }),
            const SizedBox(width: 15),


            // 🎯 ឆែកមើលស្ថានភាព Lock
            // បើជាប់ Lock ឱ្យប៊ូតុងទៅជាពណ៌ប្រផេះ ហើយចុចលែងកើត
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.product['is_locked'] == true
                      ? Colors.grey
                      : Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                ),
                onPressed: widget.product['is_locked'] == true
                    ? null
                    : () => _addToCart(widget.product),
                child: const Text(
                  "ដាក់កន្ត្រក់",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.product['is_locked'] == true
                      ? Colors.grey[400]
                      : Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                ),
                onPressed: widget.product['is_locked'] == true
                    ? null
                    : () async {
                  await _addToCart(widget.product);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  }
                },
                child: const Text(
                  "ទិញឥឡូវ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _toggleSave(bool alreadySaved, BuildContext context) async {
    // 🎯 ១. ទៅទាញ UID ពីបង្គោល SharedPreferences ដែលមេបានបោះទុក
    final prefs = await SharedPreferences.getInstance();
    final String? savedUid = prefs.getString(
      'user_uid',
    ); // ឆែកមើល Key មេប្រើ user_uid ឬ UID


    // 🎯 ២. ឆែកមើលថាបើគ្មាន UID ក្នុង SharedPreferences ទេ ទើបឱ្យ Login
    if (savedUid == null || savedUid.isEmpty) {
      Get.snackbar("ចូលប្រើប្រាស់", "សូមមេ Login សិន ទើបអាច Save បាន!");
      return;
    }


    final bookmarkRef = FirebaseFirestore.instance.collection('bookmarks');


    if (alreadySaved) {
      // 🎯 ៣. ពេលលុបចេញវិញ ប្រើ savedUid ពី SharedPreferences មកឆែក
      var docs = await bookmarkRef
          .where('userId', isEqualTo: savedUid)
          .where('productId', isEqualTo: widget.product['id'])
          .get();
      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("បានលុបចេញពីបញ្ជីរក្សាទុក")));
    } else {
      // 🎯 ៤. ពេលបន្ថែមចូល ប្រើ savedUid ពី SharedPreferences ជាអ្នកសម្គាល់ម្ចាស់
      await bookmarkRef.add({
        'userId': savedUid,
        'productId': widget.product['id'],
        'productName': widget.product['product_name'] ?? 'គ្មានឈ្មោះ',
        'price': widget.product['price'] ?? '0',
        'imageUrl': widget.product['image_urls'] ?? '',
        'savedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("រក្សាទុកជោគជ័យ! ✅")));
    }
  }


  Widget _qtyActionBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue, size: 20),
      ),
    );
  }


  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
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


  // ២. កូដ addToCart ដែលកែសម្រួលរួច
  Future<void> _addToCart(Map<String, dynamic> product) async {
    final String finalImageUrl =
        product['image_url'] ??
            (product['image_urls'] != null &&
                (product['image_urls'] as List).isNotEmpty
                ? product['image_urls'][0]
                : "");
    // លុប context ចេញពីក្នុងនេះ
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_uid');
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("សូមចូលប្រើប្រាស់កម្មវិធីសិន!")),
        );
        return;
      }


      await FirebaseFirestore.instance.collection('carts').add({
        'customer_id': userId,
        // កែត្រង់នេះ៖ បើ .id ក្រហម ប្រើ ['id'] ឬ ['product_id'] ជំនួស
        'product_id': widget.product['id'] ?? '',
        'product_name': widget.product['product_name'] ?? 'គ្មានឈ្មោះ',
        'price': widget.product['price'] ?? 0,
        'image_url': finalImageUrl,
        'quantity': _quantity,
        'created_at': FieldValue.serverTimestamp(),
        'seller_id': widget.product['seller_id'] ?? 'UNKNOWN_ID',
        'seller_name': widget.product['seller_name'] ?? 'អាជីវករ សេសាន',
        'seller_phone': widget.product['seller_phone'] ?? '',
        'seller_photo': widget.product['seller_photo'] ?? '',
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
      debugPrint("Error: $e");
    }
  }
}



