import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../data/mock_data.dart';
import '../models/offer.dart';
import 'auth_service.dart';

class ValidatedCouponResult {
  final bool isValid;
  final String code;
  final String title;
  final String description;
  final double discountAmount;
  final double finalAmount;
  final String? errorMessage;

  const ValidatedCouponResult({
    required this.isValid,
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.finalAmount,
    this.errorMessage,
  });

  factory ValidatedCouponResult.invalid(String code, String errorMessage) {
    return ValidatedCouponResult(
      isValid: false,
      code: code,
      title: '',
      description: '',
      discountAmount: 0.0,
      finalAmount: 0.0,
      errorMessage: errorMessage,
    );
  }
}

class OfferService {
  final ApiClient apiClient;

  OfferService({required this.apiClient});

  static OfferService? _instance;

  static OfferService get instance =>
      _instance ??= OfferService(apiClient: AuthService.instance.apiClient);

  static set instance(OfferService service) => _instance = service;

  static void resetInstance() {
    _instance = null;
  }

  /// Fetches active offers from `GET /api/v1/offers`.
  /// Gracefully falls back to [MockData.offers] on network failure.
  Future<List<Offer>> getOffers({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category != 'All Deals') {
        queryParams['category'] = category;
      }

      final response = await apiClient.get(
        ApiConfig.offersPath,
        queryParameters: queryParams,
        timeout: const Duration(seconds: 2),
      );

      final data = response.data;
      List<dynamic> items = [];
      if (data is Map<String, dynamic> && data['data'] is List) {
        items = data['data'] as List<dynamic>;
      } else if (data is List) {
        items = data;
      }

      if (items.isNotEmpty) {
        return items.asMap().entries.map((entry) {
          final idx = entry.key;
          final json = entry.value as Map<String, dynamic>;
          return Offer.fromJson(json, idx);
        }).toList();
      }
    } catch (_) {
      // Fallback to offline mock data
    }

    // Client fallback
    var list = MockData.offers;
    if (category != null && category.isNotEmpty && category != 'All Deals') {
      list = list.where((o) => o.eligibleCategory == category).toList();
    }
    return list;
  }

  /// Validates a coupon code against backend `POST /api/v1/offers/validate`.
  /// Falls back to local validation against [MockData.coupons] if server is unreachable
  /// or when operating on local mock services / offline mode.
  Future<ValidatedCouponResult> validateCoupon({
    required String code,
    required double orderAmount,
    String? category,
    String? serviceId,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    // If serviceId is a local mock ID (e.g. 's1', 'srv_periodic_1') or in offline mode,
    // evaluate immediately against local coupons for instant responsiveness without network latency.
    final isMockService = serviceId != null && !RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(serviceId);
    final isOffline = AuthService.instance.authStatus == AuthStatus.offline;

    if (isMockService || isOffline) {
      final localCoupon = MockData.findCoupon(cleanCode);
      if (localCoupon != null) {
        final val = localCoupon.validate(
          orderAmount: orderAmount,
          category: category,
          serviceId: serviceId,
        );
        if (!val.isValid) {
          return ValidatedCouponResult.invalid(
            cleanCode,
            val.errorMessage ?? 'Invalid coupon code',
          );
        }
        final disc = localCoupon.calculateDiscount(orderAmount);
        return ValidatedCouponResult(
          isValid: true,
          code: localCoupon.code,
          title: localCoupon.title,
          description: localCoupon.description,
          discountAmount: disc,
          finalAmount: (orderAmount - disc).clamp(0.0, double.infinity),
        );
      }
      return ValidatedCouponResult.invalid(cleanCode, 'Invalid coupon code "$cleanCode".');
    }

    try {
      final body = <String, dynamic>{
        'code': cleanCode,
        'orderAmount': orderAmount,
      };
      if (category != null) body['category'] = category;
      if (serviceId != null) body['serviceId'] = serviceId;

      final response = await apiClient.post(
        '${ApiConfig.offersPath}/validate',
        body: body,
        timeout: const Duration(seconds: 3),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = (data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : data;

        final discAmount = (payload['discountAmount'] as num?)?.toDouble() ?? 0.0;
        final finalAmt = (payload['finalAmount'] as num?)?.toDouble() ??
            (orderAmount - discAmount).clamp(0.0, double.infinity);

        return ValidatedCouponResult(
          isValid: true,
          code: payload['code']?.toString() ?? cleanCode,
          title: payload['title']?.toString() ?? '',
          description: payload['description']?.toString() ?? '',
          discountAmount: discAmount,
          finalAmount: finalAmt,
        );
      }
    } catch (e) {
      if (e is HttpStatusException) {
        if (e.statusCode == 404) {
          return ValidatedCouponResult.invalid(cleanCode, 'Invalid coupon code "$cleanCode".');
        }
        if (e.statusCode == 400) {
          if (e.errorCode == 'COUPON_EXPIRED') {
            return ValidatedCouponResult.invalid(cleanCode, 'This coupon has expired.');
          }
          if (e.errorCode == 'COUPON_INACTIVE') {
            return ValidatedCouponResult.invalid(cleanCode, 'This coupon is currently inactive.');
          }
          if (e.errorCode == 'MIN_ORDER_VALUE_NOT_MET') {
            return ValidatedCouponResult.invalid(
              cleanCode,
              e.message.isNotEmpty ? e.message : 'Minimum order value not met.',
            );
          }
          if (e.errorCode == 'CATEGORY_NOT_ELIGIBLE') {
            return ValidatedCouponResult.invalid(
              cleanCode,
              e.message.isNotEmpty ? e.message : 'Coupon not applicable to this category.',
            );
          }
          return ValidatedCouponResult.invalid(
            cleanCode,
            e.message.isNotEmpty ? e.message : 'Coupon cannot be applied.',
          );
        }
      }

      // Offline / network failure: fallback to local validation against MockData.coupons
      final localCoupon = MockData.findCoupon(cleanCode);
      if (localCoupon != null) {
        final val = localCoupon.validate(
          orderAmount: orderAmount,
          category: category,
          serviceId: serviceId,
        );
        if (!val.isValid) {
          return ValidatedCouponResult.invalid(
            cleanCode,
            val.errorMessage ?? 'Invalid coupon code',
          );
        }
        final disc = localCoupon.calculateDiscount(orderAmount);
        return ValidatedCouponResult(
          isValid: true,
          code: localCoupon.code,
          title: localCoupon.title,
          description: localCoupon.description,
          discountAmount: disc,
          finalAmount: (orderAmount - disc).clamp(0.0, double.infinity),
        );
      }
      return ValidatedCouponResult.invalid(cleanCode, 'Invalid coupon code "$cleanCode".');
    }

    return ValidatedCouponResult.invalid(cleanCode, 'Unable to validate coupon.');
  }
}
