import 'dart:ui';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// Initialize local notifications
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  // Ensure initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize time zone data
  tz.initializeTimeZones();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize background service
  await initializeService();

  runApp(MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Configure background service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure Widgets binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize time zone data in the background isolate
  tz.initializeTimeZones();

  // Only available on Android!
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Schedule notifications
  scheduleNotifications();
}

bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Notifications',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // No need to sendData here, the service will handle itself
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Background Notifications'),
      ),
      body: Center(
        child: Text('Your time is according to schedule Notification'),
      ),
    );
  }
}

// Schedule multiple notifications
void scheduleNotifications() {

  final myCoordinates = Coordinates(30.16239231144667, 71.51478590556405);
  final params = CalculationMethod.karachi.getParameters();
  params.madhab = Madhab.hanafi;
  final prayerTimes = PrayerTimes.today(myCoordinates, params);

  String fajarStr = DateFormat('HHmm').format(prayerTimes.fajr);
  int fajarHour = int.parse(fajarStr.substring(0, 2));
  int fajarMinute = int.parse(fajarStr.substring(2, 4));

  String duhrTimeStr = DateFormat('HHmm').format(prayerTimes.dhuhr);
  int duhrHour = int.parse(duhrTimeStr.substring(0, 2));
  int duhrMinute = int.parse(duhrTimeStr.substring(2, 4));

  String asrTimeStr = DateFormat('HHmm').format(prayerTimes.asr);
  int asrHour = int.parse(asrTimeStr.substring(0, 2));
  int asrMinute = int.parse(asrTimeStr.substring(2, 4));

  String magribStr = DateFormat('HHmm').format(prayerTimes.maghrib);
  int magribHour = int.parse(magribStr.substring(0, 2));
  int magribMinute = int.parse(magribStr.substring(2, 4));


  String ishaStr = DateFormat('HHmm').format(prayerTimes.isha);
  int ishaHour = int.parse(ishaStr.substring(0, 2));
  int ishaMinute = int.parse(ishaStr.substring(2, 4));




  final fajarTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, fajarHour, fajarMinute);
  final duhrTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, duhrHour, duhrMinute);
  final asrTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, asrHour, asrMinute);
  final magribTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, magribHour, magribMinute);
  final ishaTime =  DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, ishaHour, ishaMinute);


  print("This is Fajar Time: ${fajarTime}");
  print("This is Duhr Time: ${duhrTime}");
  print("This is Asr Time: ${asrTime}");
  print("This is Magrib Time: ${magribTime}");
  print("This is Isha Time: ${ishaTime}");

  final times = [
    fajarTime,
    duhrTime,
    asrTime,
    magribTime,
    ishaTime,
  ];

  for (int i = 0; i < times.length; i++) {
    scheduleNotification(i, times[i]);
  }
}

Future<void> scheduleNotification(int id, DateTime time) async {
  var scheduledTZTime = tz.TZDateTime.from(time, tz.local);

  print("Scheduling notification for: $scheduledTZTime");

  // Define notification details
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'your_channel_id', // channel ID
    'Channel Name', // channel name
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('notification'),
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  // Schedule notification
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id, // notification ID
    "Namaz", // title
    'Alarm', // body
    scheduledTZTime, // schedule time
    platformChannelSpecifics,
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}
//Second Method app is terminate


//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//     startForegroundService();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text("If app is terminate, service is running in background")
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// void startForegroundService() {
//   FlutterForegroundTask.init(
//     androidNotificationOptions: AndroidNotificationOptions(
//       channelId: 'foreground_channel_id',
//       channelName: 'Foreground Service Notification',
//       channelDescription: 'This notification appears when the foreground service is running.',
//       iconData: const NotificationIconData(
//         resType: ResourceType.mipmap,
//         resPrefix: ResourcePrefix.ic,
//         name: 'launcher',
//       ),
//     ),
//     iosNotificationOptions: IOSNotificationOptions(),
//     foregroundTaskOptions: ForegroundTaskOptions(
//       interval: 5000,
//       isOnceEvent: false,
//       autoRunOnBoot: true,
//       allowWifiLock: true,
//     ),
//
//   );
//
//   FlutterForegroundTask.startService(
//     notificationTitle: 'Foreground Service is running',
//     notificationText: 'Tap to return to the app',
//     callback: startCallback,
//   );
// }
//
// @pragma('vm:entry-point')
// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(MyTaskHandler());
// }
//
// class MyTaskHandler extends TaskHandler {
//   @override
//   Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
//     // Initialize resources or start an initial process
//     print('Foreground task started at $timestamp');
//     // Optionally, send a message back to the main isolate
//     sendPort?.send('Task started');
//   }
//
//   @override
//   Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
//     // Perform the background task
//     print('Event triggered at $timestamp');
//     // Optionally, send progress or result to the main isolate
//     sendPort?.send('Event triggered');
//   }
//
//   @override
//   Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
//     // Cleanup resources
//     print('Foreground task destroyed at $timestamp');
//   }
//
//   @override
//   Future<void> onButtonPressed(String id) async{
//     // Handle the button press action
//     print('Notification button pressed: $id');
//   }
//
//   @override
//   void onNotificationPressed() {
//     // Handle the notification press action
//     print('Notification pressed');
//   }
//
//   @override
//   void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
//     // Handle the repeated event
//     print('Repeat event triggered at $timestamp');
//     // Optionally, send progress or result to the main isolate
//     sendPort?.send('Repeat event triggered');
//   }
// }
