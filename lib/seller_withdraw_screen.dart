import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SellerWithdrawScreen extends StatefulWidget {
  const SellerWithdrawScreen({super.key});


  @override
  State<SellerWithdrawScreen> createState() => _SellerWithdrawScreenState();
}


class _SellerWithdrawScreenState extends State<SellerWithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  final currencyFormat = NumberFormat('#,###');


  String? userId;
  bool _isLoading = false;
  double _canWithdraw = 0;


  @override
  void initState() {
    super.initState();
    _loadUserId();
  }


  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }


  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_uid');
    });
  }


  void _showWithdrawDialog() {
    final accountNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final pinController = TextEditingController();
    String selectedBank = 'ABA';
    File? selectedQR;
    bool isSubmitting = false;


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "បញ្ជាក់អត្តសញ្ញាណដកប្រាក់",
            style: TextStyle(
              fontFamily: 'Siemreap',
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedBank,
                  decoration: const InputDecoration(labelText: "រើសធនាគារ *"),
                  items: ['ABA', 'AC', 'Canadia', 'Wing', 'ផ្សេងៗ']
                      .map(
                        (bank) =>
                        DropdownMenuItem(value: bank, child: Text(bank)),
                  )
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedBank = val!),
                ),
                TextField(
                  controller: accountNameController,
                  decoration: const InputDecoration(labelText: "ឈ្មោះគណនី *"),
                ),
                TextField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(
                    labelText: "លេខគណនីធនាគារ *",
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),


                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null)
                      setDialogState(() => selectedQR = File(image.path));
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: selectedQR == null
                        ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code),
                        Text(
                          "Upload KHQR",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    )
                        : Image.file(selectedQR!, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 15),


                TextField(
                  controller: pinController,
                  decoration: const InputDecoration(
                    labelText: "លេខសម្ងាត់ ៦ ខ្ទង់ *",
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.red),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("បោះបង់"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: isSubmitting
                  ? null
                  : () async {
                if (accountNameController.text.isEmpty ||
                    selectedQR == null ||
                    pinController.text.length < 6) {
                  _showSnackBar(
                    "⚠️ សូមបំពេញព័ត៌មាន និងលេខសម្ងាត់ឱ្យគ្រប់!",
                    isError: true,
                  );
                  return;
                }


                setDialogState(() => isSubmitting = true);


                try {
                  final now = DateTime.now();
                  final userRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId);
                  final userDoc = await userRef.get();


                  if (!userDoc.exists) {
                    _showSnackBar(
                      "❌ រកមិនឃើញទិន្នន័យអ្នកប្រើ!",
                      isError: true,
                    );
                    setDialogState(() => isSubmitting = false);
                    return;
                  }


                  final userData = userDoc.data() as Map<String, dynamic>;


                  // 🛡️ ១. ឆែកមើលស្ថានភាព Lock ៥០នាទី
                  if (userData['lock_until'] != null) {
                    DateTime lockUntil =
                    (userData['lock_until'] as Timestamp).toDate();
                    if (now.isBefore(lockUntil)) {
                      int remaining = lockUntil.difference(now).inMinutes;
                      _showSnackBar(
                        "🚫 គណនីត្រូវ Lock! សូមរង់ចាំ $remaining នាទីទៀត",
                        isError: true,
                      );
                      setDialogState(() => isSubmitting = false);
                      return;
                    }
                  }


                  // 🎯 ២. ទាញ Field 'password' មកផ្ទៀងផ្ទាត់ (String)
                  String savedPassword =
                      userData['password']?.toString() ?? "";
                  String inputPassword = pinController.text.trim();
                  int attempts = userData['wrong_attempts'] ?? 0;


                  if (inputPassword == savedPassword) {
                    // ✅ បើត្រូវ៖ Reset ចំនួនដងដែលវាយខុស
                    await userRef.update({
                      'wrong_attempts': 0,
                      'lock_until': null,
                    });


                    // ៣. បន្តការ Upload QR និងបង្កើតបុងដកលុយ
                    String fileName =
                        'khqr/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    Reference ref = FirebaseStorage.instance.ref().child(
                      fileName,
                    );
                    await ref.putFile(selectedQR!);
                    String khqrUrl = await ref.getDownloadURL();


                    await FirebaseFirestore.instance
                        .collection('withdraw_requests')
                        .add({
                      'seller_id': userId,
                      'bank_name': selectedBank,
                      'account_name': accountNameController.text,
                      'account_number': accountNumberController.text,
                      'amount':
                      double.tryParse(_amountController.text) ??
                          0.0,
                      'khqr_url': khqrUrl,
                      'status': 'pending',
                      'created_at': FieldValue.serverTimestamp(),
                    });


                    if (mounted) {
                      Navigator.pop(context); // បិទ Dialog
                      _amountController.clear();
                      _showSnackBar(
                        "✅ លេខសម្ងាត់ត្រឹមត្រូវ! សំណើបានបញ្ជូន។",
                      );
                    }
                  } else {
                    // ❌ បើវាយខុស៖ បូកចំនួនដង (Wrong Attempts)
                    attempts++;
                    if (attempts >= 5) {
                      // Lock ៥០នាទីភ្លាម
                      await userRef.update({
                        'wrong_attempts': attempts,
                        'lock_until': Timestamp.fromDate(
                          now.add(const Duration(minutes: 50)),
                        ),
                      });
                      _showSnackBar(
                        "🚫 វាយខុស ៥ដង! គណនីត្រូវ Lock ៥០នាទី",
                        isError: true,
                      );
                    } else {
                      await userRef.update({'wrong_attempts': attempts});
                      _showSnackBar(
                        "❌ លេខសម្ងាត់មិនត្រឹមត្រូវ! នៅសល់ ${5 - attempts} ដងទៀត",
                        isError: true,
                      );
                    }
                    setDialogState(() => isSubmitting = false);
                  }
                } catch (e) {
                  _showSnackBar("❌ កំហុសបច្ចេកទេស៖ $e", isError: true);
                  setDialogState(() => isSubmitting = false);
                }
              },
              child: isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                "បញ្ជាក់ដកលុយ",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Siemreap',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Siemreap')),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (userId == null)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "ដកប្រាក់ចំណូល",
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text("រកមិនឃើញគណនី"));


          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          _canWithdraw = (data['available_balance'] ?? 0)
              .toDouble(); // ប្រើ available_balance ឱ្យត្រូវតាម Cloud Functions


          return SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // កាតបង្ហាញសមតុល្យ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Color(0xFF1B5E20)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "សមតុល្យដែលអាចដកបាន",
                        style: TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Siemreap',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${currencyFormat.format(_canWithdraw)} ៛",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "ចំនួនទឹកប្រាក់ដែលចង់ដក",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Siemreap',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "0 ៛",
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [50000, 100000, 200000, 500000].map((amount) {
                    return OutlinedButton(
                      onPressed: () =>
                      _amountController.text = amount.toString(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '${currencyFormat.format(amount)} ៛',
                        style: const TextStyle(fontFamily: 'Siemreap'),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      double amount =
                          double.tryParse(_amountController.text) ?? 0;
                      if (amount < 5000) {
                        // កំណត់ឱ្យដកយ៉ាងតិច ៥ពាន់
                        _showSnackBar(
                          "⚠️ ចំនួនដកត្រូវតែចាប់ពី ៥,០០០៛ ឡើងទៅ",
                          isError: true,
                        );
                        return;
                      }
                      if (amount > _canWithdraw) {
                        _showSnackBar(
                          "⚠️ លុយក្នុងកាបូបមិនគ្រប់គ្រាន់ទេ!",
                          isError: true,
                        );
                        return;
                      }
                      _showWithdrawDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "បញ្ជាក់ការដកប្រាក់",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Siemreap',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



