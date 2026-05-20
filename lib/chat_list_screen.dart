import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:my_app/create_invoice_sheet.dart';
import 'package:my_app/farm_tools.dart';
import 'package:my_app/invoice_history_screen.dart';
import 'package:my_app/order_management_screen.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';


class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});


  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}


class _ChatListScreenState extends State<ChatListScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundUser;
  bool _isSearchLoading = false;
  String _searchError = '';


  // ✅ ជុសជុល 1: ប្រើ nullable ដើម្បីដឹងថាបាន Load រួចឬនៅ
  String? currentUserId;
  bool _isUserLoaded = false;


  @override
  void initState() {
    super.initState();
    _loadUserId();
  }


  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ១. ព្យាយាមយកពី Preferences ជាអាទិភាពក្នុងករណី Firebase Error
      String uid = prefs.getString('user_uid') ?? '';


      // ២. បើ Preferences អត់មាន ទើបយកពី FirebaseAuth
      if (uid.isEmpty) {
        uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (uid.isNotEmpty) {
          await prefs.setString('user_uid', uid); // Save ទុកការពារលើកក្រោយ
        }
      }


      if (mounted) {
        setState(() {
          // បើ uid នៅតែទទេ គឺទុកវាជា null ដើម្បីឱ្យ UI បង្ហាញផ្ទាំង Login
          currentUserId = uid.isNotEmpty ? uid : null;
          _isUserLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Load User ID Error: $e");
      if (mounted) setState(() => _isUserLoaded = true);
    }
  }


  Future<void> _markAsSeen(String chatRoomId) async {
    if (currentUserId == null || currentUserId!.isEmpty) return;


    try {
      final batch = FirebaseFirestore.instance.batch();
      final unreadQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('receiver', isEqualTo: currentUserId)
          .where('status', isNotEqualTo: 'seen')
          .get();


      for (var doc in unreadQuery.docs) {
        batch.update(doc.reference, {'status': 'seen'});
      }
      await batch.commit();


      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'unreadCount': 0})
          .catchError((e) => debugPrint("Update unreadCount error: $e"));
    } catch (e) {
      debugPrint("Mark as seen error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    // ✅ ជុសជុល 2: បង្ហាញ Loading មុនពេលពិនិត្យ User
    if (!_isUserLoaded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "បញ្ជីសារ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }


    // ✅ ជុសជុល 3: បង្ហាញ Error បើគ្មាន Login
    if (currentUserId == null || currentUserId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "បញ្ជីសារ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              const Text(
                'សូម Login មុននឹងប្រើឆាត',
                style: TextStyle(fontSize: 18, color: Colors.orange),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // បើក Login Screen ឬត្រឡប់ក្រោយ
                  Navigator.pop(context);
                },
                child: const Text('ត្រឡប់ក្រោយ'),
              ),
            ],
          ),
        ),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "បញ្ជីសារ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [_buildInvoiceAction(), _buildToolAction()],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_isSearchLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(color: Colors.green),
            ),
          if (_searchError.isNotEmpty) _buildSearchError(),
          if (_foundUser != null) _buildFoundUserTile(),


          // ... បន្តពី ElevatedButton របស់មេ
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ✅ ថ្មី — field ត្រូវ
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('users', arrayContains: currentUserId)
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // ១. ឆែកមើលក្រែងលោមាន Error (ដូចក្នុង Log ដែលមេផ្ញើមក)
                if (snapshot.hasError) {
                  return Center(child: Text("មានបញ្ហា៖ ${snapshot.error}"));
                }


                // ២. កំពុងទាញទិន្នន័យ
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }


                // ៣. បើអត់ទាន់មានទិន្នន័យឆាត
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }


                // ✅ បន្ថែមក្នុង builder — filter unique chatRoomId
                final Map<String, Map<String, dynamic>> conversations = {};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final roomId = data['chatRoomId'] ?? '';
                  if (roomId.isNotEmpty && !conversations.containsKey(roomId)) {
                    conversations[roomId] = data;
                  }
                }
                final listItems = conversations.values.toList();


                if (listItems.isEmpty) return _buildEmptyState();


                return ListView.builder(
                  itemCount: listItems.length,
                  itemBuilder: (context, index) {
                    var chat = listItems[index];
                    final usersList = chat['users'];
                    if (usersList == null) return const SizedBox();
                    String otherUserId = (usersList as List).firstWhere(
                          (id) => id != currentUserId,
                      orElse: () => '',
                    );
                    if (otherUserId.isEmpty) return const SizedBox();
                    return _buildChatTile(chat, otherUserId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildChatTile(Map<String, dynamic> chat, String otherUserId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .snapshots(),
      builder: (context, userSnapshot) {
        var userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        String userName = userData?['name'] ?? 'អ្នកប្រើប្រាស់';
        String userImg = userData?['photoUrl'] ?? '';
        bool isOnline = userData?['isOnline'] == true; // ✅


        return ListTile(
          onTap: () async {
            await _markAsSeen(chat['chatRoomId']);
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  seller_id: otherUserId,
                  receiver_id: otherUserId,
                  productName: chat['productName'] ?? 'Chat',
                  productId: chat['productId'] ?? 'general',
                ),
              ),
            );
          },
          leading: _buildAvatarWithUnread(
            userImg,
            chat['chatRoomId'],
            isOnline,
          ), // ✅
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (chat['time'] != null)
                Text(
                  _formatTime(chat['time']),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              // ✅ Online status
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  isOnline
                      ? 'កំពុង Online'
                      : _formatLastSeen(userData?['lastSeen']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildAvatarWithUnread(String img, String roomId, bool isOnline) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
          child: img.isEmpty ? const Icon(Icons.person) : null,
        ),


        // ✅ Online dot
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: isOnline ? Colors.greenAccent : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),


        // unread badge
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('chatRoomId', isEqualTo: roomId)
              .where('receiver', isEqualTo: currentUserId)
              .where('status', isNotEqualTo: 'seen')
              .snapshots(),
          builder: (context, unread) {
            if (!unread.hasData || unread.data!.docs.isEmpty)
              return const SizedBox();
            return Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    '${unread.data!.docs.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildSearchBar() {
    return Container(
      color: Colors.green[700],
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (v) {
            setState(() {
              _foundUser = null;
              _searchError = '';
            });
            if (v.length == 6) _searchById(v);
          },
          decoration: const InputDecoration(
            hintText: 'ស្វែងរកតាម Sesan ID (6 ខ្ទង់)...',
            prefixIcon: Icon(Icons.tag_rounded, color: Colors.green),
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }


  Widget _buildFoundUserTile() => GestureDetector(
    onTap: () => _openChatWithFoundUser(_foundUser!),
    child: Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: (_foundUser?['photoUrl'] != null)
                ? NetworkImage(_foundUser!['photoUrl'])
                : null,
            child: (_foundUser?['photoUrl'] == null)
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _foundUser?['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'ID: ${_foundUser?['sesan_id'] ?? ""}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chat, color: Colors.green),
        ],
      ),
    ),
  );


  void _openChatWithFoundUser(Map<String, dynamic> user) {
    _searchController.clear();
    final targetUid = user['uid']?.toString() ?? '';
    if (targetUid.isEmpty) return;
    setState(() => _foundUser = null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          seller_id: targetUid,
          receiver_id: targetUid,
          productName: 'Chat',
          productId: 'general',
        ),
      ),
    );
  }


  void _openInvoiceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateInvoiceSheet(
        onAction: (invoiceData) async {
          final String actionType = invoiceData['type'];


          if (actionType == 'save' || actionType == 'screenshot') {
            await _captureLongInvoice();


            await FirebaseFirestore.instance.collection('invoices').add({
              'buyer_name': CreateInvoiceSheet.cusName.text,
              'buyer_phone': CreateInvoiceSheet.cusPhone.text,
              'buyer_address': CreateInvoiceSheet.cusAddress.text,
              'total_amount': double.tryParse(_calculateGrandTotal()) ?? 0.0,
              'created_at': FieldValue.serverTimestamp(),
            });


            if (mounted) {
              Navigator.pop(context);
            }
          } else if (actionType == 'history') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InvoiceHistoryScreen(),
              ),
            );
          }
        },
      ),
    );
  }


  Future<void> _captureLongInvoice() async {
    try {
      const int itemsPerPage = 10;
      int totalItems = CreateInvoiceSheet.items.length;
      int totalPages = (totalItems / itemsPerPage).ceil();


      for (int i = 0; i < totalPages; i++) {
        int start = i * itemsPerPage;
        int end = (start + itemsPerPage > totalItems)
            ? totalItems
            : start + itemsPerPage;
        List currentPageItems = CreateInvoiceSheet.items.sublist(start, end);


        final imageUint8List = await _screenshotController.captureFromWidget(
          Material(
            color: Colors.white,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Container(
                width: 375,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i == 0) _buildCaptureHeader(),
                    const SizedBox(height: 10),
                    Text(
                      "បញ្ជីទំនិញ (សន្លឹកទី ${i + 1})",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(thickness: 1, color: Colors.black),
                    ...currentPageItems
                        .map((item) => _buildCaptureItemRow(item))
                        .toList(),
                    if (i == totalPages - 1) ...[
                      const Divider(thickness: 1, color: Colors.black),
                      _buildCaptureTotalAndQR(),
                    ],
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "--- ${i + 1} / $totalPages ---",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          pixelRatio: 3.0,
        );
        if (imageUint8List != null) {
          await Gal.putImageBytes(imageUint8List);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ បានថតបំបែកជា $totalPages សន្លឹកក្នុង Gallery"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Capture Error: $e");
    }
  }


  Widget _buildCaptureHeader() {
    return Column(
      children: [
        const Center(
          child: Text(
            "វិក្កយបត្រ / INVOICE",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const Divider(thickness: 2, color: Colors.black),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "ឈ្មោះអ្នកទិញ៖ ${CreateInvoiceSheet.cusName.text}",
            style: const TextStyle(color: Colors.black),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "លេខទូរស័ព្ទ៖ ${CreateInvoiceSheet.cusPhone.text}",
            style: const TextStyle(color: Colors.black),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "អាសយដ្ឋាន៖ ${CreateInvoiceSheet.cusAddress.text}",
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }


  Widget _buildCaptureItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item['desc']!.text,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          Text(
            "${item['qty']!.text} x ${item['price']!.text} ៛",
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }


  Widget _buildCaptureTotalAndQR() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "សរុបចុងក្រោយ៖",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "${_calculateGrandTotal()} ៛",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        if (CreateInvoiceSheet.qrFile != null) ...[
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Scan ដើម្បីបង់ប្រាក់",
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),
          const SizedBox(height: 10),
          Center(child: Image.file(CreateInvoiceSheet.qrFile!, width: 160)),
        ],
      ],
    );
  }


  String _calculateGrandTotal() {
    double total = CreateInvoiceSheet.items.fold(
      0,
          (sum, item) =>
      sum +
          ((double.tryParse(item['qty']!.text) ?? 0) *
              (double.tryParse(item['price']!.text) ?? 0)),
    );
    return (total + (double.tryParse(CreateInvoiceSheet.shipPrice.text) ?? 0))
        .toStringAsFixed(0);
  }


  String _formatLastSeen(dynamic timestamp) {
    if (timestamp == null) return 'អសកម្ម';
    final time = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'ទើបតែសកម្ម';
    if (diff.inMinutes < 60) return 'សកម្ម ${diff.inMinutes} នាទីមុន';
    if (diff.inHours < 24) return 'សកម្ម ${diff.inHours} ម៉ោងមុន';
    return 'សកម្ម ${diff.inDays} ថ្ងៃមុន';
  }


  Future<void> _searchById(String id) async {
    setState(() {
      _isSearchLoading = true;
      _foundUser = null;
      _searchError = '';
    });
    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('sesan_id', isEqualTo: id)
          .limit(1)
          .get();
      if (result.docs.isEmpty) {
        setState(() {
          _searchError = 'រកមិនឃើញ ID: $id';
          _isSearchLoading = false;
        });
        return;
      }
      final foundData = result.docs.first.data();
      final foundUid = result.docs.first.id;
      if (foundUid == currentUserId) {
        setState(() {
          _searchError = 'នេះគឺជា ID របស់អ្នកផ្ទាល់!';
          _isSearchLoading = false;
        });
        return;
      }
      setState(() {
        _foundUser = {...foundData, 'uid': foundUid};
        _isSearchLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchError = '❌ មានបញ្ហា: $e';
        _isSearchLoading = false;
      });
    }
  }


  Widget _buildEmptyState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 64),
        SizedBox(height: 16),
        Text(
          'មិនទាន់មានការសន្ទនា',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          'ចាប់ផ្តើមសន្ទនាជាមួយអ្នកលក់ឥឡូវនេះ!',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    ),
  );


  Widget _buildSearchError() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      _searchError,
      style: const TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    ),
  );


  // 🎯 Method បង្កើតបុង
  Widget _buildInvoiceAction() => SizedBox(
    height: 35,
    child: ActionChip(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      label: const Text(
        "បង្កើតបុង",
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: 'Siemreap',
        ),
      ),
      backgroundColor: Colors.orange[800],
      onPressed:
      _openInvoiceSheet, // ប្រាកដថាមេមាន method នេះ បើមិនទាន់មាន ត្រូវបង្កើតដែរ
    ),
  );


  // 🎯 Method ប៊ូតុងគិតលេខ
  Widget _buildToolAction() => Container(
    height: 36,
    width: 36,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: IconButton(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.calculate_rounded, color: Colors.green[700], size: 22),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FarmToolsPage()),
      ),
    ),
  );


  String _getSubtitleText(Map<String, dynamic> chat) {
    if (chat['type'] == 'image') return "📷 រូបភាព";
    if (chat['type'] == 'video') return "🎥 វីដេអូ";
    if (chat['type'] == 'audio') return "🎵 សម្លេង";
    return chat['message'] ?? "";
  }


  String _formatTime(Timestamp ts) => DateFormat('hh:mm a').format(ts.toDate());
}



