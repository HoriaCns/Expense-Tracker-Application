class Budget {
  final String id;
  final String userId;
  final double amount;
  final String month; // Format: "YYYY-MM"

  Budget({
    required this.id,
    required this.userId,
    required this.amount,
    required this.month,
  });
}