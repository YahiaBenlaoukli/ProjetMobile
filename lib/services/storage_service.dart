import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _goalKey = 'monthly_goal';

  Future<int> getMonthlyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? 0;
  }

  Future<void> setMonthlyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, goal);
  }
}
