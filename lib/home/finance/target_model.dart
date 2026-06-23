import 'package:flutter/material.dart';

class SavingsTarget {
  final String id;
  final String name;
  final double targetAmount;
  final double dailyAmount;
  final String frequency;
  final String? category;
  final DateTime startDate;
  final DateTime maturityDate;
  final bool strictMode;
  double savedAmount;

  SavingsTarget({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.dailyAmount,
    required this.frequency,
    this.category,
    required this.startDate,
    required this.maturityDate,
    required this.strictMode,
    this.savedAmount = 0,
  });

  double get progress => (savedAmount / targetAmount).clamp(0.0, 1.0);
  int get daysLeft =>
      maturityDate.difference(DateTime.now()).inDays.clamp(0, 9999);
  bool get isCompleted => daysLeft == 0 || savedAmount >= targetAmount;
  double get totalDays => maturityDate.difference(startDate).inDays.toDouble();
  double get percentComplete => progress * 100;
}

class TargetStore extends InheritedWidget {
  final List<SavingsTarget> targets;
  final void Function(SavingsTarget) addTarget;

  const TargetStore({
    super.key,
    required this.targets,
    required this.addTarget,
    required super.child,
  });

  static TargetStore? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TargetStore>();

  @override
  bool updateShouldNotify(TargetStore old) => targets != old.targets;
}
