class Workshop {
  final String id;
  final String name;
  final String city;
  final String area;
  final String address;
  final String pincode;
  final double rating;
  final int reviewsCount;
  final String leadMechanic;
  final String phone;
  final String operatingHours;
  final bool isDemoSeedData;
  final String disclaimer;
  final double latitude;
  final double longitude;

  const Workshop({
    required this.id,
    required this.name,
    this.city = 'Gurugram',
    required this.area,
    required this.address,
    this.pincode = '122015',
    this.rating = 4.8,
    this.reviewsCount = 150,
    required this.leadMechanic,
    this.phone = '+91 88269 91028',
    this.operatingHours = '24x7',
    this.isDemoSeedData = false,
    this.disclaimer = 'Official verified workshop location.',
    this.latitude = 28.491111,
    this.longitude = 77.0562498,
  });

  factory Workshop.fromJson(Map<String, dynamic> json) {
    return Workshop(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'My Mechanic Premium Car Service',
      city: json['city']?.toString() ?? 'Gurugram',
      area: json['area']?.toString() ?? 'Atul Kataria Chowk',
      address: json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '122015',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.8,
      reviewsCount: (json['reviewsCount'] is num) ? (json['reviewsCount'] as num).toInt() : 150,
      leadMechanic: json['leadMechanic']?.toString() ?? 'Assigned upon arrival',
      phone: json['phone']?.toString() ?? '+91 88269 91028',
      operatingHours: json['operatingHours']?.toString() ?? '24x7',
      isDemoSeedData: json['isDemoSeedData'] == true,
      disclaimer: json['disclaimer']?.toString() ??
          'Official verified workshop location.',
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : 28.491111,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : 77.0562498,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'area': area,
      'address': address,
      'pincode': pincode,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'leadMechanic': leadMechanic,
      'phone': phone,
      'operatingHours': operatingHours,
      'isDemoSeedData': isDemoSeedData,
      'disclaimer': disclaimer,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
