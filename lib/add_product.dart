import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:my_app/map_picker_screen.dart';
import 'package:my_app/upload_controller.dart';
import 'dart:io';
import 'main.dart'; // ដើម្បីឱ្យវាស្គាល់ navigatorKey
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ថែមជួរនេះចូលមេ!
import 'auction_add_screen.dart';
import 'location_data.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

class AddProductPage extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? initialData;

  const AddProductPage({super.key, this.productId, this.initialData});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // --- Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController phone1Controller = TextEditingController();
  final TextEditingController phone2Controller = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  double? selectedLat;
  double? selectedLng;

  // --- Media Variables ---
  List<XFile> selectedImages = [];
  XFile? selectedVideo;
  final ImagePicker _picker = ImagePicker();
  final formatter = NumberFormat('#,###');
  final UploadController uploadController = Get.put(UploadController());

  String? selectedCategory;
  String selectedCurrency = '៛';
  List<String> categories = [
    'គ្រឿងចក្រ',
    'សម្ភារៈកសិកម្ម',
    'ពូជដំណាំ',
    'ពូជសត្វចិញ្ចឹម',
    'ជីនិងថ្នាំ',
    'បន្លែផ្លែឈើ',
    'ត្រីសាច់',
    'សេវាកម្ម',
    'ផ្សេងៗ',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      nameController.text = widget.initialData!['product_name'] ?? '';
      descriptionController.text = widget.initialData!['description'] ?? '';
      priceController.text = widget.initialData!['price']?.toString() ?? '';
      phone1Controller.text = widget.initialData!['phone1'] ?? '';
      phone2Controller.text = widget.initialData!['phone2'] ?? '';
      locationController.text = widget.initialData!['location'] ?? '';
      selectedCategory = widget.initialData!['category'];
      selectedCurrency = widget.initialData!['currency'] ?? '\$';
    }
  }

  Future<void> pickManyImages() async {
    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      List<XFile> allPicked = [...selectedImages, ...images];

      if (allPicked.length > 10) {
        // 🎯 កាត់យកត្រឹមតែ ១០ សន្លឹកដំបូងគត់
        setState(() {
          selectedImages = allPicked.sublist(0, 10);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('យើងកាត់យកត្រឹម ១០ សន្លឹកដំបូងជូនមេ!')),
        );
      } else {
        setState(() {
          selectedImages = allPicked;
        });
      }
    }
  }

  Future<void> pickVideo() async {
    // 🎯 ប្រើឈ្មោះ pickVideo ឱ្យដូចកូដចាស់មេ
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60), // កែជា ៦០ វិនាទីតាមមេចង់បាន
    );

    if (video != null) {
      // 🎯 ឆែកឱ្យច្បាស់ ១០០% បើលើស ៦០ វិនាទី គឺមិនយកដាច់ខាត
      final info = await VideoCompress.getMediaInfo(video.path);
      if (info.duration != null && info.duration! > 61000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('វីដេអូមិនអាចលើសពី ៦០ វិនាទីឡើយ!')),
        );
        return;
      }
      setState(() => selectedVideo = video);
    }
  }

  // --- មុខងារបង្រួមរូបភាព (កែសម្រួលឱ្យកាន់តែសុវត្ថិភាព និងច្បាស់ល្អ) ---
  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;

      // 🎯 រកចំណុច (.) ចុងក្រោយគេបង្អស់ ដើម្បីកាត់ឈ្មោះ File ឱ្យត្រូវគ្រប់ប្រភេទ (png, jpg, heic)
      final lastIndex = filePath.lastIndexOf('.');

      // បង្កើត Path ថ្មីសម្រាប់រក្សាទុក File ដែលបង្រួមរួច
      final outPath = "${filePath.substring(0, lastIndex)}_compressed.jpg";

      // ចាប់ផ្ដើមបង្រួមរូបភាព
      var result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 70, // បង្រួមសល់ ៧០% (ទំហំស្រាលខ្លាំង តែនៅតែច្បាស់ភ្នែក)
        minWidth: 1024, // កម្រិតទទឹងសមល្មមសម្រាប់បង្ហាញលើ App
        minHeight: 1024, // កម្រិតកម្ពស់សមល្មម
        format: CompressFormat
            .jpeg, // 🎯 បង្ខំឱ្យទៅជា JPEG ដើម្បីឱ្យ Firebase ងាយអាន
      );

      if (result == null) return null;

      return File(result.path);
    } catch (e) {
      // បើមានបញ្ហាពេលបង្រួម ឱ្យវាប្រើ File ដើមសិន ដើម្បីកុំឱ្យគាំងការបង្ហោះ
      return file;
    }
  }

  Future<File?> _compressVideo(File file) async {
    try {
      print("--- ចាប់ផ្ដើមបង្រួមវីដេអូ ---");
      print("ទំហំដើម៖ ${file.lengthSync() / (1024 * 1024)} MB");

      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality
            .LowQuality, // 🎯 បង្ខំឱ្យយក LowQuality (សន្សំទំហំបានច្រើនបំផុត)
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        print(
          "បង្រួមរួចរាល់! ទំហំថ្មី៖ ${info.file!.lengthSync() / (1024 * 1024)} MB",
        );
        return info.file;
      }
    } catch (e) {
      print("កំហុសពេលបង្រួម៖ $e");
      VideoCompress.cancelCompression();
    }
    return null;
  }

  // --- នេះជាមុខងារ _uploadToStorage ដែលកែសម្រួលរួច (ផាសជួសកន្លែងចាស់) ---
  Future<String> _uploadToStorage(File file, String folder) async {
    File fileToUpload = file;

    // បើជារូបភាព ឱ្យវាបង្រួមសិន
    if (folder.contains('images')) {
      File? compressed = await _compressImage(file);
      if (compressed != null) {
        fileToUpload = compressed;
      }
    } else if (folder.contains('videos')) {
      File? compressed = await _compressVideo(file);

      if (compressed != null) {
        // 🎯 ឆែកមើល៖ បើ File ដែលបង្រួមហើយ បែរជាធំជាង File ដើម ឱ្យយក File ដើមវិញ
        if (compressed.lengthSync() > file.lengthSync()) {
          fileToUpload = file;
          print("យក File ដើមវិញ ព្រោះការបង្រួមធ្វើឱ្យឡើងទំហំ");
        } else {
          fileToUpload = compressed;
          print("យក File ដែលបង្រួមរួចទៅ Upload");
        }

        // ឆែកប្រវែងវីដេអូក្រោម ៦០ វិនាទី
        final info = await VideoCompress.getMediaInfo(fileToUpload.path);
        if (info.duration != null && info.duration! > 60000) {
          throw "វីដេអូវែងពេក! សូមជ្រើសរើសវីដេអូក្រោម ៦០ វិនាទី។";
        }
      }
    }

    String fileExtension = fileToUpload.path.split('.').last;
    String fileName =
        "${DateTime.now().millisecondsSinceEpoch}_${fileToUpload.path.split('/').last}";
    Reference ref = FirebaseStorage.instance
        .ref()
        .child(folder)
        .child(fileName);

    SettableMetadata metadata = SettableMetadata(
      contentType: folder.contains('videos')
          ? 'video/$fileExtension'
          : 'image/$fileExtension',
    );

    UploadTask uploadTask = ref.putFile(fileToUpload, metadata);
    TaskSnapshot snapshot = await uploadTask;

    if (folder.contains('videos')) await VideoCompress.deleteAllCache();

    return await snapshot.ref.getDownloadURL();
  }

  // --- ផាសជំនួសមុខងារ _uploadProduct ចាស់ដោយកូដខាងក្រោមនេះ ---

  // បន្ថែមមុខងារនេះនៅខាងក្រោម _uploadProduct (ក្រៅសញ្ញាដង្កៀប)
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('បញ្ហាបង្ហោះ'),
        content: Text('មិនអាចបង្ហោះបានទេ ដោយសារ៖ $message'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('យល់ព្រម'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productId != null ? 'កែប្រែទំនិញ' : 'បន្ថែមទំនិញថ្មី',
        ),
        backgroundColor: Colors.green,
        // 🎯 ដាក់ក្នុង actions: [] របស់ AppBar ក្នុងទំព័រ Add Product
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionAddScreen
                      (),
                  ),
                ); // 🎯 ដាក់ Navigator ទៅកាន់ទំព័រ Request Exhibition របស់មេនៅទីនេះ
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  // ✨ ពណ៌មាសដេញ (Gold Gradient) ឱ្យមើលទៅមានតម្លៃ
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.stars_rounded, color: Colors.black, size: 18),
                    SizedBox(width: 4),
                    Text(
                      "ស្នើសុំពិព័រណ៍",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        fontFamily: 'Siemreap',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMediaButton(
              onTap: () {
                if (selectedImages.length < 10) {
                  pickManyImages();
                }
              },
              icon: Icons.collections,
              label: selectedImages.length >= 10
                  ? "រូបភាពគ្រប់ចំនួនហើយ (១០/១០)"
                  : "រើសរូបភាព (${selectedImages.length}/10)",
              // 🎯 កែពណ៌ឱ្យទៅជាប្រផេះ បើគ្រប់ ១០ សន្លឹក
              color: selectedImages.length >= 10
                  ? Colors.grey.shade300
                  : Colors.blue.shade50,
              textColor: selectedImages.length >= 10
                  ? Colors.grey
                  : Colors.blue,
            ),
            const SizedBox(height: 10),

            // បង្ហាញរូបភាព Preview
            if (selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(selectedImages[index].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            // កែជួរ ៤៣២
                            onTap: selectedImages.length >= 10
                                ? null
                                : () => pickManyImages(),
                            child: const Icon(Icons.cancel, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 15),

            // ប៊ូតុងរើសវីដេអូ
            _buildMediaButton(
              // កែជួរ ៤៨៧
              onTap: () => pickVideo(),
              icon: Icons.video_library,
              label: selectedVideo == null
                  ? "រើសវីដេអូបង្ហាញទំនិញ"
                  : "រើសវីដេអូរួចរាល់ ✅",
              color: Colors.orange.shade50,
              textColor: Colors.orange,
            ),

            const SizedBox(height: 20),
            _buildTextField('ឈ្មោះទំនិញ *', Icons.shopping_bag, nameController),
            const SizedBox(height: 10),
            _buildCategoryDropdown(),
            const SizedBox(height: 10),
            _buildPriceSection(),
            const SizedBox(height: 10),
            _buildTextField(
              'បរិយាយទំនិញ',
              Icons.description,
              descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            _buildPhoneSection(),
            const SizedBox(height: 10),
            // --- ចំណុចចាប់ផ្ដើម៖ ផាសជំនួស InkWell ចាស់របស់មេត្រឹមនេះ ---
            Row(
              children: [
                // ១. ប៊ូតុងរើសឈ្មោះខេត្ត (ប្រើកូដចាស់ដែលមេមានស្រាប់)
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () {
                      showLocationPicker(context, (value) {
                        setState(() {
                          locationController.text = value;
                        });
                      });
                    },
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
                              locationController.text.isEmpty
                                  ? "ជ្រើសរើសខេត្ត *"
                                  : locationController.text,
                              style: TextStyle(
                                fontSize: 15,
                                color: locationController.text.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ២. ប៊ូតុងថ្មីសម្រាប់បើកផែនទី (MapPickerScreen)
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () async {
                      // ហៅទៅកាន់ File ផែនទីដែលមេបង្កើតរួចមិញ
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapPickerScreen(),
                        ),
                      );

                      // បើរើសទីតាំងរួច វានឹងយកកូអរដោនេមកទុកក្នុង variable
                      if (result != null) {
                        setState(() {
                          selectedLat = result.latitude;
                          selectedLng = result.longitude;
                        });
                        // បង្ហាញសារប្រាប់មេថាដៅជាប់ហើយ
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("📍 បានដៅទីតាំងលើផែនទីជោគជ័យ!"),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        // បើដៅរួចចេញពណ៌ខៀវស្រាល បើមិនទាន់ដៅចេញពណ៌ប្រផេះ
                        color: selectedLat != null
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedLat != null
                              ? Colors.blue
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: Icon(
                        selectedLat != null
                            ? Icons.location_on
                            : Icons.map_outlined,
                        color: selectedLat != null ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // --- ចប់ផ្នែក Row ទីតាំង ---
            const SizedBox(height: 25),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                // ១. ឆែកលក្ខខណ្ឌចាំបាច់ (Validation) ឱ្យគ្រប់តាមផ្កាយ * ក្នុង UI
                if (selectedImages.isEmpty || // ឆែករូបថត
                    selectedCategory == null || // ឆែកប្រភេទ
                    nameController.text.isEmpty || // ឆែកឈ្មោះ
                    priceController.text.isEmpty || // ឆែកតម្លៃ
                    phone1Controller.text.isEmpty || // ឆែកលេខទូរស័ព្ទទី១
                    locationController.text.isEmpty) {
                  // ឆែកទីតាំង

                  Get.snackbar(
                    'ខ្វះព័ត៌មាន',
                    'សូមមេមេ ជួយបំពេញព័ត៌មាន និងដាក់រូបថតដែលមានសញ្ញា (*) ឱ្យគ្រប់សិន!',
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                  return; // បញ្ឈប់ការងារភ្លាម មិនឱ្យវាលោតទៅ Home ឡើយ
                }
                // ២. រៀបចំទិន្នន័យសម្រាប់ផ្ញើទៅ Controller
                Map<String, dynamic> dataFromForm = {
                  'product_name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'price': priceController.text.trim(),
                  'phone1': phone1Controller.text.trim(),
                  'phone2': phone2Controller.text.trim(),
                  'location': locationController.text.trim(),
                  'category': selectedCategory,
                  'currency': selectedCurrency,
                  'lat': selectedLat,
                  'lng': selectedLng,
                };

                // ៣. បញ្ជាឱ្យបង្ហោះក្រោយខ្នង (Background Upload)
                // ប្រើ List.from ដើម្បី Copy រូបភាពទុកឱ្យ Controller ការពារការបាត់ data ពេល clear screen
                uploadController.startBackgroundUpload(
                  productId: widget.productId,
                  formData: dataFromForm,
                  selectedImages: List.from(selectedImages),
                  selectedVideo: selectedVideo,
                );

                // ៤. នាំផ្លូវទៅ Home Screen វិញភ្លាមៗ (ប្រើតែមួយជួរនេះបានហើយមេ)
                Get.offAllNamed('/home');

                // ៥. បង្ហាញសារជូនដំណឹងនៅលើអេក្រង់ Home
                Get.snackbar(
                  '🚀 កំពុងបង្ហោះ...',
                  'ទំនិញរបស់មេកំពុងបង្ហោះក្នុង Background មេអាចបន្តមើលទំនិញផ្សេងបាន!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.black54,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 4),
                );

                // ៦. Clear ទិន្នន័យក្នុង Form ឱ្យស្អាត (Optional បើទៅ Home ហើយវានឹង Reset ខ្លួនឯង)
                nameController.clear();
                priceController.clear();
                descriptionController.clear();
                selectedImages.clear();
                // selectedVideo = null; // បើ error ជួរនេះអាច comment ចោលបាន
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'រក្សាទុកការផុស',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets ជំនួយសម្រាប់ UI ---
  Widget _buildMediaButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        minimumSize: const Size(double.infinity, 50),
        elevation: 0,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: InputDecoration(
        labelText: 'ប្រភេទលក់ *',
        prefixIcon: const Icon(Icons.category, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) => setState(() => selectedCategory = val),
    );
  }

  // ក្នុង _buildPriceSection បងដក Dropdown ចេញ ហើយប្រើតែសញ្ញារៀល
  Widget _buildPriceSection() {
    return TextField(
      controller: priceController,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isNotEmpty) {
          String cleanNumber = value.replaceAll(',', '');
          String formatted = formatter.format(int.parse(cleanNumber));

          priceController.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.fromPosition(
              TextPosition(offset: formatted.length),
            ),
          );
        }
      },
      decoration: InputDecoration(
        labelText: 'តម្លៃ (៛) *',
        prefixIcon: const Icon(Icons.money, color: Colors.green),
        suffixText: "៛",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField('លេខទី១ *', Icons.phone, phone1Controller),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTextField(
            'លេខទី២',
            Icons.phone_android,
            phone2Controller,
          ),
        ),
      ],
    );
  }
}
