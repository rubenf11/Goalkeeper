import 'package:flutter/material.dart';

class HabitCategoryOption {
  const HabitCategoryOption(this.name, this.icon);

  final String name;
  final IconData icon;
}

class HabitCategoryCatalog {
  static const List<HabitCategoryOption> options = [
    HabitCategoryOption('Health & Fitness', Icons.fitness_center),
    HabitCategoryOption('Mental Wellness', Icons.psychology_outlined),
    HabitCategoryOption('Productivity', Icons.bolt_outlined),
    HabitCategoryOption('Learning', Icons.menu_book_outlined),
    HabitCategoryOption('Career', Icons.work_outline),
    HabitCategoryOption('Finance', Icons.account_balance_wallet_outlined),
    HabitCategoryOption('Relationships', Icons.favorite_border),
    HabitCategoryOption('Home', Icons.home_outlined),
    HabitCategoryOption('Creativity', Icons.palette_outlined),
    HabitCategoryOption('Spirituality', Icons.self_improvement),
    HabitCategoryOption('Nutrition', Icons.restaurant_outlined),
    HabitCategoryOption('Hobbies', Icons.sports_esports_outlined),
    HabitCategoryOption('Personal Growth', Icons.trending_up),
    HabitCategoryOption('Travel', Icons.flight_takeoff_outlined),
    HabitCategoryOption('Family', Icons.people_outline),
    HabitCategoryOption('Pet Care', Icons.pets_outlined),
    HabitCategoryOption('Community & Volunteering', Icons.groups_outlined),
    HabitCategoryOption('Addiction Recovery', Icons.healing_outlined),
    HabitCategoryOption('Other', Icons.more_horiz),
  ];

  static HabitCategoryOption optionFor(String categoryName) {
    for (final option in options) {
      if (option.name.toLowerCase() == categoryName.toLowerCase()) {
        return option;
      }
    }

    return options.last;
  }
}
