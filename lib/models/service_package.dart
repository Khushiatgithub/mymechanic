class ServicePackage {
  final String id;
  final String title;
  final String tag;
  final String description;
  final double price;
  final double originalPrice;
  final String intervalText; // e.g. "Every 5,000 Kms / 3 Months"
  final String timeTakenText; // e.g. "4 Hours Taken"
  final List<String> checklist;
  final bool isRecommended;
  final String warranty;

  const ServicePackage({
    required this.id,
    required this.title,
    required this.tag,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.intervalText,
    required this.timeTakenText,
    required this.checklist,
    this.isRecommended = false,
    this.warranty = '1000 Kms / 1 Month Warranty',
  });

  int get savingsPercentage {
    if (originalPrice <= price) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }
}
