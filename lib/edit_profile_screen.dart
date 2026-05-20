import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/otp_screen.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});


  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}


class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? uid;


  late TextEditingController _nameController;
  late TextEditingController _phoneController;


  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    // ទាញយក UID នៅទីនេះវិញ
    uid = FirebaseAuth.instance.currentUser?.uid;
    _nameController = TextEditingController();
    _phoneController = TextEditingController();


    // បើមាន UID ទើបឱ្យវា Load ទិន្នន័យ
    if (uid != null && uid!.isNotEmpty) {
      _loadUserData();
    } else {
      debugPrint("Error: UID is null or empty");
    }
  }


  void _loadUserData() async {
    if (uid == null || uid!.isEmpty) return; // បើអត់ UID ទេ មិនបាច់ធ្វើការទេ


    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid) // ធានាថា uid នៅទីនេះមិនមែនជាស្ទ្រីងទទេ
          .get();


      if (doc.exists) {
        Map<String, dynamic> data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _currentImageUrl = data['photoUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Load user data error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) setState(() => _imageFile = File(image.path));
  }


  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);


    try {
      String finalImageUrl = _currentImageUrl ?? '';


      // Upload រូបភាព Profile ថ្មីបើមាន
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'profiles/$uid.jpg',
        );
        await storageRef.putFile(_imageFile!);
        finalImageUrl = await storageRef.getDownloadURL();
      }


      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'photoUrl': finalImageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ រក្សាទុកជោគជ័យ"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ បញ្ហា: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // --- ដាក់កូដនេះបន្តពីក្រោម _saveProfile ---


  // ១. មុខងារបង្ហាញផ្ទាំង Dialog ឱ្យគេវាយលេខសម្ងាត់
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKeyDialog = GlobalKey<FormState>();


    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "ប្ដូរលេខសម្ងាត់ ៦ ខ្ទង់",
          style: TextStyle(fontFamily: 'KHMEROS'),
        ),
        content: Form(
          key: formKeyDialog,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogInput(oldPassController, "លេខសម្ងាត់ចាស់"),
              _buildDialogInput(newPassController, "លេខសម្ងាត់ថ្មី"),
              _buildDialogInput(confirmPassController, "បញ្ជាក់លេខថ្មី"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("បោះបង់"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKeyDialog.currentState!.validate()) {
                _updateTransactionPassword(
                  oldPassController.text.trim(),
                  newPassController.text.trim(),
                  confirmPassController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text(
              "រក្សាទុក",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


  // ២. មុខងារផ្ទៀងផ្ទាត់ និង Update ទៅ Firestore
  Future<void> _updateTransactionPassword(
      String oldP,
      String newP,
      String confirmP,
      ) async {
    if (newP != confirmP) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ លេខថ្មីមិនស៊ីគ្នា"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      String currentPass =
          doc.data()?['password'] ?? ''; // ប្រើ field 'password' តាមមេប្រាប់


      if (oldP == currentPass) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'password': newP,
          'lastUpdate': FieldValue.serverTimestamp(),
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ ប្ដូរជោគជ័យ"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ លេខចាស់មិនត្រឹមត្រូវ"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ បញ្ហា: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }


  // Widget ជំនួយសម្រាប់ Input ក្នុង Dialog
  Widget _buildDialogInput(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      obscureText: true,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value!.length < 6 ? "ត្រូវមាន ៦ ខ្ទង់" : null,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "កែប្រែព័ត៌មានផ្ទាល់ខ្លួន",
          style: TextStyle(fontFamily: 'KHMEROS'),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ផ្នែករូបភាព Profile
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_currentImageUrl != null &&
                          _currentImageUrl!.isNotEmpty
                          ? NetworkImage(_currentImageUrl!)
                      as ImageProvider
                          : null),
                      child:
                      (_imageFile == null &&
                          (_currentImageUrl == null ||
                              _currentImageUrl!.isEmpty))
                          ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.green[700],
                        radius: 18,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildInput(_nameController, "ឈ្មោះបង្ហាញ", Icons.person),
              _buildInput(
                _phoneController,
                "លេខទូរស័ព្ទ",
                Icons.phone,
                isNumber: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "រក្សាទុក",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              // --- ក្រោម ElevatedButton "រក្សាទុក" របស់មេ ---
              const SizedBox(height: 20),
              const Divider(),
              OutlinedButton.icon(
                onPressed:
                _showChangePasswordDialog, // ហៅ Logic ដែលយើងទើបដាក់មិញ
                icon: const Icon(Icons.lock_outline),
                label: const Text("ប្ដូរលេខសម្ងាត់ ៦ ខ្ទង់"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                ),
              ),
              const SizedBox(height: 10),
              // ស្វែងរកប៊ូតុង "ភ្លេចលេខសម្ងាត់" ក្នុង build method រួចដាក់កូដនេះចូល
              TextButton(
                onPressed: () async {
                  // ១. យកលេខទូរស័ព្ទដែលភ្ញៀវកំពុងប្រើ
                  String phoneNumber = _phoneController.text.trim();


                  if (phoneNumber.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("សូមមេមេ បំពេញលេខទូរស័ព្ទសិន!"),
                      ),
                    );
                    return;
                  }


                  // បង្ហាញ Loading បន្តិចដើម្បីឱ្យភ្ញៀវដឹងថា App កំពុងផ្ញើសារ
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
                  );


                  // ២. ហៅ Firebase ឱ្យផ្ញើសារ OTP
                  await FirebaseAuth.instance.verifyPhoneNumber(
                    phoneNumber: phoneNumber,
                    verificationCompleted:
                        (PhoneAuthCredential credential) async {
                      // ករណីទូរស័ព្ទខ្លះវាចាប់ OTP ឱ្យស្វ័យប្រវត្តិ
                    },
                    verificationFailed: (FirebaseAuthException e) {
                      Navigator.pop(context); // បិទ Loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("ផ្ញើសារមិនជោគជ័យ៖ ${e.message}"),
                        ),
                      );
                    },
                    codeSent: (String verificationId, int? resendToken) {
                      Navigator.pop(context); // បិទ Loading


                      // ៣. ពេលផ្ញើសារចេញហើយ ទើបយើងរុញទៅ Screen OTP ដោយបោះ ID ពិតទៅឱ្យ
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OTPScreen(
                            verificationId:
                            verificationId, // បោះ ID ពិតពី Firebase
                            name:
                            "ResetPassword", // ដាក់ចំណាំថាទៅលើកនេះគឺដើម្បីដូរ Password
                            phone: phoneNumber,
                            password: "",
                          ),
                        ),
                      );
                    },
                    codeAutoRetrievalTimeout: (String verificationId) {},
                  );
                },
                child: const Text(
                  "ភ្លេចលេខសម្ងាត់? កំណត់ឡើងវិញតាម OTP",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily:
                    'KHMEROS', // ប្រាកដថាប្រើ Font ខ្មែរឱ្យស្អាតដូចក្នុងរូប
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildInput(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isNumber = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green[700]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value!.isEmpty ? "សូមបំពេញ $label" : null,
      ),
    );
  }
}



