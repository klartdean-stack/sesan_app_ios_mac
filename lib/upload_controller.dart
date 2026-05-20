import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // 🎯 បន្ថែមសម្រាប់ទាញយក User ID
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

class UploadController extends GetxController {
  var isUploading = false.obs;
  var uploadProgress = 0.0.obs; // 🎯 សម្រាប់បង្ហាញភាគរយរត់លើអេក្រង់ Home

  // --- មុខងារបង្រួមរូបភាព ---
  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final outPath =
          "${filePath.substring(0, lastIndex)}_${DateTime.now().millisecondsSinceEpoch}_compressed.jpg";

      var result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );
      return result != null ? File(result.path) : file;
    } catch (e) {
      return file;
    }
  }

  // --- មុខងារបង្រួមវីដេអូ ---
  Future<File?> _compressVideo(File file) async {
    try {
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      return info?.file;
    } catch (e) {
      VideoCompress.cancelCompression();
      return null;
    }
  }

  // --- មុខងារបង្ហោះចម្បង ( background Upload - គ្រប់ជ្រុងជ្រោយ ) ---
  Future<void> startBackgroundUpload({
    required String? productId,
    required Map<String, dynamic>
    formData, // ទិន្នន័យពី Form (ឈ្មោះ, តម្លៃ, លេខទូរស័ព្ទ...)
    required List<XFile> selectedImages,
    XFile? selectedVideo,
  }) async {
    if (isUploading.value) return; // ការពារការចុចផុសជាន់គ្នា
    isUploading.value = true;
    uploadProgress.value = 0.05; // ចាប់ផ្ដើម ៥%

    try {
      List<String> imageUrls = [];
      String? videoUrl;

      // ១. ទាញព័ត៌មានអ្នកលក់ (Seller Info) ឱ្យបានគ្រប់ជ្រុងជ្រោយតាមកូដចាស់
      final user = FirebaseAuth.instance.currentUser;
      String currentUserName = 'មិនមានឈ្មោះ';
      String currentUserPhoto = '';

      if (user != null) {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          currentUserName = userDoc.data()?['name'] ?? 'មិនមានឈ្មោះ';
          currentUserPhoto = userDoc.data()?['photoUrl'] ?? '';
        }
      }

      // ២. បង្ហោះរូបភាព និង Update ភាគរយ (ស៊ីម៉ោង ៥០%)
      for (int i = 0; i < selectedImages.length; i++) {
        File fileToUpload = File(selectedImages[i].path);
        File? compressed = await _compressImage(fileToUpload);

        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${selectedImages[i].name}";
        Reference ref = FirebaseStorage.instance.ref().child(
          'products/images/$fileName',
        );

        await ref.putFile(compressed ?? fileToUpload);
        imageUrls.add(await ref.getDownloadURL());

        // គណនាភាគរយរត់ពី ១០% ដល់ ៦០%
        uploadProgress.value = 0.1 + ((i + 1) / selectedImages.length * 0.5);
      }

      // ៣. បង្ហោះវីដេអូ (ស៊ីម៉ោង ៣០%)
      if (selectedVideo != null) {
        File fileToUpload = File(selectedVideo.path);
        File? compressed = await _compressVideo(fileToUpload);

        String fileName = "${DateTime.now().millisecondsSinceEpoch}_video.mp4";
        Reference ref = FirebaseStorage.instance.ref().child(
          'products/videos/$fileName',
        );

        await ref.putFile(compressed ?? fileToUpload);
        videoUrl = await ref.getDownloadURL();
        await VideoCompress.deleteAllCache();

        uploadProgress.value = 0.9; // បង្ហោះចប់លោតដល់ ៩០%
      } // ៤. រៀបចំផែនទីទិន្នន័យ (Map Data) ឱ្យដូចកូដចាស់ ១០០% ដើម្បីកុំឱ្យច្របូកច្របល់លុយកាក់
      Map<String, dynamic> finalData = {
        'seller_id': user?.uid ?? 'UNKNOWN',
        'seller_name': currentUserName,
        'seller_photo': currentUserPhoto,
        'product_name': formData['product_name'],
        'description': formData['description'],
        'price': formData['price'],
        'phone1': formData['phone1'],
        'phone2': formData['phone2'],
        'seller_phone': formData['phone1'], // លេខសំខាន់សម្រាប់ទំនាក់ទំនង
        'location': formData['location'],
        'category': formData['category'],
        'currency': formData['currency'],
        'image_urls': imageUrls,
        'video_url': videoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // ៥. រុញចូល Firestore
      if (productId == null) {
        finalData['created_at'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(finalData);
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .update(finalData);
      }

      uploadProgress.value = 1.0; // ជោគជ័យ ១០០%

      Get.snackbar(
        "🎉 រក្សាទុកជោគជ័យ!",
        "ទំនិញ '${finalData['product_name']}' ត្រូវបានដាក់លក់ហើយមេ!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      uploadProgress.value = 0.0;
      Get.snackbar(
        "❌ បរាជ័យ",
        "ការបង្ហោះមានបញ្ហា៖ $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploading.value = false;
      // លាក់របារ Progress ក្រោយ ៣ វិនាទី
      Future.delayed(
        const Duration(seconds: 3),
        () => uploadProgress.value = 0.0,
      );
    }
  }
}
