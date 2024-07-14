import 'dart:convert';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notifications/main.dart';
import 'package:notifications/pages/notif.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async{
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

void handleMessage(RemoteMessage? message ){
  print("16");
  if(message==null) return;
  print("18");
  navigatorKey.currentState?.pushNamed(
    NotificationScreen.route,
    arguments: message
  );
}





class FirebaseApi {
  final firebaseMessaging = FirebaseMessaging.instance;
  final androidchannel = const AndroidNotificationChannel(
    'exampleid', // id
    'Channel Name', // name
    description: 'This channel is used for important notifications.',
    // description
    importance: Importance.high,
  );
  final localNotif = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await firebaseMessaging.requestPermission();
    final fCMToken = await firebaseMessaging.getToken();
    print("Token: $fCMToken");
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    print("16");
    initPushNotifications();
    initLocalNotifications();
    print("initlocal called");
  }

  Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true
    );
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      localNotif.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              androidchannel.id,
              androidchannel.name,
              channelDescription: androidchannel.description,
              icon: '@drawable/ic_launcher'
            )
          ),
        payload: jsonEncode(message.toMap())
      );
    });
  }
  Future initLocalNotifications() async{
    // const ios = IOSInitializationSettings();
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const settings = InitializationSettings(android: android);
    await localNotif.initialize(
      settings,
      // onDidReceiveBackgroundNotificationResponse: (payload){
      //   print("hello");
      //   print(payload);
      //   final message = RemoteMessage.fromMap(jsonDecode(payload.toString()));
      //   handleMessage(message);
      //   handleBackgroundMessage(message);
      // }
      //   onDidReceiveNotificationResponse: (payload){
      //     print("===");
      //     print(payload.runtimeType);
      //   final msg = RemoteMessage.fromMap(jsonDecode(payload.toString()));
      //   print(msg);
      //   print("===");
      //   handleBackgroundMessage(msg);
      //   handleMessage(msg);
      //   }
        onDidReceiveNotificationResponse: ( x) async {
          print("Received notification response:");
          // print(payload);
          try {
            final RemoteMessage msg = RemoteMessage.fromMap(jsonDecode(x.payload!));
            print("Parsed RemoteMessage:");
            print(msg);

            // Handle your background message here
            handleBackgroundMessage(msg);
            handleMessage(msg);
          } catch (e) {
            print('Error handling notification response: $e');
          }
        }

    );
    final platform = localNotif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(androidchannel);
  }
}