import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class UserNotificationScreen extends StatelessWidget {
  const UserNotificationScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: const Text(
          'ការជូនដំណឹង',
          style: TextStyle(
            fontFamily: 'Siemreap',
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B5BFF)),
            );
          }


          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'មិនទាន់មានដំណឹងថ្មីឡើយ',
                    style: TextStyle(
                      fontFamily: 'Siemreap',
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }


          final docs = snapshot.data!.docs;


          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isFirst = index == 0;
              return _NotiCard(data: data, isNew: isFirst);
            },
          );
        },
      ),
    );
  }
}


// ── Notification Card ──────────────────────────────────────
class _NotiCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isNew;


  const _NotiCard({required this.data, this.isNew = false});


  @override
  State<_NotiCard> createState() => _NotiCardState();
}


class _NotiCardState extends State<_NotiCard> {
  bool _isExpanded = false;
  static const int _maxChars = 150;


  // ── ពណ៌ និង Icon តាម type ──────────────────────────────
  _NotiStyle _getStyle(String? type) {
    switch (type) {
      case 'warning':
        return _NotiStyle(
          color: const Color(0xFFFF6B35),
          bg: const Color(0xFFFFF3EE),
          icon: Icons.warning_amber_rounded,
        );
      case 'success':
        return _NotiStyle(
          color: const Color(0xFF2DCB73),
          bg: const Color(0xFFEEFBF4),
          icon: Icons.check_circle_rounded,
        );
      case 'info':
        return _NotiStyle(
          color: const Color(0xFF3B5BFF),
          bg: const Color(0xFFEEF2FF),
          icon: Icons.info_rounded,
        );
      default:
        return _NotiStyle(
          color: const Color(0xFF3B5BFF),
          bg: const Color(0xFFEEF2FF),
          icon: Icons.campaign_rounded,
        );
    }
  }


  String _formatDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = (ts as Timestamp).toDate();
      return DateFormat('dd MMM yyyy • HH:mm').format(date);
    } catch (_) {
      return '';
    }
  }


  @override
  Widget build(BuildContext context) {
    final content = widget.data['message'] ?? '';
    final title = widget.data['title'] ?? '';
    final type = widget.data['type'] as String?;
    final style = _getStyle(type);
    final date = _formatDate(widget.data['created_at']);
    final isLong = content.length > _maxChars;


    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: style.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Color Bar Top ───────────────────────────
            Container(height: 4, color: style.color),


            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Row ───────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: style.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(style.icon, color: style.color, size: 22),
                      ),
                      const SizedBox(width: 12),


                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title + NEW badge ────
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                      fontFamily: 'Siemreap',
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                if (widget.isNew)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'ថ្មី',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontFamily: 'Siemreap',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),


                            // ── Date ────────────────
                            if (date.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),


                  // ── Divider ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.grey.shade100),
                  ),


                  // ── Content ──────────────────────────
                  AnimatedCrossFade(
                    firstChild: Text(
                      content,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        height: 1.6,
                        color: Colors.grey.shade700,
                        fontSize: 13.5,
                        fontFamily: 'Siemreap',
                      ),
                    ),
                    secondChild: Text(
                      content,
                      style: TextStyle(
                        height: 1.6,
                        color: Colors.grey.shade700,
                        fontSize: 13.5,
                        fontFamily: 'Siemreap',
                      ),
                    ),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),


                  // ── See More Button ───────────────────
                  if (isLong)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () =>
                            setState(() => _isExpanded = !_isExpanded),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isExpanded ? 'បិទវិញ' : 'មើលបន្ថែម',
                              style: TextStyle(
                                color: style.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Siemreap',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: style.color,
                              size: 18,
                            ),
                          ],
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


// ── Style Model ───────────────────────────────────────────
class _NotiStyle {
  final Color color;
  final Color bg;
  final IconData icon;


  _NotiStyle({required this.color, required this.bg, required this.icon});
}




