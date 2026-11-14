class ServiceItem {
  final String id;
  final String categoryId;
  final String? categoryName;
  final String title;
  final String description;
  final double price;
  final double originalPrice;
  final String durationText;
  final double rating;
  final int reviewsCount;
  final String warrantyPeriod;
  final List<String> keyFeatures;
  final bool isPopular;
  final String serviceType;
  final List<String> includedItems;
  final List<String> excludedItems;
  final List<String> benefits;
  final List<String> processSteps;
  final List<Map<String, String>> faqs;
  final List<String> packageIds;

  const ServiceItem({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.durationText,
    required this.rating,
    required this.reviewsCount,
    required this.warrantyPeriod,
    required this.keyFeatures,
    this.isPopular = false,
    this.serviceType = 'Doorstep & Workshop Service',
    this.includedItems = const [],
    this.excludedItems = const [],
    this.benefits = const [],
    this.processSteps = const [],
    this.faqs = const [],
    this.packageIds = const [],
  });

  /// Factory constructor to parse a backend JSON response.
  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    String parsedCategoryId = '';
    String? parsedCategoryName;

    if (json['categoryId'] is Map) {
      final catMap = json['categoryId'] as Map<String, dynamic>;
      parsedCategoryId = catMap['_id']?.toString() ?? catMap['id']?.toString() ?? '';
      parsedCategoryName = catMap['name']?.toString();
    } else if (json['categoryId'] != null) {
      parsedCategoryId = json['categoryId'].toString();
    }

    final double price = (json['price'] as num?)?.toDouble() ?? 0.0;
    final double originalPrice = (json['originalPrice'] as num?)?.toDouble() ?? price;
    final double rating = (json['rating'] as num?)?.toDouble() ?? 4.8;
    final int reviewsCount = (json['reviewCount'] ?? json['reviewsCount'] as num?)?.toInt() ?? 0;

    final List<String> inc = (json['includedItems'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final List<String> exc = (json['excludedItems'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final List<String> feats = (json['keyFeatures'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (inc.isNotEmpty ? List<String>.from(inc) : <String>[]);

    return ServiceItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      categoryId: parsedCategoryId,
      categoryName: parsedCategoryName,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: price,
      originalPrice: originalPrice,
      durationText: json['durationText']?.toString() ?? '3-4 Hours',
      rating: rating,
      reviewsCount: reviewsCount,
      warrantyPeriod: json['warrantyPeriod']?.toString() ?? 'Standard Warranty',
      keyFeatures: feats,
      isPopular: json['isPopular'] == true || rating >= 4.85,
      serviceType: json['serviceType']?.toString() ?? 'Doorstep & Workshop Service',
      includedItems: inc,
      excludedItems: exc,
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      processSteps: (json['processSteps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      faqs: (json['faqs'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(
                    (e as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
                  ))
              .toList() ??
          const [],
      packageIds: (json['packageIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      'title': title,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'durationText': durationText,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'warrantyPeriod': warrantyPeriod,
      'keyFeatures': keyFeatures,
      'isPopular': isPopular,
      'serviceType': serviceType,
      'includedItems': includedItems,
      'excludedItems': excludedItems,
    };
  }

  int get discountPercentage {
    if (originalPrice <= price) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }

  List<String> get allIncludedItems =>
      includedItems.isNotEmpty ? includedItems : keyFeatures;

  List<String> get allExcludedItems => excludedItems.isNotEmpty
      ? excludedItems
      : const [
          'Major mechanical engine rebuilding or replacement',
          'Accidental body frame restoration & chassis straightening',
          'Consumables or spares not listed in included items',
        ];

  List<String> get allBenefits => benefits.isNotEmpty
      ? benefits
      : const [
          '100% Genuine OEM / OES Spares Guaranteed',
          '50-Point Digital Vehicle Health Checklist',
          'Free Doorstep Pick-up and Delivery',
          'Certified Mechanics with State-of-the-art Tools',
        ];

  List<String> get allProcessSteps => processSteps.isNotEmpty
      ? processSteps
      : const [
          'Step 1: Thorough Digital Vehicle Inspection',
          'Step 2: Service Execution by Senior Certified Tech',
          'Step 3: Multi-Point Quality Audit & Trial Run',
          'Step 4: Final Exterior Clean & Digital Handover',
        ];

  List<Map<String, String>> get allFaqs => faqs.isNotEmpty
      ? faqs
      : [
          {
            'q': 'How long does this service usually take?',
            'a': 'This service typically takes approximately $durationText at our certified workshop.',
          },
          {
            'q': 'Are OEM genuine spare parts used?',
            'a': 'Yes, MyMechanic exclusively uses 100% genuine OEM/OES spares backed by manufacturer warranties.',
          },
          {
            'q': 'What is the warranty coverage?',
            'a': 'This service is covered by our $warrantyPeriod with hassle-free claim support.',
          },
          {
            'q': 'Is doorstep pickup and delivery included?',
            'a': 'Yes, you can choose free doorstep pickup & drop at your preferred time slot during booking.',
          },
        ];
}
