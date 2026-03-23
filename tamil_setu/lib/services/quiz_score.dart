/// Utility for computing quiz score percentages consistently across all quiz types.
class QuizScore {
  /// Returns the score as a rounded integer percentage (0–100).
  ///
  /// Asserts that [correct] is within [0, total] and [total] > 0 so any
  /// inconsistent state is surfaced immediately in debug/test builds.
  static int percent(int correct, int total) {
    assert(total > 0, 'Quiz total must be > 0');
    assert(
      correct >= 0 && correct <= total,
      'correct=$correct is out of range [0, $total]',
    );
    final result = (correct / total * 100).round();
    assert(
      result >= 0 && result <= 100,
      'Computed percentage $result is out of range [0, 100]',
    );
    return result;
  }
}
