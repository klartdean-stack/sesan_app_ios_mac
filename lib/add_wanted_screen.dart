import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // កុំភ្លេច Import មួយនេះ
import 'package:my_app/location_data.dart';
import 'package:path_provider/path_provider.dart';

class AddWantedScreen extends StatefulWidget {
  const AddWantedScreen({super.key});

  @override
  State<AddWantedScreen> createState() => _AddWantedScreenState();
}

class _AddWantedScreenState extends State<AddWantedScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  // 🎯 ដាក់កូដនេះចូល ដើម្បីបាត់ក្រហម
  void _pickLocation() {
    showLocationPicker(context, (value) {
      setState(() {
        _locationController.text = value;
      });
    });
  }

  // Variables
  List<File> _selectedImages = []; // 🎯 បញ្ជីរូបភាពដែលបានជ្រើសរើស
  String _selectedUnit = "គីឡូ";
  String _priceType = "បំពេញតម្លៃ";
  String _currency = "\$";
  bool _isLoading = false;

  final List<String> _units = [
    "គ្រាប់",
    "គ្រឿង",
    "គីឡូ",
    "តោន",
    "បាវ",
    "ដើម",
    "...",
  ];

  // 🎯 ១. មុខងារបង្រួមរូបភាព (Compress)
  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path =
        "${tempDir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      path,
      quality: 60, // បង្រួមសល់ ៦០%
    );
    return result != null ? File(result.path) : null;
  }

  // 🎯 ២. មុខងាររើសរូប (កំណត់ត្រឹម ៣ សន្លឹក)
  Future<void> _pickImages() async {
    final List<XFile> images = await ImagePicker().pickMultiImage();

    if (images.isNotEmpty) {
      if ((_selectedImages.length + images.length) > 3) {
        // បង្ហាញការព្រមានបើលើស ៣ សន្លឹក
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ជ្រើសរើសបានត្រឹមតែ ៣ សន្លឹកប៉ុណ្ណោះ!")),
        );
      } else {
        setState(() {
          _selectedImages.addAll(images.map((x) => File(x.path)).toList());
        });
      }
    }
  }

  // 🎯 ៣. មុខងារ Upload (បង្រួមរូបសិន ទើបបង្ហោះ)
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("សូមបំពេញព័ត៌មាន និងដាក់រូបភាពយ៉ាងហោច ១ សន្លឹក"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    List<String> imageUrls = [];

    try {
      // លូកបង្រួម និងបង្ហោះរូបម្តងមួយៗ
      for (File img in _selectedImages) {
        File? smallImg = await _compressImage(img); // 🎯 បង្រួមរូបនៅទីនេះ
        if (smallImg != null) {
          String fileName =
              "${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(img)}.jpg";
          Reference ref = FirebaseStorage.instance.ref().child(
            'wanted_images/$fileName',
          );
          await ref.putFile(smallImg); // បង្ហោះរូបដែលបង្រួមរួច
          String url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      // រក្សាទុកក្នុង Firestore
      await FirebaseFirestore.instance.collection('wanted_products').add({
        'productName': _nameController.text.trim(),
        'quantity': _qtyController.text.trim(),
        'unit': _selectedUnit,
        'priceType': _priceType,
        'price': _priceType == "ចរចារ" ? "ចរចារ" :
        _priceController.text.trim(),
        'currency': _currency,
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'imageUrls': imageUrls, // រក្សាទុកជា List នៃ URL
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ប្រកាសទិញត្រូវបានចុះផ្សាយ")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("កំហុស៖ $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "បង្កើតការប្រកាសទិញ",
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
              // --- កន្លែងរើសរូបភាព (បង្ហាញរូបដែលរើសរួច) ---
              const Text(
              "រូបភាពទំនិញត្រូវការទិញ (អតិបរមា ៣ សន្លឹក) *",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
                spacing: 10,
                children: [
                ..._selectedImages
                .map(
                (img) => Stack(
        children: [
        ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          img,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: GestureDetector(
          onTap: () => setState(
                () => _selectedImages.remove(img),
          ),
          child: const Icon(
            Icons.cancel,
            color: Colors.red,
          ),
        ),
      ),
      ],
    ),
    )
        .toList(),
    if (_selectedImages.length < 3)
    GestureDetector(
    // 🎯 កន្លែងនេះ៖ បើគ្រប់ ៣ ហើយ ឱ្យវាទៅជា null (ចុចលែងកើត)
    onTap: _selectedImages.length >= 3
    ? null
        : _pickImages,
    child: Container(
    height: 180,
    width: double.infinity,
    decoration: BoxDecoration(
    // 🎯 ប្តូរពណ៌៖ បើគ្រប់ ៣ ឱ្យវាចេញពណ៌ប្រផេះ (Grey)
    color: _selectedImages.length >= 3
    ? Colors.grey[300]
        : Colors.grey[200],
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[400]!),
    ),
    child: _selectedImages.isEmpty
        ? const Column(
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 40),
        Text("ដាក់រូបភាព (អតិបរមា ៣សន្លឹក)"),
      ],
    )
        : ClipRRect(
      borderRadius: BorderRadius.circular(12),
      // បង្ហាញរូបទី ១ ដែលបានរើស
      child: Image.file(
        _selectedImages[0],
        fit: BoxFit.cover,
      ),
    ),
    ),
    ),
                ],
            ),
            const SizedBox(height: 20),

            // --- ឈ្មោះទំនិញ ---
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "ឈ្មោះទំនិញ",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "សូមបញ្ចូលឈ្មោះ" : null,
            ),

            const SizedBox(height: 15),

            // --- ចំនួន និង ឯកតា ---
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "ចំនួនត្រូវការ",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _units
                        .map(
                          (u) => DropdownMenuItem(
                        value: u,
                        child: Text(u),
                      ),
                    )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedUnit = v.toString()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // --- ជម្រើសតម្លៃ ---
            const Text(
              "តម្លៃរំពឹងទុក៖",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Radio(
                  value: "បំពេញតម្លៃ",
                  groupValue: _priceType,
                  onChanged: (v) =>
                      setState(() => _priceType = v.toString()),
                ),
                const Text("បំពេញ"),
                Radio(
                  value: "ចរចារ",
                  groupValue: _priceType,
                  onChanged: (v) =>
                      setState(() => _priceType = v.toString()),
                ),
                const Text("ចរចារ"),
              ],
            ),

            if (_priceType == "បំពេញតម្លៃ")
        Row(
      children: [
      Expanded(
      child: TextFormField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "តម្លៃ",
          border: OutlineInputBorder(),
        ),
      ),
    ),
    const SizedBox(width: 10),
    ToggleButtons(
    isSelected: [_currency == "\$", _currency == "៛"],
    onPressed: (index) => setState(
    () => _currency = index == 0 ? "\$" : "៛",
    ),
    borderRadius: BorderRadius.circular(8),
    children: const [
    Padding(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: Text("\$"),
    ),
    Padding(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: Text("៛"),
    ),
    ],
    ),
    ],
    ),

    const SizedBox(height: 15),

    // --- លេខទូរស័ព្ទ និង ទីតាំង ---
    TextFormField(
    controller: _phoneController,
    keyboardType: TextInputType.phone,
    decoration: const InputDecoration(
    labelText: "លេខទូរស័ព្ទ",
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.phone),
    ),
    ),
    const Text(
    "ទីតាំងត្រូវការទិញ *",
    style: TextStyle(fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 10),
    InkWell(
    onTap: _pickLocation, // 🎯 ហៅមុខងាររើសទីតាំង
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 15,
    ),
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.grey.shade400),
    ),
    child: Row(
    children: [
    const Icon(
    Icons.location_city,
    color: Colors.green,
    size: 20,
    ),
    const SizedBox(width: 8),
    Expanded(
    child: Text(
    _locationController.text.isEmpty
    ? "ជ្រើសរើសខេត្ត *"
        : _locationController.text,
    style: TextStyle(
    fontSize: 15,
    color: _locationController.text.isEmpty
    ? Colors.grey
        : Colors.black,
    ),
    ),
    ),
    const Icon(
    Icons.arrow_drop_down,
    color: Colors.grey,
    ),
    ],
    ),
    ),
    ),
                    const Text(
                      "រៀបរាប់បន្ថែម (ទិញយកទៅធ្វើអ្វី/លក្ខខណ្ឌផ្សេងៗ) *",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4, // ឱ្យវាចេញ ៤ ជួរដើម្បីងាយស្រួលសរសេរវែង
                  decoration: InputDecoration(
                    hintText:
                    "ឧទាហរណ៍៖ ត្រូវការទិញយកទៅប្រើប្រាស់ផ្ទាល់ខ្លួន ចង់បានរបស់នៅស្អាត មិនទាន់ជួសជុល...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (v) =>
                  v!.isEmpty ? "សូមបំពេញការរៀបរាប់ខ្លះៗ" : null,
                ),

                const SizedBox(height: 30),

                // --- ប៊ូតុងផ្ញើ ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "ចុះផ្សាយប្រកាសទិញ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Siemreap',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
        ),
      ),
    );
  }
}
    // --- ប្រឡោះរៀបរាប់លម្អិត