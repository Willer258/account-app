/// A budget buddy — a fictional peer for social motivation.
///
/// In MVP, buddies are mock/demo data to provide social proof
/// and motivation without requiring a backend.
class BudgetBuddy {
  const BudgetBuddy({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.savingsPercent,
    required this.streak,
    required this.badge,
    required this.isOnline,
  });

  final String id;
  final String name;
  final String avatarEmoji;

  /// Percentage of budget saved (0-100)
  final int savingsPercent;

  /// Current streak in days
  final int streak;

  /// Achievement badge label
  final String badge;

  final bool isOnline;

  /// Demo buddies for the MVP
  static const List<BudgetBuddy> demoBuddies = [
    BudgetBuddy(
      id: 'aissatou',
      name: 'Aïssatou',
      avatarEmoji: '👩🏾',
      savingsPercent: 78,
      streak: 12,
      badge: '🏆 Économe du mois',
      isOnline: true,
    ),
    BudgetBuddy(
      id: 'moussa',
      name: 'Moussa',
      avatarEmoji: '👨🏾',
      savingsPercent: 55,
      streak: 5,
      badge: '🔥 5 jours de suite',
      isOnline: false,
    ),
    BudgetBuddy(
      id: 'fatima',
      name: 'Fatima',
      avatarEmoji: '👩🏽',
      savingsPercent: 92,
      streak: 21,
      badge: '💎 Budget master',
      isOnline: true,
    ),
    BudgetBuddy(
      id: 'kofi',
      name: 'Kofi',
      avatarEmoji: '👨🏿',
      savingsPercent: 40,
      streak: 3,
      badge: '⚡ En progression',
      isOnline: false,
    ),
  ];
}

/// A shared budget challenge between buddies.
class BuddyChallenge {
  const BuddyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.participants,
    required this.endsAt,
  });

  final String id;
  final String title;
  final String description;
  final int targetAmount;
  final int currentAmount;
  final List<String> participants;
  final DateTime endsAt;

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;

  int get daysLeft => endsAt.difference(DateTime.now()).inDays.clamp(0, 999);
}
