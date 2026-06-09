import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.actionId == 'stop_alarm') {
        if (response.id != null) {
          await flutterLocalNotificationsPlugin.cancel(response.id!);
        }
      }
    },
  );
  runApp(const TrainAlarmApp());
}

class TrainAlarmApp extends StatelessWidget {
  const TrainAlarmApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainAlarmScreen(),
      theme: ThemeData.dark(),
    );
  }
}

class MainAlarmScreen extends StatefulWidget {
  const MainAlarmScreen({Key? key}) : super(key: key);
  @override
  State<MainAlarmScreen> createState() => _MainAlarmScreenState();
}

class _MainAlarmScreenState extends State<MainAlarmScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> logList = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _controller.text = prefs.getString('raw_text') ?? '';
      logList = prefs.getStringList('logs') ?? [];
    });
  }

  void _saveCurrentText(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('raw_text', text);
  }

  void runFastTest() async {
    final prefs = await SharedPreferences.getInstance();
    await AndroidAlarmManager.oneShot(const Duration(minutes: 1), 1, fireFirstAlarmNotification, exact: true, wakeup: true);
    await AndroidAlarmManager.oneShot(const Duration(minutes: 2), 2, fireSecondAlarmNotification, exact: true, wakeup: true);
    setState(() {
      logList = ["🧪 تست فعال شد: آلارم اول ۱ دقیقه بعد", "🧪 تست فعال شد: آلارم دوم ۲ دقیقه بعد"];
    });
    await prefs.setStringList('logs', logList);
  }

  void clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await AndroidAlarmManager.cancel(1);
    await AndroidAlarmManager.cancel(2);
    await flutterLocalNotificationsPlugin.cancelAll();
    await prefs.clear();
    setState(() { _controller.clear(); logList.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سیستم بومی آلارم راهبران')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _controller, maxLines: 5, onChanged: _saveCurrentText, decoration: const InputDecoration(hintText: 'متن پیام اعزام یا تست...', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(50)), onPressed: runFastTest, child: const Text('🧪 تست سریع پس‌زمینه (۱ و ۲ دقیقه بعد)')),
            const SizedBox(height: 10),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(50)), onPressed: clearAll, child: const Text('❌ پاک کردن تمام آلارم‌ها')),
            const SizedBox(height: 20),
            Expanded(child: logList.isEmpty ? const Center(child: Text('هیچ آلارم فعالی وجود ندارد')) : ListView.builder(itemCount: logList.length, itemBuilder: (context, index) => ListTile(leading: const Icon(Icons.alarm, color: Colors.amber), title: Text(logList[index]))))
          ],
        ),
      ),
    );
  }
}

void fireFirstAlarmNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails('alarm_channel_1', 'آلارم اصلی', importance: Importance.max, priority: Priority.high, sound: RawResourceAndroidNotificationSound('digital_alarm'), playSound: true, enableVibration: true, fullScreenIntent: true, actions: [AndroidNotificationAction('stop_alarm', '❌ قطع صدا', showsUserInterface: true)]);
  await flutterLocalNotificationsPlugin.show(1, '🚨 زمان حضور روی سکو!', '۱۰ دقیقه به اعزام باقی مانده است.', const NotificationDetails(android: androidDetails));
}

void fireSecondAlarmNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails('alarm_channel_2', 'آلارم ثانویه', importance: Importance.max, priority: Priority.high, sound: RawResourceAndroidNotificationSound('digital_alarm'), playSound: true, enableVibration: true, fullScreenIntent: true, actions: [AndroidNotificationAction('stop_alarm', '❌ قطع صدا', showsUserInterface: true)]);
  await flutterLocalNotificationsPlugin.show(2, '🚨 آماده‌ی اعزام!', 'ساعت حرکت نهایی فرا رسیده است.', const NotificationDetails(android: androidDetails));
}
