import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/mqtt_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final MqttService _mqttService = MqttService();
  bool _isConnecting = false;
  bool _isManualMode = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Get temperature status color
  Color _getTemperatureColor(double? temp) {
    if (temp == null) return Colors.grey;
    if (temp < 24) return Colors.lightBlue; // 🔵 DINGIN
    if (temp >= 24 && temp <= 28) return Colors.green; // 🟢 NORMAL
    return Colors.red; // 🔴 OVERHEAT
  }
  
  // Get temperature status text
  String _getTemperatureStatus(double? temp) {
    if (temp == null) return '⏳ Memuat...';
    if (temp < 24) return '❄️ DINGIN';
    if (temp >= 24 && temp <= 28) return '✅ NORMAL';
    return '🔥 OVERHEAT';
  }
  
  // Get temperature status description
  String _getTemperatureDescription(double? temp) {
    if (temp == null) return 'Menunggu data sensor...';
    if (temp < 24) return 'Suhu terlalu dingin untuk ikan tropis';
    if (temp >= 24 && temp <= 28) return 'Suhu ideal untuk akuarium';
    return 'Suhu terlalu tinggi! Segera turunkan';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _connectToMqtt();
  }

  Future<void> _connectToMqtt() async {
    setState(() => _isConnecting = true);
    await _mqttService.connect();
    setState(() => _isConnecting = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double?>(
      stream: _mqttService.temperatureStream,
      initialData: _mqttService.lastTemperature,
      builder: (context, tempSnapshot) {
        final temp = tempSnapshot.data;
        final themeColor = _getTemperatureColor(temp);
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(FontAwesomeIcons.fishFins, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Dashboard Aquarium'),
              ],
            ),
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
        actions: [
          StreamBuilder<bool>(
            stream: _mqttService.connectionStream,
            initialData: _mqttService.isConnected,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? false;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isConnected 
                      ? Colors.green.withOpacity(0.2) 
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnected ? Colors.greenAccent : Colors.redAccent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.greenAccent : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Online' : 'Offline',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isConnecting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting to MQTT...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _connectToMqtt,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Temperature Status Banner
                      _buildTemperatureStatusBanner(),
                      const SizedBox(height: 16),
                      
                      // Quick Stats Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                        children: [
                          _buildQuickStatCard(
                            title: 'Suhu Air',
                            icon: FontAwesomeIcons.temperatureHigh,
                            color: Colors.orange,
                            stream: _mqttService.temperatureStream,
                            initialValue: _mqttService.lastTemperature,
                            unit: '°C',
                          ),
                          _buildQuickStatCard(
                            title: 'Kekeruhan',
                            icon: FontAwesomeIcons.droplet,
                            color: Colors.blue,
                            stream: _mqttService.turbidityStream,
                            initialValue: _mqttService.lastTurbidity,
                            unit: 'NTU',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Heater Control Card
                      _buildHeaterControlCard(),
                      const SizedBox(height: 16),
                      
                      // System Status
                      _buildSystemStatusCard(),
                    ],
                  ),
                ),
              ),
            ),
        );
      },
    );
  }

  Widget _buildQuickStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<double> stream,
    required double initialValue,
    required String unit,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FaIcon(icon, color: Colors.white, size: 18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                StreamBuilder<double>(
                  stream: stream,
                  initialData: initialValue,
                  builder: (context, snapshot) {
                    final value = snapshot.data ?? 0.0;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color.withOpacity(0.7),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaterControlCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[400]!, Colors.red[600]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const FaIcon(FontAwesomeIcons.fire, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Kontrol Heater',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                StreamBuilder<String>(
                  stream: _mqttService.statusStream,
                  initialData: _mqttService.lastStatus,
                  builder: (context, snapshot) {
                    final status = snapshot.data ?? 'OFF';
                    final isOn = status == 'ON';
                    final isAuto = status == 'AUTO';
                    
                    Color statusColor = isOn 
                        ? Colors.green 
                        : isAuto 
                            ? Colors.blue 
                            : Colors.grey;
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mode Switch
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mode Manual',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Switch(
                    value: _isManualMode,
                    onChanged: (value) {
                      setState(() => _isManualMode = value);
                      if (!value) {
                        _mqttService.setAutoMode();
                      }
                    },
                    activeColor: Colors.blue[700],
                  ),
                ],
              ),
            ),
            
            if (_isManualMode) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _mqttService.turnOnHeater(),
                      icon: const FaIcon(FontAwesomeIcons.fire, size: 16),
                      label: const Text('ON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _mqttService.turnOffHeater(),
                      icon: const FaIcon(FontAwesomeIcons.powerOff, size: 16),
                      label: const Text('OFF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusItem(
              icon: FontAwesomeIcons.wifi,
              label: 'Connection',
              status: 'Connected',
              color: Colors.green,
            ),
            const Divider(height: 24),
            _buildStatusItem(
              icon: FontAwesomeIcons.microchip,
              label: 'ESP32 Device',
              status: 'Active',
              color: Colors.blue,
            ),
            const Divider(height: 24),
            _buildStatusItem(
              icon: FontAwesomeIcons.clockRotateLeft,
              label: 'Last Update',
              status: 'Just now',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Temperature Status Banner Widget
  Widget _buildTemperatureStatusBanner() {
    return StreamBuilder<double?>(
      stream: _mqttService.temperatureStream,
      initialData: _mqttService.lastTemperature,
      builder: (context, snapshot) {
        final temp = snapshot.data;
        final statusColor = _getTemperatureColor(temp);
        final statusText = _getTemperatureStatus(temp);
        final statusDesc = _getTemperatureDescription(temp);
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withOpacity(0.8),
                statusColor.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  temp == null 
                      ? Icons.hourglass_empty 
                      : temp < 24 
                          ? Icons.ac_unit 
                          : temp <= 28 
                              ? Icons.check_circle 
                              : Icons.local_fire_department,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Status Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusDesc,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (temp != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${temp.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Animated Pulse Indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String status,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
