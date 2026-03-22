import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'app.dart';
import 'firebase_options.dart';

/// ===============================
/// BACKGROUND MESSAGE HANDLER
/// ===============================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("Background notification:");
  print(message.notification?.title);
  print(message.notification?.body);
}

/// ===============================
/// SETUP FCM
/// ===============================
Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  /// xin quyền notification
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  /// lấy token thiết bị
  String? token = await messaging.getToken();
  print("FCM TOKEN: $token");

  /// nhận notification khi app đang mở
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground notification:");
    print(message.notification?.title);
    print(message.notification?.body);
  });

  /// khi user bấm vào notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("User clicked notification");
  });
}

/// ===============================
/// MAIN
/// ===============================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// xử lý notification khi app ở background
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  await setupFCM();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}
