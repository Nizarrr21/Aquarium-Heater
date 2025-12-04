import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';
import 'services/mqtt_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final MqttService _mqttService = MqttService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle untuk stabilitas koneksi
    switch (state) {
      case AppLifecycleState.resumed:
        // App kembali ke foreground, reconnect MQTT jika perlu
        print('App resumed - Checking MQTT connection...');
        if (!_mqttService.isConnected) {
          _mqttService.connect();
        }
        break;
      case AppLifecycleState.paused:
        // App di background
        print('App paused');
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
      case AppLifecycleState.detached:
        print('App detached');
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        break;
    }
  }
  
  // Dynamic theme colors based on temperature status
  Color _getThemeColor(double? temp) {
    if (temp == null) return Colors.blue; // Default
    
    if (temp < 24) {
      return Colors.lightBlue; // 🔵 DINGIN (Cold)
    } else if (temp >= 24 && temp <= 28) {
      return Colors.green; // 🟢 NORMAL
    } else {
      return Colors.red; // 🔴 OVERHEAT (Hot)
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double?>(
      stream: _mqttService.temperatureStream,
      builder: (context, snapshot) {
        final temperature = snapshot.data;
        final themeColor = _getThemeColor(temperature);
        
        return MaterialApp(
          title: 'Aquarium Smart Control',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeColor,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: Colors.grey[50],
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: false,
              titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
          ),
          home: const MainNavigation(),
        );
      },
    );
  }
}
