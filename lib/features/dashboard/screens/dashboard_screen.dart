import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _monthlyGoal = 0;
  bool _isLoadingGoal = true;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final storageService = context.read<StorageService>();
    final goal = await storageService.getMonthlyGoal();
    if (mounted) {
      setState(() {
        _monthlyGoal = goal;
        _isLoadingGoal = false;
      });
    }
  }

  Future<void> _updateGoal() async {
    int? newGoal = await showDialog<int>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _monthlyGoal.toString());
        return AlertDialog(
          title: const Text('Set Monthly Goal'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of plays'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newGoal != null && mounted) {
      final storageService = context.read<StorageService>();
      await storageService.setMonthlyGoal(newGoal);
      setState(() {
        _monthlyGoal = newGoal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<FirestoreService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Usage Statistics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              color: Colors.deepPurple.shade800,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.play_circle_fill, size: 60, color: Colors.purpleAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'Total Audio Plays',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<int>(
                      stream: firestoreService.getTotalPlays(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        final totalPlays = snapshot.data ?? 0;
                        return Column(
                          children: [
                            Text(
                              '$totalPlays',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (!_isLoadingGoal && _monthlyGoal > 0) ...[
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: (totalPlays / _monthlyGoal).clamp(0.0, 1.0),
                                backgroundColor: Colors.white24,
                                color: Colors.purpleAccent,
                                minHeight: 10,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Goal Progress: ${((totalPlays / _monthlyGoal) * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ]
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              color: Colors.deepPurple.shade900,
              child: ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Monthly Goal (Local)'),
                subtitle: _isLoadingGoal 
                    ? const Text('Loading...') 
                    : Text('$_monthlyGoal plays'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _updateGoal,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
