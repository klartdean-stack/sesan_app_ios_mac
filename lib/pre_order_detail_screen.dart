import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


// 👉 ត្រូវប្រាកដថា file ឈ្មោះ chat_screen.dart មានពិតប្រាកដក្នុង Project
import 'chat_screen.dart';


class PreOrderDetailScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> data;


  const PreOrderDetailScreen({
    super.key,
    required this.documentId,
    required this.data,
  });


  @override
  State<PreOrderDetailScreen> createState() => _PreOrderDetailScreenState();
}


class _PreOrderDetailScreenState extends State<PreOrderDetailScreen> {
  String? currentUid;
  final formatter = NumberFormat('#,###');
  int _currentImageIndex = 0;


  @override
  void initState() {
    super.initState();
    _loadUser();
  }


  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUid = prefs.getString('user_uid');
    if (mounted) setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final ownerId = widget.data['owner_id'] ?? '';
    final isOwner = currentUid == ownerId;
    List<dynamic> images =
        widget.data['images'] ?? widget.data['image_urls'] ?? [];


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "ព័ត៌មានលម្អិត",
          style: TextStyle(fontFamily: 'Siemreap', fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImageGallery(images),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitlePriceSection(),
                  const SizedBox(height: 25),
                  const Text(
                    "ម្ចាស់ការប្រកាស",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Siemreap',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOwnerCard(ownerId),
                  const SizedBox(height: 25),
                  _buildProductDetails(),
                  const SizedBox(height: 120), // ទុកចន្លោះសម្រាប់ Bottom Bar
                ],
              ),
            ),
          ],
        ),
      ),
      // ប៊ូតុង Call, Chat និង Delete នៅខាងក្រោម
      bottomNavigationBar: _buildBottomBar(isOwner),
    );
  }


  // --- ប៊ូតុងខាងក្រោម (រៀបតាមការចង់បានរបស់មេ) ---
  Widget _buildBottomBar(bool isOwner) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ១. ប៊ូតុង Call (បង្ហាញរហូត)
          _buildActionButton(
            icon: Icons.phone_forwarded,
            color: Colors.green,
            onTap: () async {
              final phone = widget.data['phone'] ?? '';
              if (phone.isNotEmpty) await launchUrl(Uri.parse("tel:$phone"));
            },
          ),
          const SizedBox(width: 12),


          // ២. ប៊ូតុង Chat (បង្ហាញរហូត)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _goToChat,
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              label: const Text(
                "ផ្ញើសារឥឡូវនេះ",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Siemreap',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
            ),
          ),


          // ៣. ប៊ូតុងលុប (បង្ហាញតែចំពោះម្ចាស់ការប្រកាស)
          if (isOwner) ...[
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.delete_outline,
              color: Colors.red,
              onTap: () => _confirmDelete(),
            ),
          ],
        ],
      ),
    );
  }


  // ជំនួយការបង្កើតប៊ូតុងតូចៗ (Call / Delete)
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }


  // --- ផ្នែកបង្ហាញរូបភាព ---
  Widget _buildImageGallery(List<dynamic> images) {
    return Stack(
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: images.isNotEmpty
              ? PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (_, i) =>
                Image.network(images[i], fit: BoxFit.cover),
          )
              : Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image, size: 80),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${_currentImageIndex + 1}/${images.length}",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }


  // --- ផ្នែកម្ចាស់ការប្រកាស ---
  Widget _buildOwnerCard(String ownerId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(ownerId).get(),
      builder: (_, snapshot) {
        if (!snapshot.hasData)
          return const SizedBox(height: 50, child: LinearProgressIndicator());
        var user = snapshot.data!.data() as Map<String, dynamic>;
        String name = user['name'] ?? 'ម្ចាស់ការប្រកាស';
        String image = user['profile_image'] ?? '';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                child: image.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 15),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              const Icon(Icons.verified, color: Colors.blue, size: 18),
            ],
          ),
        );
      },
    );
  }


  // --- មុខងារ Chat ---
  void _goToChat() {
    if (currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("សូមចូលប្រើប្រាស់កម្មវិធីជាមុនសិន")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          productId: widget.documentId,
          productName: widget.data['product_name'] ?? 'ផលិតផល',
          seller_id: widget.data['owner_id'],
          receiver_id: widget.data['owner_id'],
        ),
      ),
    );
  }


  // --- មុខងារលុប ---
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "លុបការប្រកាស?",
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        content: const Text("តើអ្នកពិតជាចង់លុបការប្រកាសនេះមែនទេ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ទេ"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('pre_orders')
                  .doc(widget.documentId)
                  .delete();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("លុប", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  // --- ផ្នែកអត្ថបទផ្សេងៗ ---
  Widget _buildTitlePriceSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.data['product_name'] ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          "${formatter.format(widget.data['price'] ?? 0)} ៛",
          style: const TextStyle(
            fontSize: 20,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _buildProductDetails() {
    return Column(
      children: [
        // ១. បង្ហាញថ្ងៃប្រមូលផល
        _row(
          Icons.event_available,
          "ថ្ងៃប្រមូលផល",
          _formatDate(widget.data['harvest_date']),
        ),
        const Divider(),


        // ២. បង្ហាញលេខទូរស័ព្ទ (មេថែមជួរនេះចូល)
        _row(
          Icons.phone_android,
          "លេខទូរស័ព្ទ",
          widget.data['phone'] ?? 'មិនមានលេខទូរស័ព្ទ',
        ),
        const Divider(),


        // ៣. បង្ហាញទីតាំង
        _row(
          Icons.location_on_outlined,
          "ទីតាំង",
          widget.data['location'] ?? 'មិនមានទីតាំង',
        ),
        const Divider(),


        // ៤. បង្ហាញការពិពណ៌នា
        _row(
          Icons.description_outlined,
          "ពិពណ៌នា",
          widget.data['description'] ?? 'មិនមានការពិពណ៌នា',
        ),
      ],
    );
  }


  Widget _row(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ដាក់កូដនេះនៅខាងក្រោមបង្អស់ មុនបិទវង់ក្រចក Class
  String _formatDate(dynamic date) {
    if (date == null) return 'មិនទាន់កំណត់';


    if (date is Timestamp) {
      return DateFormat('dd-MM-yyyy').format(date.toDate());
    }


    return date.toString();
  }
} // នេះគឺជាវង់ក្រចកបិទបញ្ចប់ Class របស់មេ



