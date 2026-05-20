import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_app/admin_delete_screen.dart';
import 'package:my_app/admin_dispute_screen.dart';
import 'package:my_app/admin_notification_screen.dart';
import 'package:my_app/admin_stock_management.dart';
import 'package:my_app/admin_transfer_requests_screen.dart';
import 'transactionconfirm_history.dart';


class AdminWithdrawList extends StatefulWidget {
  const AdminWithdrawList({super.key});


  @override
  _AdminWithdrawListState createState() => _AdminWithdrawListState();
}


class _AdminWithdrawListState extends State<AdminWithdrawList> {
  File? _adminReceiptImage;
  final picker = ImagePicker();


  Future<void> _pickImage(
      ImageSource source,
      StateSetter setStateCustom,
      ) async {
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setStateCustom(() => _adminReceiptImage = File(pickedFile.path));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          "បញ្ជីស្នើដកប្រាក់",
          style: TextStyle(
            fontFamily: 'KHMEROS',
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 🎯 ប្តូរទៅពណ៌ទឹកប៊ិចចាស់បែប ABA (Deep Navy Blue)
        backgroundColor: const Color(0xFF003F63),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            // 🎯 ប្តូរ Icon ទៅជាតំណាងក្រុមហ៊ុន/ហ៊ុនវិញ (Icons.corporate_fare)
            icon: const Icon(
              Icons.corporate_fare,
              color: Colors.white,
              size: 28,
            ),
            offset: const Offset(0, 50), // ឱ្យវាធ្លាក់មកក្រោម AppBar បន្តិច
            onSelected: (value) {
              switch (value) {
                case 'stock':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminStockManagement(),
                    ),
                  );
                  break;
                case 'transfers':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminTransferRequestsScreen(),
                    ),
                  );
                  break;
                case 'history':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransactionConfirmHistory(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              _buildPopupItem('stock', Icons.inventory_2, "គ្រប់គ្រងភាគហ៊ុន"),
              _buildPopupItem('transfers', Icons.swap_horiz, "សំណើផ្ទេរ"),
              _buildPopupItem('history', Icons.history, "ប្រវត្តិបាញ់លុយ"),
            ],
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: () {
              // ចុចទៅកាន់ Screen បង្កើតដំណឹង (Admin Side)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminNotificationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_alert, color: Colors.white),
            label: const Text(
              "ផ្ញើដំណឹង",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(
              Icons.report_problem_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDisputeScreen(),
                ),
              );
            },
            tooltip: 'មើលបណ្ដឹង',
          ),
          IconButton(
            icon: const Icon(
              Icons.format_list_bulleted_rounded,
              color: Colors.white70,
            ),
            tooltip: 'គ្រប់គ្រងទិន្នន័យ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManagementScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('withdraw_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("មិនមានសំណើដកប្រាក់ទេ"));


          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var request = snapshot.data!.docs[index];
              var data = request.data() as Map<String, dynamic>;
              String sellerId = data['seller_id'] ?? "";


              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: FutureBuilder(
                  future: Future.wait([
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(sellerId)
                        .get(),
                    FirebaseFirestore.instance
                        .collection('products')
                        .where('seller_id', isEqualTo: sellerId)
                        .limit(1)
                        .get(),
                  ]),
                  builder: (context, AsyncSnapshot<List<dynamic>> multiSnapshot) {
                    if (!multiSnapshot.hasData)
                      return const LinearProgressIndicator();


                    var userDoc = multiSnapshot.data![0] as DocumentSnapshot;
                    var productQuery = multiSnapshot.data![1] as QuerySnapshot;


                    String sesanId = userDoc.exists
                        ? (userDoc.data() as Map)['sesan_id'] ?? 'N/A'
                        : 'N/A';
                    double availableBalance = userDoc.exists
                        ? (userDoc.data() as Map)['available_balance']
                        ?.toDouble() ??
                        0.0
                        : 0.0;
                    String sName = productQuery.docs.isNotEmpty
                        ? productQuery.docs.first['seller_name']
                        : 'អត់ឈ្មោះ';
                    String sPhone = productQuery.docs.isNotEmpty
                        ? productQuery.docs.first['seller_phone']
                        : 'អត់លេខ';
                    String sPhoto = productQuery.docs.isNotEmpty
                        ? productQuery.docs.first['seller_photo']
                        : '';


                    double requestAmount = (data['amount'] ?? 0).toDouble();
                    String requestTime = data['created_at'] != null
                        ? DateFormat(
                      'dd-MM HH:mm',
                    ).format((data['created_at'] as Timestamp).toDate())
                        : "N/A";


                    bool isBalanceInsufficient =
                        availableBalance < requestAmount;
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: sPhoto.isNotEmpty
                                    ? NetworkImage(sPhoto)
                                    : null,
                                child: sPhoto.isEmpty
                                    ? const Icon(Icons.person, size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${requestAmount.toStringAsFixed(0)} ៛",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text(
                                      "សមតុល្យ៖ ${availableBalance.toStringAsFixed(0)} ៛",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isBalanceInsufficient
                                            ? Colors.red
                                            : Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "ស្នើនៅ៖ $requestTime",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildActionButtons(
                                request.id,
                                sellerId,
                                requestAmount,
                                isBalanceInsufficient,
                                sName,
                                sPhone,
                                sPhoto,
                                sesanId,
                                availableBalance,
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildInfoRow(
                            Icons.badge_outlined,
                            "Sesan ID",
                            sesanId,
                          ),
                          _buildInfoRow(
                            Icons.person_outline,
                            "ឈ្មោះអ្នកលក់",
                            sName,
                          ),
                          _buildInfoRow(
                            Icons.account_balance_outlined,
                            "ធនាគារ",
                            "${data['bank_name'] ?? 'N/A'}",
                          ),
                          _buildInfoRow(
                            Icons.credit_card_outlined,
                            "លេខគណនី",
                            "${data['account_number'] ?? 'N/A'}",
                          ),
                          _buildInfoRow(
                            Icons.person_pin_outlined,
                            "ឈ្មោះគណនី",
                            "${data['account_name'] ?? 'N/A'}",
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }


  PopupMenuItem<String> _buildPopupItem(
      String value,
      IconData icon,
      String title,
      ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF003F63),
            size: 20,
          ), // ប្រើពណ៌ទឹកប៊ិចចាស់ ABA
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontFamily: 'KHMEROS', fontSize: 13),
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons(
      String rId,
      String sId,
      dynamic amt,
      bool isDisabled,
      String sName,
      String sPhone,
      String sPhoto,
      String sesanId,
      double bal,
      ) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? Colors.grey : Colors.green,
            minimumSize: const Size(90, 32),
          ),
          onPressed: isDisabled
              ? null
              : () => _showApprovalDialog(
            rId,
            sId,
            amt,
            isDisabled,
            sName,
            sPhone,
            sPhoto,
            sesanId,
            bal,
          ),
          child: const Text(
            "យល់ព្រម",
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        TextButton(
          onPressed: () => _showRejectDialog(rId, sId, amt),
          child: const Text(
            "បដិសេធ",
            style: TextStyle(
              color: Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


  void _showApprovalDialog(
      String requestId,
      String sellerId,
      dynamic amount,
      bool isInsufficient,
      String sName,
      String sPhone,
      String sPhoto,
      String sesanId,
      double bal,
      ) {
    _adminReceiptImage = null;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateCustom) => AlertDialog(
          title: const Text(
            "បញ្ជាក់ការបាញ់លុយ",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'KHMEROS', fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ចំនួនទឹកប្រាក់៖ $amount ៛",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () =>
                        _pickImage(ImageSource.camera, setStateCustom),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: () =>
                        _pickImage(ImageSource.gallery, setStateCustom),
                  ),
                ],
              ),
              if (_adminReceiptImage != null)
                Image.file(_adminReceiptImage!, height: 100, fit: BoxFit.cover),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("បោះបង់"),
            ),
            ElevatedButton(
              onPressed: _adminReceiptImage == null
                  ? null
                  : () => _approveRequest(
                requestId,
                sellerId,
                amount,
                isInsufficient,
                sName,
                sPhone,
                sPhoto,
                sesanId,
                bal,
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("យល់ព្រម"),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _approveRequest(
      String rId,
      String sId,
      dynamic amt,
      bool isIns,
      String sName,
      String sPh,
      String sPt,
      String sIdn,
      double bal,
      ) async {
    _showLoading();
    try {
      String fileName =
          'receipts_admin/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child(fileName)
          .putFile(_adminReceiptImage!);
      String receiptUrl = await (await uploadTask).ref.getDownloadURL();


      WriteBatch batch = FirebaseFirestore.instance.batch();
      batch.update(
        FirebaseFirestore.instance.collection('withdraw_requests').doc(rId),
        {
          'status': 'success',
          'admin_receipt': receiptUrl,
          'approved_at': FieldValue.serverTimestamp(),
          'seller_name': sName,
          'seller_phone': sPh,
          'seller_photo': sPt,
          'sesan_id': sIdn,
        },
      );
      batch.update(FirebaseFirestore.instance.collection('users').doc(sId), {
        'available_balance': FieldValue.increment(-amt),
      });


      await batch.commit();
      Navigator.pop(context); // close loading
      Navigator.pop(context); // close dialog
      _showSnackBar("ជោគជ័យ!", Colors.green);
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar("Error: $e", Colors.red);
    }
  }


  void _showRejectDialog(String rId, String sId, dynamic amt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("បដិសេធ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ទេ"),
          ),
          ElevatedButton(
            onPressed: () => _rejectRequest(rId, sId, amt),
            child: const Text("បដិសេធ"),
          ),
        ],
      ),
    );
  }


  Future<void> _rejectRequest(String rId, String sId, dynamic amt) async {
    _showLoading();
    await FirebaseFirestore.instance
        .collection('withdraw_requests')
        .doc(rId)
        .update({'status': 'rejected'});
    Navigator.pop(context);
    Navigator.pop(context);
  }


  void _showLoading() => showDialog(
    context: context,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );
  void _showSnackBar(String msg, Color color) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
}



