import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:my_app/download_helper.dart';
import 'order_service.dart';
import 'telegram_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_data.dart';
import 'vireak_buntham_data.dart'; // ហៅបញ្ជីមកប្រើ

class ReceiptScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartDocs;

  const ReceiptScreen({super.key, required this.cartDocs});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  File? _paymentImage;
  bool _isProcessing = false;
  String? _currentOrderId = null; // សម្រាប់តាមដាន Status
  bool isVireakBuntham = false;
  String? selectedVireakBranch;
  // Controller សម្រាប់ព័ត៌មានដឹកជញ្ជូន
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? selectedProvince;
  String? selectedDistrict;
  String? selectedCommune;

  final User? currentUser = FirebaseAuth.instance.currentUser;
  Future<void> _loadSavedCustomerData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // ១. ទាញឈ្មោះ៖ បើគ្មានក្នុង Preference ឱ្យយកពី Profile Firebase
      _nameController.text =
          prefs.getString('saved_name') ?? (currentUser?.displayName ?? "");

      // ២. ទាញលេខទូរស័ព្ទ៖ បើគ្មានក្នុង Preference ឱ្យយកពី Profile Firebase
      _phoneController.text =
          prefs.getString('saved_phone') ?? (currentUser?.phoneNumber ?? "");

      // ៣. ទាញអាសយដ្ឋាន៖ បើធ្លាប់មានទិន្នន័យចាស់ វានឹងបំពេញឱ្យអូតូ
      if (prefs.getString('saved_address') != null) {
        _addressController.text = prefs.getString('saved_address')!;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCustomerData();
    // បំពេញឈ្មោះ និងលេខទូរស័ព្ទអូតូ បើមានក្នុង Profile
    _nameController.text = currentUser?.displayName ?? "";
    _phoneController.text = currentUser?.phoneNumber ?? "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose(); // បន្ថែមជួរនេះដើម្បីបំបាត់ក្រហម
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) setState(() => _paymentImage = File(image.path));
  }

  Future<void> _confirmOrder() async {
    // ១. ប្រកាសថា App កំពុងដើរភ្លាមៗពេលចុច ដើម្បីទប់កុំឱ្យចុចលើកទី២បាន
    if (_isProcessing) return; // បើកំពុងដើរ មិនឱ្យធ្វើការងារខាងក្រោមទេ

    // ២. ឆែកលក្ខខណ្ឌចាំបាច់មុនគេបង្អស់
    bool isLocationSelected =
        selectedProvince != null &&
        (isVireakBuntham
            ? selectedVireakBranch != null
            : selectedDistrict != null);
    bool isAddressTyped = _addressController.text.trim().isNotEmpty;

    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _showSnackBar("សូមបំពេញឈ្មោះ និងលេខទូរស័ព្ទ!");
      return;
    }

    if (!isLocationSelected && !isAddressTyped) {
      _showSnackBar("សូមជ្រើសរើសទីតាំង ឬបំពេញអាសយដ្ឋានដឹកជញ្ជូន!");
      return;
    }

    if (_paymentImage == null) {
      _showSnackBar("សូមជ្រើសរើសរូបភាពប្លង់ផ្ទេរលុយសិន!");
      return;
    }

    // ៣. បើលក្ខខណ្ឌត្រឹមត្រូវអស់ហើយ ចាប់ផ្ដើមស្ទះប៊ូតុង (Loading)
    setState(() => _isProcessing = true);

    try {
      // រៀបចំ Address
      String locationInfo = isVireakBuntham
          ? "ផ្ញើតាមវិរៈ (សាខា: $selectedVireakBranch)"
          : "ស្រុក: ${selectedDistrict ?? ''}";
      String finalAddress =
          "$selectedProvince, $locationInfo, ${_addressController.text}".trim();

      // រក្សាទុកទិន្នន័យទៅ SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_name', _nameController.text);
      await prefs.setString('saved_phone', _phoneController.text);
      await prefs.setString('saved_address', _addressController.text);

      double exactTotal = 0.0;

      // ៤. រៀបចំបញ្ជីទំនិញ
      List<Map<String, dynamic>> cartItems = widget.cartDocs.map((doc) {
        double price =
            double.tryParse(doc['price'].toString().replaceAll(',', '')) ?? 0.0;
        int quantity = int.tryParse(doc['quantity'].toString()) ?? 1;
        exactTotal += (price * quantity);

        return {
          'product_name': doc['product_name'] ?? 'គ្មានឈ្មោះ',
          'price': price,
          'quantity': quantity,
          'order_date': FieldValue.serverTimestamp(),
          'seller_id': doc.data().toString().contains('seller_id')
              ? doc['seller_id']
              : 'UNKNOWN_ID',
          'seller_phone': doc.data().toString().contains('seller_phone')
              ? doc['seller_phone']
              : "គ្មានលេខទូរស័ព្ទ",
          'image_url': doc.data().toString().contains('image_url')
              ? doc['image_url']
              : "",
        };
      }).toList();

      // ៥. Upload រូបភាព (ចំណុចនេះយូរជាងគេ ទើបធ្វើឱ្យមេមានអារម្មណ៍ថាស្ពឹក)
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      var storageRef = FirebaseStorage.instance.ref().child(
        'payments/$fileName.jpg',
      );
      await storageRef.putFile(_paymentImage!);
      String paymentImageUrl = await storageRef.getDownloadURL();

      // ៦. បង្កើត Order (បាញ់ទៅ Firebase)
      OrderService orderService = OrderService();
      bool success = await orderService.createOrder(
        cartItems: cartItems,
        totalAmount: exactTotal,
        customerId: currentUser?.uid ?? 'GUEST',
        customerName: _nameController.text,
        phoneNumber: _phoneController.text,
        shippingAddress: finalAddress,
        paymentImage: paymentImageUrl,
      );

      if (success) {
        // ៧. ផ្ញើសារទៅ Telegram
        String telegramMsg =
            "🔔 *មានការកុម្ម៉ង់ថ្មី (Pending)*\n\n👤 ភ្ញៀវ៖ ${_nameController.text}\n💰 សរុប៖ ${exactTotal.toStringAsFixed(0)} ៛\n🖼 ប្លង់៖ $paymentImageUrl";
        await TelegramService.sendMessage(telegramMsg);

        // ៨. សម្អាតកន្ត្រក
        await orderService.clearCart(currentUser?.uid ?? 'GUEST');

        // បង្ហាញ Dialog ជោគជ័យ
        _showSuccessWaitingDialog();
      } else {
        _showSnackBar("ការបង្កើត Order មានបញ្ហា!");
      }
    } catch (e) {
      _showSnackBar("មានបញ្ហា៖ $e");
    } finally {
      // ៩. បញ្ចប់ការដំណើរការ (បើ Error វានឹងបើកប៊ូតុងឱ្យចុចវិញ)
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "ការកុម្ម៉ង់ជោគជ័យ!",
          style: TextStyle(fontFamily: 'KHMEROS'),
        ),
        content: const Text(
          "ការរបស់បងកម្មង់រួចរាល់ រងចាំការបញ្ជាក់ទទួលប្រាក់ បងអាចត្រលប់ទៅផ្ទាំងដើមបាន។",
          style: TextStyle(fontFamily: 'KHMEROS'),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text("ត្រឡប់ទៅផ្ទាំងដើម"),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 🎯 ១. ដាក់មុខងារនេះនៅខាងលើ Widget build
  Widget _buildLocationDropdowns() {
    return Column(
      children: [
        // រើសខេត្ត
        DropdownButtonFormField<String>(
          value: selectedProvince,
          decoration: const InputDecoration(
            labelText: "ជ្រើសរើសខេត្ត/ក្រុង",
            prefixIcon: Icon(Icons.map_outlined),
            border: OutlineInputBorder(),
          ),
          items: cambodiaProvinceData.keys.map((String province) {
            return DropdownMenuItem(value: province, child: Text(province));
          }).toList(),
          onChanged: (val) {
            setState(() {
              selectedProvince = val;
              selectedDistrict = null;
              selectedVireakBranch = null; // Reset ពេលដូរខេត្ត
            });
          },
        ),

        const SizedBox(height: 10),

        // 🟢 ថែមត្រង់នេះ៖ ប៊ូតុង Switch សម្រាប់បើកសេវាវិរៈ
        SwitchListTile(
          title: const Text(
            "ផ្ញើតាមវិរៈប៊ុនថាំ (Vireak Buntham)",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          secondary: const Icon(Icons.directions_bus, color: Colors.red),
          value: isVireakBuntham,
          onChanged: (bool value) {
            setState(() {
              isVireakBuntham = value;
              selectedDistrict = null;
              selectedVireakBranch = null;
            });
          },
        ),

        if (selectedProvince != null) ...[
          const SizedBox(height: 10),
          // បើបើក Switch ឱ្យរើសសាខា បើបិទឱ្យរើសស្រុកធម្មតា
          isVireakBuntham
              ? DropdownButtonFormField<String>(
                  value: selectedVireakBranch,
                  decoration: const InputDecoration(
                    labelText: "ជ្រើសរើសសាខាវិរៈប៊ុនថាំ",
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    border: OutlineInputBorder(),
                  ),
                  // 🟢 ប្រើឈ្មោះ Class ចុច ឈ្មោះ variable (VETData.branches)
                  // 🟢 កែត្រង់ items ឱ្យទៅជាបែបនេះវិញ
                  items: (VETData.branches[selectedProvince] ?? []).map((
                    branchName,
                  ) {
                    // ប្តូរពី branchMap មកជា branchName វិញ
                    return DropdownMenuItem<String>(
                      value: branchName, // ដាក់ឈ្មោះសាខាដែលជា String ចូលតែម្តង
                      child: Text(
                        branchName,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => selectedVireakBranch = val),
                )
              : DropdownButtonFormField<String>(
                  value: selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: "ជ្រើសរើសស្រុក/ខណ្ឌ",
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  items: cambodiaProvinceData[selectedProvince!]!.map((
                    district,
                  ) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedDistrict = val),
                ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = 0.0;
    for (var doc in widget.cartDocs) {
      total +=
          double.tryParse(doc['price'].toString().replaceAll(',', '')) ?? 0.0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ទូទាត់ប្រាក់"),
        backgroundColor: Colors.green[700],
      ),
      body: // _currentOrderId == null
      _buildOrderForm(
        total,
      ),
    );
  }

  // ១. បង្កើត Function សម្រាប់បើក Link ABA (ដាក់ខាងលើ build widget)
  Future<void> _launchABA() async {
    final Uri _url = Uri.parse('https://pay.ababank.com/oRF8/lq8jgwzb');
    try {
      await launchUrl(_url, mode: LaunchMode.externalApplication);
    } catch (e) {
      await launchUrl(_url, mode: LaunchMode.platformDefault);
    }
  }

  // ២. បង្កើត Function សម្រាប់ថតរូប ឬរើសរូប (សម្រាប់ប្រអប់ Square)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _paymentImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- ចាប់ផ្ដើមប្លុកកូដដែលមេត្រូវការ ---

  // ផ្ទាំងសម្រាប់បំពេញព័ត៌មាន និងបង់ប្រាក់
  Widget _buildOrderForm(double total) {
    // បង្កើតអថេរសម្រាប់អត្ថបទជំនួយ (Hint)
    String addressHint = (selectedProvince != null && selectedDistrict != null)
        ? "មិនបាច់បំពេញក៏បាន ព្រោះអ្នកបានរើសទីតាំងខាងលើរួចហើយ ឬចង់សរសេរបញ្ជាក់បន្ថែម (លេខផ្ទះ/ផ្លូវ)"
        : "អាសយដ្ឋានដឹកជញ្ជូនលម្អិត (ផ្ទះលេខ/ផ្លូវ/ភូមិ)";
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInput("ឈ្មោះអ្នកទទួល", _nameController, Icons.person),
          _buildInput(
            "លេខទូរស័ព្ទ",
            _phoneController,
            Icons.phone,
            inputType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _buildLocationDropdowns(),

          const SizedBox(height: 10),
          _buildInput(
            addressHint,
            _addressController,
            Icons.location_on,
            maxLines: 2,
          ),
          // 🎯 ថែមប៊ូតុងនេះ ដើម្បីឱ្យភ្ញៀវដឹងថាថ្ងៃក្រោយអាចរើសលើ Map បាន
          OutlinedButton.icon(
            onPressed: () => _showSnackBar("មុខងាររើសលើផែនទី កំពុងរៀបចំ..."),
            icon: const Icon(Icons.map, color: Colors.green),
            label: const Text(
              "រើសទីតាំងលើផែនទី (Coming Soon)",
              style: TextStyle(color: Colors.green),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.green),
            ),
          ),
          const Divider(height: 40),
          const Text(
            "ស្កេនបង់ប្រាក់មកកាន់ QR នេះ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // មុខងារចុចសង្កត់ (Long Press) ដើម្បី Save រូបភាព
          GestureDetector(
            onLongPress: () async {
              try {
                // ១. បង្ហាញ SnackBar ប្រាប់ថា App កំពុងដំណើរការ
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("⌛ កំពុងរក្សាទុករូបភាពទៅក្នុង Gallery..."),
                    duration: Duration(seconds: 2),
                  ),
                );
                // ២. ហៅ Helper ដើម្បី Save រូបភាព (ប្រើ Link ABA របស់មេ)
                // ចំណាំ៖ ត្រូវប្រាកដថា Link នេះបើកមើលរូបភាព QR បានតាម Browser
                await DownloadHelper.saveQRImage(
                  "https://firebasestorage.googleapis.com/v0/b/sesan-my-app.firebasestorage.app/o/20260308_163835.jpg?alt=media&token=95922392-ed40-4483-9097-899987ad06e8",
                );

                // ៣. បង្ហាញ SnackBar ពណ៌បៃតងពេលជោគជ័យ
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ រក្សាទុកក្នុង Gallery រួចរាល់!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // ៤. បង្ហាញ SnackBar ពណ៌ក្រហមបើមាន Error
                debugPrint("Save Error: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("❌ បរាជ័យក្នុងការរក្សាទុក: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Image.asset(
              "assets/aba_qr.png", // រូបភាពដែលបង្ហាញលើអេក្រង់
              height: 150,
              errorBuilder: (c, e, s) => const Icon(Icons.qr_code, size: 80),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${total.toStringAsFixed(0)} ៛",
            style: const TextStyle(
              fontSize: 24,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // ប៊ូតុងចុចបើក App ABA ផ្ទាល់
          ElevatedButton.icon(
            onPressed: _launchABA,
            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
            label: const Text(
              "ចុចដើម្បីបង់ប្រាក់តាម App ABA",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005D7E),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 15),
          const Text(
            "បញ្ជាក់៖ បង់ប្រាក់រួច សូមថតរូបវិក្កយបត្របញ្ចូលខាងក្រោម (ចុចសង្កត់លើ QR ដើម្បីរក្សាទុកក្នុង Gallery)",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // ប្រអប់បញ្ចូលវិក្កយបត្រ រាងការ៉េ (Square)
          Center(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  // បន្ថែមរាងមូលនៅជ្រុងខាងលើឱ្យមើលទៅទំនើប
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Center(
                            child: Text(
                              "ជ្រើសរើសរូបភាពវិក្កយបត្រ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.camera_alt,
                            color: Colors.green,
                          ),
                          title: const Text('ថតរូបវិក្កយបត្រ (Camera)'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.photo_library,
                            color: Colors.blue,
                          ),
                          title: const Text('ជ្រើសរើសពីអាល់ប៊ុម (Gallery)'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 180, // ទំហំតូចល្មមស្អាតតាមមេចង់បាន
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  // បន្ថែមស្រមោលតិចៗឱ្យមើលទៅលេចចេញពីផ្ទៃ Background
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: _paymentImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 50, // កែទំហំ Icon ឱ្យសមជាមួយប្រអប់ ១៨០
                            color: Colors.green[700],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "ដាក់រូបវិក្កយបត្រ",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(
                          _paymentImage!,
                          // 🎯 ប្រើ contain ដើម្បីឱ្យឃើញរូបទាំងមូល មិនបាត់ចំនួនលុយ
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isProcessing ? null : _confirmOrder,
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "បញ្ជាក់ការកុម្ម៉ង់",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ផ្ទាំង "រង់ចាំការបញ្ជាក់" (StreamBuilder តាមដាន status ពី Admin)
  Widget _buildWaitingScreen() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(_currentOrderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var orderData = snapshot.data!.data() as Map<String, dynamic>;
        String status = orderData['status'] ?? 'pending';

        // --- ថែមជួរនេះដើម្បីទាញយកម៉ោងមកបង្ហាញភ្ញៀវ ---
        Timestamp? time = orderData['order_date'] as Timestamp?;
        String formattedDate = time != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(time.toDate())
            : '';

        if (status == 'confirmed') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 100),
                const SizedBox(height: 20),
                const Text(
                  "ការកុម្ម៉ង់បានជោគជ័យ!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "សូមអរគុណសម្រាប់ការគាំទ្រ!! យើងខ្ញុំកំពុងរៀបចំខ្ចប់ និងដឹកអីវ៉ាន់ជូនលោកអ្នក។",
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: const Text("ត្រឡប់ទៅហាងវិញ"),
                ),
              ],
            ),
          );
        }

        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "កំពុងរង់ចាំការបញ្ជាក់ទទួលប្រាក់...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Admin កំពុងពិនិត្យមើលវិក្កយបត្ររបស់អ្នក សូមកុំបិទផ្ទាំងនេះ!",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput(
    String hint,
    TextEditingController controller,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
