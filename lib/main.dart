import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

// ✅ ត្រូវប្រាកដថាបានដាក់ File ទាំងនេះក្នុង Folder តែមួយ
import 'firebase_options.dart';
import 'upload_controller.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

// ១. បង្កើត Channel សម្រាប់ Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'order_channel',
  'ការកម្ម៉ង់ទំនិញថ្មី',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('order_sound'),
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // បង្ការ Error ពេល App នៅ Background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  // ១. ត្រូវដាក់ជួរនេះមុនគេបង្អស់
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ២. ដំឡើង Firebase ជាមួយ Options (ដាច់ខាតត្រូវតែមានសម្រាប់ iOS/Mac)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully!");

    // ៣. រៀបចំ Controller និង Notification បន្ទាប់ពី Firebase រួចរាល់
    Get.put(UploadController());
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ស្នើសុំសិទ្ធិសម្រាប់ iOS
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

  } catch (e) {
    print("❌ Firebase Init Error: $e");
    // បើ Firebase មានបញ្ហា ឱ្យវាចេញអក្សរប្រាប់ កុំឱ្យចេញផ្ទាំងស
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Error: $e")))));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sesan Agriculture Store',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('km', 'KH')],
      locale: const Locale('km', 'KH'),
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
        fontFamily: 'Siemreap', // បើចេញផ្ទាំងសទៀត សាកលុបជួរនេះចោលសិន
        platform: TargetPlatform.iOS,
      ),
      // ✅ ប្រើ StreamBuilder ដើម្បីប្តូរទំព័រដោយស្វ័យប្រវត្តិ
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // ខណៈពេលកំពុងឆែកមើលថា User បាន Login ឬនៅ
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.green)),
            );
          }
          // បើមានទិន្នន័យ User (បាន Login រួច)
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }
          // បើមិនទាន់ Login
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}