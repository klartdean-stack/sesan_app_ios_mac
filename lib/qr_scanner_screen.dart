import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms; // ✅ កែត្រង់នេះ
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
as ml; // ✅ កែត្រង់នេះ
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail.dart';


class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});


  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}


class _QrScannerScreenState extends State<QrScannerScreen> {
  final ms.MobileScannerController _controller =
  ms.MobileScannerController(); // ✅ ថែម ms.
  bool _isProcessing = false;
  String _statusMsg = 'ស្កែន QR Code ផលិតផល';


  // ── Scan from Gallery ──────────────────────────────────
  Future<void> _pickAndScanImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;


    // ✅ ប្រើ ml. នៅពីមុខ ដើម្បីឱ្យវាស្គាល់ BarcodeScanner របស់ ML Kit
    final barcodeScanner = ml.BarcodeScanner(
      formats: [ml.BarcodeFormat.qrCode],
    );
    final inputImage = ml.InputImage.fromFilePath(image.path);


    try {
      final barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final code = barcodes.first.displayValue;
        if (code != null) _handleQrCode(code);
      } else {
        _showSnackBar('រកមិនឃើញ QR ក្នុងរូបភាពទេ!');
      }
    } finally {
      barcodeScanner.close();
    }
  }


  // ── Handle QR Code ─────────────────────────────────────
  Future<void> _handleQrCode(String code) async {
    setState(() => _statusMsg = 'កំពុងស្វែងរកផលិតផល...');


    if (!code.startsWith('product_id_')) {
      _showSnackBar('QR Code នេះមិនមែនជារបស់ Sesan App!');
      // ✅ reset ដើម្បីអាច scan ម្ដងទៀត
      if (mounted)
        setState(() {
          _isProcessing = false;
          _statusMsg = 'ស្កែន QR Code ផលិតផល';
        });
      return;
    }


    final String productId = code.replaceAll('product_id_', '');


    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();


      if (!mounted) return;


      if (doc.exists) {
        // ✅ include 'id' ចូល product map
        final productData = doc.data()!;
        productData['id'] = doc.id;


        // ✅ push មិនមែន pushReplacement — អាច back វិញ
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: productData),
          ),
        );


        // ✅ reset ពេល back មកវិញ
        if (mounted)
          setState(() {
            _isProcessing = false;
            _statusMsg = 'ស្កែន QR Code ផលិតផល';
          });
      } else {
        _showSnackBar('រកមិនឃើញផលិតផលក្នុងប្រព័ន្ធ!');
        if (mounted)
          setState(() {
            _isProcessing = false;
            _statusMsg = 'ស្កែន QR Code ផលិតផល';
          });
      }
    } catch (e) {
      _showSnackBar('Error: $e');
      if (mounted)
        setState(() {
          _isProcessing = false;
          _statusMsg = 'ស្កែន QR Code ផលិតផល';
        });
    }
  }


  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Siemreap')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }


  // ... (ទុក _handleQrCode និង _showSnackBar ឱ្យនៅដដែល) ...


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'ស្កែន QR ផលិតផល',
          style: TextStyle(fontFamily: 'Siemreap'),
        ),
        actions: [
          // Flash toggle
          // 💡 កែក្នុង AppBar ត្រង់ផ្នែក actions
          IconButton(
            // ✅ ai_barcode_scanner ភាគច្រើនប្រើ toggleTorch() ផ្ទាល់ពី controller
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              // ប្រសិនបើមេប្រើ MobileScannerController របស់ ai_barcode_scanner
              _controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _controller.switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          ms.MobileScanner(
            // ✅ ថែម ms.
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null) {
                setState(() => _isProcessing = true);
                _handleQrCode(code);
              }
            },
          ),


          // ── Scan Frame UI ───────────────────────────────
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.orange : Colors.greenAccent,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isProcessing
                  ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
                  : null,
            ),
          ),


          // ── Status Text ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.62,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusMsg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Siemreap',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),


          // ── Gallery Button ──────────────────────────────
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _isProcessing ? null : _pickAndScanImage,
                icon: const Icon(Icons.image_rounded, color: Colors.blue),
                label: const Text(
                  'ជ្រើសរើសរូបពី Gallery',
                  style: TextStyle(
                    color: Colors.black87,
                    fontFamily: 'Siemreap',
                  ),
                ),
              ),
            ),
          ),
          // ── Loading Overlay ─────────────────────────────
          if (_isProcessing) Container(color: Colors.black26),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}



