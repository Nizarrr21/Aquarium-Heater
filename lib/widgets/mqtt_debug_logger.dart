import 'package:flutter/material.dart';

class MqttDebugLogger extends StatefulWidget {
  final Stream<String> logStream;
  
  const MqttDebugLogger({
    super.key,
    required this.logStream,
  });

  @override
  State<MqttDebugLogger> createState() => _MqttDebugLoggerState();
}

class _MqttDebugLoggerState extends State<MqttDebugLogger> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    widget.logStream.listen((log) {
      setState(() {
        _logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $log');
        if (_logs.length > 50) {
          _logs.removeAt(0);
        }
      });
      
      // Auto scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Connection Log',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() => _logs.clear());
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey, height: 8),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet...',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color textColor = Colors.white70;
                      
                      if (log.contains('✅') || log.contains('Connected')) {
                        textColor = Colors.green;
                      } else if (log.contains('❌') || log.contains('Error') || log.contains('Failed')) {
                        textColor = Colors.red;
                      } else if (log.contains('⚠️') || log.contains('Disconnected')) {
                        textColor = Colors.orange;
                      } else if (log.contains('📩') || log.contains('📤')) {
                        textColor = Colors.blue;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          log,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
