/// A weekly spending challenge.
///
/// Challenges motivate users to improve their budget habits
/// with concrete, time-limited goals.
class WeeklyChallenge {
  const WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.reward,
    required this.difficulty,
    this.isCompleted = false,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeType type;

  /// Target value (e.g. 5 days, 10000 FCFA)
  final double targetValue;

  /// Current progress value
  final double currentValue;

  /// Reward badge/message on completion
  final String reward;

  final ChallengeDifficulty difficulty;
  final bool isCompleted;
  final bool isActive;

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0;

  /// Active challenges for this week (demo data)
  static List<WeeklyChallenge> currentChallenges() {
    final now = DateTime.now();
    return [
      WeeklyChallenge(
        id: 'no-wants',
        title: 'Semaine sans envies',
        description: 'Passez 3 jours sans dépenses dans la catégorie Envies',
        emoji: '🧘',
        type: ChallengeType.avoidCategory,
        targetValue: 3,
        currentValue: 1,
        reward: '🏅 Maître de soi',
        difficulty: ChallengeDifficulty.medium,
      ),
      WeeklyChallenge(
        id: 'daily-log',
        title: 'Suivi quotidien',
        description: 'Enregistrez une dépense chaque jour pendant 7 jours',
        emoji: '📝',
        type: ChallengeType.dailyLog,
        targetValue: 7,
        currentValue: 3,
        reward: '⚡ Super traceur',
        difficulty: ChallengeDifficulty.easy,
      ),
      WeeklyChallenge(
        id: 'save-target',
        title: 'Objectif épargne',
        description: 'Épargnez 25 000 FCFA cette semaine',
        emoji: '💰',
        type: ChallengeType.savingsTarget,
        targetValue: 25000,
        currentValue: 8500,
        reward: '🌟 Épargnant étoile',
        difficulty: ChallengeDifficulty.hard,
      ),
      WeeklyChallenge(
        id: 'stay-budget',
        title: 'Budget intact',
        description: 'Ne dépassez pas votre budget Besoins cette semaine',
        emoji: '🎯',
        type: ChallengeType.stayUnderBudget,
        targetValue: 1,
        currentValue: 1,
        reward: '🏆 Budget champion',
        difficulty: ChallengeDifficulty.easy,
        isCompleted: true,
      ),
    ];
  }
}

enum ChallengeType {
  avoidCategory,
  dailyLog,
  savingsTarget,
  stayUnderBudget,
  reduceSpending,
}

enum ChallengeDifficulty { easy, medium, hard }

extension ChallengeDifficultyExt on ChallengeDifficulty {
  String get label {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 'Facile';
      case ChallengeDifficulty.medium:
        return 'Moyen';
      case ChallengeDifficulty.hard:
        return 'Difficile';
    }
  }

  // ignore: avoid_returning_this
  String get color {
    switch (this) {
      case ChallengeDifficulty.easy:
        return 'green';
      case ChallengeDifficulty.medium:
        return 'amber';
      case ChallengeDifficulty.hard:
        return 'red';
    }
  }
}
