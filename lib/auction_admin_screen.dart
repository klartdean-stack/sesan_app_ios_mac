import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


class AuctionAdminScreen extends StatelessWidget {
  const AuctionAdminScreen({super.key});


  static const _bg = Color(0xFF0D1117);
  static const _card = Color(0xFF161B22);
  static const _border = Color(0xFF30363D);
  static const _accent = Color(0xFF238636);
  static const _accentBlue = Color(0xFF1F6FEB);
  static const _text = Color(0xFFE6EDF3);
  static const _textMuted = Color(0xFF8B949E);
  static const _red = Color(0xFFDA3633);
  static const _gold = Color(0xFFFFB300);


  // ── Zoom Image ────────────────────────────────────────────────
  void _showZoomImage(BuildContext context, String url) {
    if (url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ── Approve Auction ───────────────────────────────────────────
  Future<void> _approveAuction(
      BuildContext context,
      String requestId,
      Map<String, dynamic> data,
      ) async {
    try {
      // បង្ហាញ Loading ជាមុនសិនដើម្បីកុំឱ្យ User ចុចជាន់គ្នា
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );


      final hours =
          int.tryParse(data['duration_hours']?.toString() ?? '24') ?? 24;
      final endTime = DateTime.now().add(Duration(hours: hours));


      // ១. បញ្ចូលទៅក្នុង collection products
      await FirebaseFirestore.instance.collection('products').add({
        'product_name': data['product_name'],
        'description': data['description'] ?? '',
        'image_urls': data['image_urls'] ?? [],
        'status': 'auction',
        'start_price': data['start_price'],
        'current_price': data['start_price'],
        'bid_step': data['bid_step'],
        'end_time': Timestamp.fromDate(endTime),
        'owner_id': data['owner_id'] ?? '',
        'owner_name': data['owner_name'] ?? '',
        'last_bidder': null,
        'last_bidder_id': null,
        'created_at': FieldValue.serverTimestamp(),
      });


      // ២. លុបសំណើចេញពី auction_requests
      await FirebaseFirestore.instance
          .collection('auction_requests')
          .doc(requestId)
          .delete();


      // ៣. បិទ Loading Dialog
      if (!context.mounted) return;
      Navigator.pop(context);


      // ៤. បង្ហាញសារជោគជ័យ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ អនុម័តជោគជ័យ! ការដេញថ្លៃចាប់ផ្តើមហើយ',
            style: TextStyle(fontFamily: 'Siemreap'),
          ),
          backgroundColor: _accent,
        ),
      );
    } catch (e) {
      // ប្រសិនបើមាន Error ត្រូវបិទ Loading ដែរ
      if (context.mounted) Navigator.pop(context);


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: _red),
      );
    }
  }


  // ── Delete Dialog ─────────────────────────────────────────────
  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'លុបសំណើ?',
                style: TextStyle(
                  color: _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Siemreap',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'សំណើនេះនឹងត្រូវលុបចោលជាអចិន្ត្រៃយ៍',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 13,
                  fontFamily: 'Siemreap',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMuted,
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'បោះបង់',
                        style: TextStyle(fontFamily: 'Siemreap'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('auction_requests')
                            .doc(docId)
                            .delete();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'លុប',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Siemreap',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  } // ══════════════════════════════════════════════════════════════


  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'សំណើដាក់ដេញថ្លៃ',
          style: TextStyle(
            color: _text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('auction_requests')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(
              child: CircularProgressIndicator(color: _accentBlue),
            );


          final docs = snap.data!.docs;


          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _card,
                      shape: BoxShape.circle,
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(
                      Icons.inbox_outlined,
                      color: _textMuted,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'មិនមានសំណើថ្មីទេ',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 16,
                      fontFamily: 'Siemreap',
                    ),
                  ),
                ],
              ),
            );
          }


          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _buildRequestCard(context, doc.id, data);
            },
          );
        },
      ),
    );
  }


  // ── Request Card ──────────────────────────────────────────────
  Widget _buildRequestCard(
      BuildContext context,
      String docId,
      Map<String, dynamic> data,
      ) {
    final fmt = NumberFormat('#,###');
    final images = (data['image_urls'] as List?) ?? [];
    final firstImg = images.isNotEmpty ? images[0].toString() : '';
    final payImg = data['payment_image_url'] ?? '';
    final createdAt = data['created_at'] != null
        ? (data['created_at'] as Timestamp).toDate()
        : null;


    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _gold.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                if (createdAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                    style: const TextStyle(color: _textMuted, fontSize: 11),
                  ),
              ],
            ),
          ),


          // ស្វែងរក Row ក្នុងផ្នែក Image Previews ហើយប្រើ Expanded ស្រោបពីលើ
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  // 🎯 បន្ថែម Expanded ដើម្បីឱ្យរូបភាពទី១ បត់បែនតាមអេក្រង់
                  child: _buildImagePreview(
                    context,
                    'រូបទំនិញ',
                    firstImg,
                    imageCount: images.length,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // 🎯 បន្ថែម Expanded ដើម្បីឱ្យរូបភាពទី២ បត់បែនតាមអេក្រង់
                  child: _buildImagePreview(context, 'វិក្កយបត្រ', payImg),
                ),
              ],
            ),
          ), // ── Product Info ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['product_name'] ?? 'គ្មានឈ្មោះ',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Siemreap',
                  ),
                ),
                const SizedBox(height: 12),


                // Price info row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _infoChip(
                      Icons.attach_money_rounded,
                      'ចាប់ផ្តើម',
                      '${fmt.format(int.tryParse(data['start_price']?.toString() ?? '0') ?? 0)} ៛',
                      _accent,
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                      Icons.trending_up_rounded,
                      'Step',
                      '+${fmt.format(int.tryParse(data['bid_step']?.toString() ?? '0') ?? 0)} ៛',
                      _gold,
                    ),
                  ],
                ),
                const SizedBox(height: 8),


                // End time
                if (data['end_time'] != null)
                  _infoChip(
                    Icons.schedule_rounded,
                    'បញ្ចប់នៅ',
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format((data['end_time'] as Timestamp).toDate()),
                    _accentBlue,
                  ),


                // Package
                if (data['selected_package'] != null) ...[
                  const SizedBox(height: 8),
                  _infoChip(
                    Icons.workspace_premium_outlined,
                    'Package',
                    data['selected_package'],
                    const Color(0xFFBB86FC),
                  ),
                ],


                // Phone
                if (data['customer_phone'] != null) ...[
                  const SizedBox(height: 8),
                  _infoChip(
                    Icons.phone_outlined,
                    'ទូរស័ព្ទ',
                    data['customer_phone'],
                    _textMuted,
                  ),
                ],


                // Description
                if ((data['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      data['description'],
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontFamily: 'Siemreap',
                      ),
                    ),
                  ),
                ],


                const SizedBox(height: 16),
                const Divider(color: _border, height: 1),
                const SizedBox(height: 16),


                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _approveAuction(context, docId, data),
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'អនុម័ត',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Siemreap',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () => _showDeleteDialog(context, docId),
                      child: const Icon(Icons.delete_outline_rounded, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ── Image Preview ─────────────────────────────────────────────
  Widget _buildImagePreview(
      BuildContext context,
      String label,
      String url, {
        int imageCount = 1,
      }) {
    return GestureDetector(
      onTap: () => _showZoomImage(context, url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 11,
              fontFamily: 'Siemreap',
            ),
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 110,
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: url.isEmpty
                    ? const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: _textMuted,
                    size: 28,
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: _bg),
                    errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: _textMuted),
                  ),
                ),
              ),
              if (url.isNotEmpty)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.zoom_in_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              if (imageCount > 1)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+$imageCount រូប',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }


  // ── Info Chip ─────────────────────────────────────────────────
  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 11,
              fontFamily: 'Siemreap',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Siemreap',
            ),
          ),
        ],
      ),
    );
  }
}



