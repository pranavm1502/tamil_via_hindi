/// Centralized XP rules for learning actions.
class XpRules {
  static const int newItemCorrect = 5;
  static const int reviewItemCorrect = 2;
  static const int lessonPass = 50;
  static const int buildPass = 25;
  static const int checkpointPass = 100;
  static const int reviewSessionBase = 10;
  static const int reviewPerCard = 2;
  static const int dailyGoalBonus = 25;

  static int xpForReviewSession(int cardsReviewed, {bool hitDailyGoal = false}) {
    final base = reviewSessionBase + (cardsReviewed * reviewPerCard);
    return hitDailyGoal ? base + dailyGoalBonus : base;
  }
}
