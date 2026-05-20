import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'auction_detail_screen.dart';
import 'auction_add_screen.dart';


class AuctionMainScreen extends StatefulWidget {
  const AuctionMainScreen({super.key});


  @override
  State<AuctionMainScreen> createState() => _AuctionMainScreenState();
}


class _AuctionMainScreenState extends State<AuctionMainScreen>
    with TickerProviderStateMixin {
  // ── Config ─────────────────────────────────────────────────────
  static const _adminId = 'WBdQVvrgEIPBTcgIlumu6bAZGUl2';


  // ── State ──────────────────────────────────────────────────────
  late Timer _timer;
  bool _isExpanded = false;


  // ── Theme ──────────────────────────────────────────────────────
  static const _bg = Color(0xFF0D1117);
  static const _card = Color(0xFF161B22);
  static const _border = Color(0xFF30363D);
  static const _accent = Color(0xFF238636);
  static const _accentBlue = Color(0xFF1F6FEB);
  static const _text = Color(0xFFE6EDF3);
  static const _textMuted = Color(0xFF8B949E);
  static const _red = Color(0xFFDA3633);
  static const _gold = Color(0xFFFFB300);


  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }


  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }


  // ── Delete Dialog ──────────────────────────────────────────────
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
                'លុបការដេញថ្លៃ?',
                style: TextStyle(
                  color: _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Siemreap',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ការដេញថ្លៃនេះនឹងត្រូវលុបចោលជាអចិន្ត្រៃយ៍',
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
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(docId)
                            .delete();
                        if (ctx.mounted) Navigator.pop(ctx);
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
  }


  // ── Rules Dialog ───────────────────────────────────────────────
  void _showRulesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accentBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: _accentBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'គោលការណ៍ចូលរួម',
                      style: TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Siemreap',
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: _border, height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: const [
                    _RuleItem(
                      number: '01',
                      title: 'ការដេញថ្លៃ',
                      desc:
                      'ការដេញថ្លៃត្រូវអនុវត្តតាមជំហានតម្លៃ (Step) ដែលបានកំណត់។ រាល់ការដេញថ្លៃដែលជោគជ័យមិនអាចដកវិញបានឡើយ។',
                      color: _accentBlue,
                    ),
                    _RuleItem(
                      number: '02',
                      title: 'ការបង់ប្រាក់',
                      desc:
                      'ម្ចាស់បន្តវេន (អ្នកឈ្នះ) ត្រូវបង្ហើយកិច្ចសន្យាជាវក្នុងរយៈពេល ២៤ ម៉ោង បន្ទាប់ពីការដេញថ្លៃត្រូវបានបញ្ចប់។',
                      color: _accent,
                    ),
                    _RuleItem(
                      number: '03',
                      title: 'ការដឹកជញ្ជូន',
                      desc:
                      'សេវាកម្មដឹកជញ្ជូន និងការវេចខ្ចប់ គឺជាការចរចា និងព្រមព្រៀងគ្នាដោយផ្ទាល់រវាងអ្នកដាក់ដេញថ្លៃ និងអ្នកឈ្នះ។',
                      color: _gold,
                    ),
                    _RuleItem(
                      number: '04',
                      title: 'តម្លាភាព និងវិវាទ',
                      desc:
                      'ក្នុងករណីមានវិវាទកើតឡើង ក្រុមការងារ Admin នឹងធ្វើការពិនិត្យ និងសម្រេចជាចុងក្រោយ ដើម្បីរក្សាយុត្តិធម៌។',
                      color: _red,
                    ),
                    _RuleItem(
                      number: '05',
                      title: 'ការដាក់ដេញថ្លៃ',
                      desc:
                      'ម្ចាស់ទំនិញត្រូវជ្រើសរើសកញ្ចប់សេវា និងរង់ចាំការអនុម័តពី Admin ដើម្បីធានានូវគុណតម្លៃនៃវត្ថុដែលត្រូវដាក់លក់។',
                      color: const Color(0xFFBB86FC),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ── Timer Widget ───────────────────────────────────────────────
  Widget _buildTimer(dynamic endTime) {
    if (endTime == null) return const SizedBox();
    final end = (endTime as Timestamp).toDate();
    final remaining = end.difference(DateTime.now());
    final finished = remaining.isNegative;
    final urgent = !finished && remaining.inMinutes < 30;


    if (finished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _red.withOpacity(0.3)),
        ),
        child: const Text(
          'ចប់ហើយ',
          style: TextStyle(
            color: _red,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Siemreap',
          ),
        ),
      );
    }


    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    final color = urgent ? _red : _accentBlue;


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            '${h.toString().padLeft(2, '0')}:'
                '${m.toString().padLeft(2, '0')}:'
                '${s.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }


  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;


    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'ផ្សារដេញថ្លៃ',
          style: TextStyle(
            color: _text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Siemreap',
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AuctionAddScreen()),
        ),
        backgroundColor: _accent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'ដាក់ដេញថ្លៃ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Siemreap',
          ),
        ),
      ),
      body: Column(
        children: [
          // Vision Header
          _buildVisionHeader(),


          // Auction List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('status', isEqualTo: 'auction')
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
                            Icons.gavel_rounded,
                            color: _textMuted,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'មិនទាន់មានការដេញថ្លៃ',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 15,
                            fontFamily: 'Siemreap',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ចុច "+ ដាក់ដេញថ្លៃ" ដើម្បីចាប់ផ្តើម',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            fontFamily: 'Siemreap',
                          ),
                        ),
                      ],
                    ),
                  );
                }


                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    final images = (data['image_urls'] as List?) ?? [];
                    final imageUrl = images.isNotEmpty
                        ? images[0].toString()
                        : '';
                    return _buildAuctionCard(
                      context,
                      docId,
                      data,
                      imageUrl,
                      currentUser,
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


  // ── Vision Header ──────────────────────────────────────────────
  Widget _buildVisionHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _gold,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'ចក្ខុវិស័យ និងតម្លៃមរតក',
                style: TextStyle(
                  color: _text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Siemreap',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            firstChild: const Text(
              'រាល់ឧបករណ៍ដែលបន្សល់ទុក មិនមែនគ្រាន់តែជាដែក ឬឈើដែលចាស់ទ្រុឌទ្រោមនោះទេ...',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textMuted,
                fontSize: 13,
                height: 1.6,
                fontFamily: 'Siemreap',
              ),
            ),
            secondChild: const Text(
              "រាល់ឧបករណ៍ដែលបន្សល់ទុក មិនមែនគ្រាន់តែជាដែក ឬឈើដែលចាស់ទ្រុឌទ្រោមនោះទេ តែវាគឺជាញើសឈាម និងបញ្ញាញាណរបស់ដូនតាខ្មែរដែលបានចិញ្ចឹមបីបាច់កូនចៅតាំងពីដើមរៀងមក។ យើងបង្កើតកម្មវិធីដេញថ្លៃនេះឡើង ដើម្បីផ្តល់តម្លៃ និងដឹងគុណដល់រាល់ស្នាដៃបុរាណៗទាំងនោះ ដោយផ្តល់ឱកាសឱ្យលោកអ្នកក្លាយជាអ្នកបន្តវេនថែរក្សា 'ព្រលឹងវប្បធម៌' ឱ្យនៅរស់រវើកជានិច្ចក្នុងសម័យកាលថ្មី។ ពីនង្គ័លមួយដែលធ្លាប់ហែកដីស្រែ ដល់ឧបករណ៍ប្រើប្រាស់ដែលធ្លាប់សម្រាលទុក្ខលំបាក... វត្ថុនីមួយៗសុទ្ធតែមានរឿងរ៉ាវ និងគុណូបការៈមិនអាចកាត់ថ្លៃបាន។",
              style: TextStyle(
                color: _textMuted,
                fontSize: 13,
                height: 1.6,
                fontFamily: 'Siemreap',
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded ? 'លាក់វិញ ▲' : 'អានបន្ថែម ▼',
                  style: const TextStyle(
                    color: _accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showRulesDialog(context),
                child: const Row(
                  children: [
                    Text(
                      'គោលការណ៍',
                      style: TextStyle(
                        color: _accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        fontFamily: 'Siemreap',
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _accentBlue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ── Auction Card ───────────────────────────────────────────────
  Widget _buildAuctionCard(
      BuildContext context,
      String docId,
      Map<String, dynamic> data,
      String imageUrl,
      User? currentUser,
      ) {
    final fmt = NumberFormat('#,###');
    final currentPrice =
        int.tryParse(data['current_price']?.toString() ?? '0') ?? 0;
    final endTime = data['end_time'];
    final isFinished =
        endTime != null &&
            (endTime as Timestamp).toDate().isBefore(DateTime.now());
    final isAdmin = currentUser?.uid == _adminId;


    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuctionDetailScreen(productId: docId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  child: imageUrl.isEmpty
                      ? Container(
                    height: 200,
                    color: _bg,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: _textMuted,
                        size: 40,
                      ),
                    ),
                  )
                      : CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(height: 200, color: _bg),
                    errorWidget: (_, __, ___) => Container(
                      height: 200,
                      color: _bg,
                      child: const Icon(
                        Icons.broken_image,
                        color: _textMuted,
                      ),
                    ),
                  ),
                ),


                // Gradient
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(19),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),


                // LIVE / ENDED badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isFinished ? _border : _red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isFinished
                          ? []
                          : [
                        BoxShadow(
                          color: _red.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFinished
                              ? Icons.lock_outline_rounded
                              : Icons.circle,
                          size: isFinished ? 12 : 7,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isFinished ? 'ចប់ហើយ' : 'LIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                // Admin delete
                if (isAdmin)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _showDeleteDialog(context, docId),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: _red,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ), // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['product_name'] ?? 'គ្មានឈ្មោះ',
                    style: const TextStyle(
                      color: _text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Siemreap',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'តម្លៃបច្ចុប្បន្ន',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 11,
                              fontFamily: 'Siemreap',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${fmt.format(currentPrice)} ៛',
                            style: const TextStyle(
                              color: _accent,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      _buildTimer(endTime),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isFinished ? _border : _accentBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        isFinished ? 'ការដេញថ្លៃចប់ហើយ' : 'ចូលរួមដេញថ្លៃ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Siemreap',
                        ),
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
  }
}


// ── Rule Item Widget ───────────────────────────────────────────────
class _RuleItem extends StatelessWidget {
  final String number;
  final String title;
  final String desc;
  final Color color;


  const _RuleItem({
    required this.number,
    required this.title,
    required this.desc,
    required this.color,
  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Siemreap',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'Siemreap',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



