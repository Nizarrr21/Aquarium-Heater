import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/mqtt_service.dart';

class HeaterScheduleScreen extends StatefulWidget {
  const HeaterScheduleScreen({super.key});

  @override
  State<HeaterScheduleScreen> createState() => _HeaterScheduleScreenState();
}

class _HeaterScheduleScreenState extends State<HeaterScheduleScreen> {
  final MqttService _mqttService = MqttService();
  
  final List<HeaterSchedule> _schedules = [
    HeaterSchedule(time: '06:00', action: 'ON', enabled: true, description: 'Pagi - Nyalakan heater'),
    HeaterSchedule(time: '09:00', action: 'OFF', enabled: true, description: 'Siang - Matikan heater'),
    HeaterSchedule(time: '18:00', action: 'ON', enabled: true, description: 'Sore - Nyalakan heater'),
    HeaterSchedule(time: '22:00', action: 'OFF', enabled: true, description: 'Malam - Matikan heater'),
  ];

  TimeOfDay? _selectedTime;
  String _selectedAction = 'ON';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Jadwal Heater'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[700]!, Colors.red[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddScheduleDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTodayScheduleCard(),
            const SizedBox(height: 16),
            _buildSchedulesList(),
            const SizedBox(height: 16),
            _buildHeaterTipsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayScheduleCard() {
    final enabledSchedules = _schedules.where((s) => s.enabled).length;
    final onSchedules = _schedules.where((s) => s.enabled && s.action == 'ON').length;
    final offSchedules = _schedules.where((s) => s.enabled && s.action == 'OFF').length;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[100]!, Colors.red[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!, width: 1),
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
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.fire,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Jadwal Heater Hari Ini',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTodayStatColumn('Total', '$enabledSchedules', Colors.red),
                Container(width: 1, height: 40, color: Colors.red[300]),
                _buildTodayStatColumn('ON', '$onSchedules', Colors.green),
                Container(width: 1, height: 40, color: Colors.red[300]),
                _buildTodayStatColumn('OFF', '$offSchedules', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulesList() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jadwal Otomatis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _schedules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                return _buildScheduleItem(schedule, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(HeaterSchedule schedule, int index) {
    final isOn = schedule.action == 'ON';
    final actionColor = isOn ? Colors.red : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: schedule.enabled 
            ? (isOn ? Colors.red[50] : Colors.grey[100])
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: schedule.enabled 
              ? (isOn ? Colors.red[200]! : Colors.grey[300]!)
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: schedule.enabled 
                  ? actionColor 
                  : Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              isOn ? FontAwesomeIcons.fire : FontAwesomeIcons.powerOff,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      schedule.time,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: schedule.enabled 
                            ? actionColor 
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: schedule.enabled 
                            ? actionColor 
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        schedule.action,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  schedule.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: schedule.enabled,
            onChanged: (value) {
              setState(() {
                _schedules[index] = schedule.copyWith(enabled: value);
              });
            },
            activeColor: actionColor,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red[400],
            onPressed: () {
              setState(() {
                _schedules.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaterTipsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[200]!, width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.lightbulb,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tips Penggunaan Heater',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem('Atur jadwal ON saat suhu turun (pagi/malam)'),
            _buildTipItem('Atur jadwal OFF saat suhu naik (siang/sore)'),
            _buildTipItem('Monitor suhu secara berkala'),
            _buildTipItem('Gunakan mode AUTO untuk hemat energi'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Jadwal Heater'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(_selectedTime?.format(context) ?? 'Pilih Waktu'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedAction,
              decoration: const InputDecoration(
                labelText: 'Aksi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ON', child: Text('Nyalakan (ON)')),
                DropdownMenuItem(value: 'OFF', child: Text('Matikan (OFF)')),
              ],
              onChanged: (value) {
                setState(() => _selectedAction = value ?? 'ON');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedTime != null) {
                setState(() {
                  _schedules.add(HeaterSchedule(
                    time: _selectedTime!.format(context),
                    action: _selectedAction,
                    enabled: true,
                    description: _selectedAction == 'ON' 
                        ? 'Nyalakan heater'
                        : 'Matikan heater',
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}

class HeaterSchedule {
  final String time;
  final String action; // 'ON' or 'OFF'
  final bool enabled;
  final String description;

  HeaterSchedule({
    required this.time,
    required this.action,
    required this.enabled,
    required this.description,
  });

  HeaterSchedule copyWith({
    String? time,
    String? action,
    bool? enabled,
    String? description,
  }) {
    return HeaterSchedule(
      time: time ?? this.time,
      action: action ?? this.action,
      enabled: enabled ?? this.enabled,
      description: description ?? this.description,
    );
  }
}
