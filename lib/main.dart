import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCV08jOjFXpF7vaR2uXsttC1T_jE8Py-nI",
      authDomain: "airqualitymonitoring-29268.firebaseapp.com",
      databaseURL:
          "https://airqualitymonitoring-29268-default-rtdb.firebaseio.com",
      projectId: "airqualitymonitoring-29268",
      storageBucket: "airqualitymonitoring-29268.firebasestorage.app",
      messagingSenderId: "863952557052",
      appId: "1:863952557052:web:71a750fd156cb27aca1879",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Quality Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Map<String, dynamic> currentData = {
    'temperature': 0.0,
    'humidity': 0.0,
    'co2_ppm': 0.0,
    'co_ppm': 0.0,
    'air_quality': 'LOADING',
    'timestamp': 0,
  };

  List<FlSpot> co2History = [];
  List<FlSpot> coHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    listenToFirebase();
  }

  void listenToFirebase() {
    // Listen to current data
    _dbRef.child('sensors/current').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          currentData = Map<String, dynamic>.from(event.snapshot.value as Map);
          isLoading = false;
        });
      }
    });

    // Load history for charts
    loadHistory();
  }

  void loadHistory() {
    _dbRef.child('sensors/history').limitToLast(20).onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> history = event.snapshot.value as Map;

        List<FlSpot> co2Spots = [];
        List<FlSpot> coSpots = [];

        int index = 0;
        history.forEach((key, value) {
          co2Spots.add(FlSpot(index.toDouble(), value['co2_ppm'].toDouble()));
          coSpots.add(FlSpot(index.toDouble(), value['co_ppm'].toDouble()));
          index++;
        });

        setState(() {
          co2History = co2Spots;
          coHistory = coSpots;
        });
      }
    });
  }

  Color getQualityColor(String quality) {
    switch (quality) {
      case 'NORMAL':
        return Colors.green;
      case 'WARNING':
        return Colors.orange;
      case 'HAZARDOUS':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌡️ Air Quality Monitor'),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                loadHistory();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              getQualityColor(currentData['air_quality']),
                              getQualityColor(currentData['air_quality'])
                                  .withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Status Kualitas Udara',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentData['air_quality'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Temperature & Humidity
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            '🌡️ Suhu',
                            '${currentData['temperature'].toStringAsFixed(1)}°C',
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            '💧 Kelembaban',
                            '${currentData['humidity'].toStringAsFixed(1)}%',
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CO2 & CO
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            '☁️ CO2',
                            '${currentData['co2_ppm'].toStringAsFixed(0)} ppm',
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            '💨 CO',
                            '${currentData['co_ppm'].toStringAsFixed(2)} ppm',
                            Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // CO2 Chart
                    if (co2History.isNotEmpty) ...[
                      const Text(
                        'Grafik CO2 (20 Data Terakhir)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: co2History,
                                isCurved: true,
                                color: Colors.purple,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // CO Chart
                    if (coHistory.isNotEmpty) ...[
                      const Text(
                        'Grafik CO (20 Data Terakhir)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: coHistory,
                                isCurved: true,
                                color: Colors.red,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
