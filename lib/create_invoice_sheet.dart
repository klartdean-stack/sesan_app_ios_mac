import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

class CreateInvoiceSheet extends StatefulWidget {
  final Function(Map<String, dynamic> data) onAction;

  static final TextEditingController cusName = TextEditingController();
  static final TextEditingController cusPhone = TextEditingController();
  static final TextEditingController cusAddress = TextEditingController();
  static final TextEditingController shipPrice = TextEditingController(
    text: '0.0',
  );

  static List<Map<String, TextEditingController>> items = [
    {
      'desc': TextEditingController(),
      'qty': TextEditingController(text: '1.0'),
      'price': TextEditingController(text: '0.0'),
    },
  ];

  static File? qrFile;

  const CreateInvoiceSheet({super.key, required this.onAction});

  @override
  State<CreateInvoiceSheet> createState() => _CreateInvoiceSheetState();
}

class _CreateInvoiceSheetState extends State<CreateInvoiceSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  // ១. មុខងារ Reset ទិន្នន័យ (Method ដែលបាត់)
  void _resetInvoice() {
    setState(() {
      CreateInvoiceSheet.cusName.clear();
      CreateInvoiceSheet.cusPhone.clear();
      CreateInvoiceSheet.cusAddress.clear();
      CreateInvoiceSheet.shipPrice.text = '0.0';
      CreateInvoiceSheet.qrFile = null;
      CreateInvoiceSheet.items = [
        {
          'desc': TextEditingController(),
          'qty': TextEditingController(text: '1.0'),
          'price': TextEditingController(text: '0.0'),
        },
      ];
    });
  }

  Future<void> _pickAndCropQRCode() async {
    final ImagePicker picker = ImagePicker();
    final ImageCropper cropper = ImageCropper();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final CroppedFile? croppedFile = await cropper.cropImage(
        sourcePath: image.path,
        // 🎯 កែសម្រួលត្រង់នេះ៖ ក្នុង Version ថ្មី គេប្រើចំណុចខាងក្រោមជំនួសវិញ
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'តម្រឹម QR Code',
            toolbarColor: Colors.green,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            // ✅ ដាក់ Aspect Ratio Presets ក្នុង AndroidUiSettings វិញ
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'តម្រឹម QR Code',
            aspectRatioLockEnabled: true,
            // ✅ ដាក់ Aspect Ratio Presets ក្នុង IOSUiSettings វិញ
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          CreateInvoiceSheet.qrFile = File(croppedFile.path);
        });
      }
    }
  }

  double _calculateGrandTotal() {
    double subtotal = CreateInvoiceSheet.items.fold(0, (sum, item) {
      double q = double.tryParse(item['qty']!.text) ?? 0;
      double p = double.tryParse(item['price']!.text) ?? 0;
      return sum + (q * p);
    });
    double shipping = double.tryParse(CreateInvoiceSheet.shipPrice.text) ?? 0;
    return subtotal + shipping;
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
        controller: _screenshotController,
        child: Container(
          // ១. កំណត់ពណ៌សដាច់ខាត និងអនុញ្ញាតឱ្យកម្ពស់អូសតាមទិន្នន័យ
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min, // 🎯 ឱ្យ Column រួញ/រីកតាមទិន្នន័យបុង
                children: [
                _buildHeader(), // ក្បាលបុង
            // ២. ប្រើ Flexible ជំនួស Expanded ដើម្បីកុំឱ្យវាបង្ខាំងទំហំពេល Screenshot
            Flexible(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- ផ្នែកបញ្ជីទំនិញ ---
                      const Text(
                        "បញ្ជីទំនិញ / Items List",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // 🎯 បង្ហាញទំនិញទាំងអស់ (មិនប្រើ ListView នាំឱ្យដាច់រូប)
                      ...CreateInvoiceSheet.items
                          .asMap()
                          .entries
                          .map((entry) => _buildItemCard(entry.key))
                          .toList(),

                      TextButton.icon(
                        onPressed: () => setState(
                              () => CreateInvoiceSheet.items.add({
                            'desc': TextEditingController(),
                            'qty': TextEditingController(text: '1'),
                            'price': TextEditingController(text: '0'),
                          }),
                        ),
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        label: const Text(
                          "បន្ថែមទំនិញថ្មី",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      const Divider(height: 30, thickness: 1),

                      // --- ផ្នែកព័ត៌មានអ្នកទិញ ---
                      const Text(
                        "ព័ត៌មានអ្នកទិញ / Buyer Info",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildInput(
                        "ឈ្មោះអ្នកទិញ / Buyer Name",
                        CreateInvoiceSheet.cusName,
                      ),
                      _buildInput(
                        "លេខទូរស័ព្ទ / Phone",
                        CreateInvoiceSheet.cusPhone,
                        isNum: true,
                      ),
                      _buildInput(
                        "អាសយដ្ឋាន / Address",
                        CreateInvoiceSheet.cusAddress,
                      ),
                      _buildInput(
                        "ថ្លៃដឹកជញ្ជូន / Shipping (៛)", // ✅ ប្រើ៛សុទ្ធ
                        CreateInvoiceSheet.shipPrice,
                        isNum: true,
                        onChanged: (v) => setState(() {}),
                      ),
                      const SizedBox(height: 20),

                      // --- ផ្នែក QR Code ---
                      _buildQRUploadSection(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
            ),

                  // ៣. ផ្នែកប៊ូតុង Save/Capture (នៅជាប់ខាងក្រោមជានិច្ច)
                  _buildActionSection(),
                ],
            ),
        ),
    );
  }

  Widget _buildQRUploadSection() {
    return Column(
      children: [
        const Text(
          "QR Code សម្រាប់បង់ប្រាក់ (ABA / KHQR)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickAndCropQRCode,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: CreateInvoiceSheet.qrFile != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                CreateInvoiceSheet.qrFile!,
                fit: BoxFit.cover,
              ),
            )
                : const Icon(
              Icons.qr_code_scanner,
              size: 60,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "បង្កើតវិក្កយបត្រអាជីព",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              // 🎯 ប៊ូតុងចូលមើលប្រវត្តិបុង
              // ក្នុង Method _buildHeader របស់ CreateInvoiceSheet
              IconButton(
                onPressed: () {
                  // 🎯 បិទ Sheet សិន រួចចាំបើក Screen ថ្មី (ដើម្បីកុំឱ្យវាជាន់គ្នា)
                  Navigator.pop(context);
                  widget.onAction({'type': 'history'});
                },
                icon: const Icon(Icons.history, color: Colors.blue),
              ),
              IconButton(
                onPressed: _resetInvoice,
                icon: const Icon(Icons.refresh, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ៣. មុខងារបង្ហាញកាតទំនិញ (Method ដែលបាត់)
  Widget _buildItemCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _buildInput("ឈ្មោះទំនិញ", CreateInvoiceSheet.items[index]['desc']!),
            Row(
              children: [
                Expanded(
                  child: _buildInput(
                    "ចំនួន",
                    CreateInvoiceSheet.items[index]['qty']!,
                    isNum: true,
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInput(
                    "តម្លៃរាយ ៛", // 🎯 ប្តូរ Label ពី $ មកជា ៛ សុទ្ធ
                    CreateInvoiceSheet.items[index]['price']!,
                    isNum: true,
                    onChanged: (v) {
                      // 🎯 រក្សាទិន្នន័យ និង Refresh UI ភ្លាមៗ
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () =>
                      setState(() => CreateInvoiceSheet.items.removeAt(index)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          children: [
          Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "សរុបចុងក្រោយ៖",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              // 🎯 ប្រើ NumberFormat ដើម្បីឱ្យចេញក្បៀស (ឧទាហរណ៍៖ 1,200,000 ៛)
              "${NumberFormat('#,###').format(_calculateGrandTotal())} ៛",
              style: const TextStyle(
                fontSize: 22, // 🎯 រីកទំហំឱ្យធំជាងមុនបន្តិច
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            // 🎯 កែត្រង់ជួរ 330 និង 334 ក្នុងរូបមេ
            // ១. ប៊ូតុង Save
            _actionBtn(Icons.save, "Save", Colors.blue, () {
          widget.onAction({
            'type': 'save',
            'total':
            _calculateGrandTotal(), // 🎯 ថែមជួរនេះដើម្បីបោះតម្លៃឱ្យ ChatScreen
          });
        }),

        // ២. ប៊ូតុង Capture
        _actionBtn(Icons.camera_alt,"Capture", Colors.purple, () {
          widget.onAction({
            'type': 'screenshot',
            'total': _calculateGrandTotal(), // 🎯 ថែមជួរនេះដែរ
          });
        }),
            ],
        ),
          ],
        ),
    );
  }

  Widget _actionBtn(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap, // 🎯 ប្រកាសថាទទួល Function ពីក្រៅ
      ) {
    return InkWell(
      onTap: onTap, // 🎯 ពេលចុចឱ្យវាហៅ Function នោះ
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
      String label,
      TextEditingController ctrl, {
        bool isNum = false,
        Function(String)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: ctrl,
        onChanged: onChanged,
        keyboardType: isNum
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}