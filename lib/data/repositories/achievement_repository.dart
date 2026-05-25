import '../models/habit.dart';
import 'habit_repository.dart';

class AchievementRepository {
  final HabitRepository _habitRepository = HabitRepository();

  Stream<List<Habit>> watchCurrentUserHabits() {
    return _habitRepository.watchCurrentUserHabits();
  }
}
