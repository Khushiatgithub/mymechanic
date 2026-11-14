import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mymechanic/core/network/api_client.dart';
import 'package:mymechanic/models/booking.dart';
import 'package:mymechanic/services/booking_service.dart';

void main() {
  const testBaseUrl = 'https://api.mymechanic.test/api/v1';

  final sampleBookingJson = {
    '_id': '67b8a1000000000000000099',
    'bookingNumber': 'MM-2026-1234',
    'userId': {
      '_id': '67b8a1000000000000000010',
      'name': 'Rahul Sharma',
      'email': 'rahul@example.com',
      'phone': '9876543210',
    },
    'vehicleId': {
      '_id': '67b8a1000000000000000020',
      'make': 'Hyundai',
      'model': 'Creta',
      'variant': 'SX (O)',
      'registrationNumber': 'KA01MJ5050',
      'fuelType': 'Petrol',
      'year': 2022,
    },
    'serviceId': {
      '_id': '67b8a1000000000000000030',
      'title': 'Comprehensive Periodic Service',
      'description': 'Full synthetic oil replacement and 40-point inspection',
      'price': 3499.0,
      'durationText': '3-4 Hours',
      'includedItems': ['Engine Oil', 'Oil Filter', 'Brake Inspection'],
    },
    'scheduledDate': '2026-03-15T10:00:00.000Z',
    'scheduledTime': '10:30 AM',
    'serviceMode': 'doorstep',
    'address': '42, Indiranagar 100ft Road, Bengaluru - 560038',
    'couponCode': 'SAVE500',
    'subtotal': 3499.0,
    'discount': 500.0,
    'pickupFee': 149.0,
    'gst': 566.0,
    'totalAmount': 3714.0,
    'status': 'confirmed',
    'notes': 'Please call before arriving',
    'createdAt': '2026-03-01T12:00:00.000Z',
    'updatedAt': '2026-03-01T12:00:00.000Z',
  };

  group('BookingService - getBookings', () {
    test('returns list of Booking objects when response has items', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/bookings'));
        expect(request.method, equals('GET'));
        expect(request.headers['Authorization'], equals('Bearer test_access_token'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Bookings retrieved successfully',
            'data': {
              'items': [sampleBookingJson],
              'pagination': {
                'page': 1,
                'limit': 50,
                'total': 1,
                'pages': 1,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      final bookings = await service.getBookings();

      expect(bookings.length, equals(1));
      final b = bookings.first;
      expect(b.id, equals('67b8a1000000000000000099'));
      expect(b.bookingNumber, equals('MM-2026-1234'));
      expect(b.serviceTitle, equals('Comprehensive Periodic Service'));
      expect(b.vehicleName, equals('Hyundai Creta SX (O)'));
      expect(b.vehicleNumber, equals('KA01MJ5050'));
      expect(b.timeSlot, equals('10:30 AM'));
      expect(b.totalAmount, equals(3714.0));
      expect(b.status, equals(BookingStatus.confirmed));
      expect(b.statusText, equals('Booking Confirmed'));
      expect(b.serviceMode, equals('doorstep'));
    });

    test('forwards vehicleId and status query parameters correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/bookings'));
        expect(request.url.queryParameters['vehicleId'], equals('veh_123'));
        expect(request.url.queryParameters['status'], equals('completed'));
        expect(request.url.queryParameters['page'], equals('2'));
        expect(request.url.queryParameters['limit'], equals('10'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [],
              'pagination': {'page': 2, 'limit': 10, 'total': 0, 'pages': 0},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      final bookings = await service.getBookings(
        vehicleId: 'veh_123',
        status: 'completed',
        page: 2,
        limit: 10,
      );

      expect(bookings, isEmpty);
    });

    test('throws HttpStatusException when server returns 401 unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Authentication required'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'expired_token',
      );

      final service = BookingService(apiClient: apiClient);
      expect(() => service.getBookings(), throwsA(isA<HttpStatusException>()));
    });
  });

  group('BookingService - getBookingById', () {
    test('returns single Booking when ID exists', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/bookings/67b8a1000000000000000099'));
        expect(request.method, equals('GET'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleBookingJson,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      final booking = await service.getBookingById('67b8a1000000000000000099');

      expect(booking.id, equals('67b8a1000000000000000099'));
      expect(booking.serviceTitle, equals('Comprehensive Periodic Service'));
      expect(booking.couponCode, equals('SAVE500'));
    });

    test('throws HttpStatusException when booking ID is 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Booking not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      expect(
        () => service.getBookingById('invalid_id'),
        throwsA(isA<HttpStatusException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('BookingService - createBooking', () {
    test('sends valid payload and parses created booking', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/bookings'));
        expect(request.method, equals('POST'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['vehicleId'], equals('67b8a1000000000000000020'));
        expect(body['serviceId'], equals('67b8a1000000000000000030'));
        expect(body['scheduledTime'], equals('10:30 AM'));
        expect(body['serviceMode'], equals('doorstep'));
        expect(body['subtotal'], equals(3499.0));
        expect(body['discount'], equals(500.0));
        expect(body['totalAmount'], equals(3714.0));
        expect(body['couponCode'], equals('SAVE500'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Booking created successfully',
            'data': sampleBookingJson,
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      final booking = await service.createBooking(
        vehicleId: '67b8a1000000000000000020',
        serviceId: '67b8a1000000000000000030',
        scheduledDate: DateTime.parse('2026-03-15T10:00:00.000Z'),
        scheduledTime: '10:30 AM',
        serviceMode: 'doorstep',
        address: '42, Indiranagar 100ft Road, Bengaluru - 560038',
        couponCode: 'save500',
        subtotal: 3499.0,
        discount: 500.0,
        pickupFee: 149.0,
        gst: 566.0,
        totalAmount: 3714.0,
        notes: 'Please call before arriving',
      );

      expect(booking.id, equals('67b8a1000000000000000099'));
      expect(booking.bookingNumber, equals('MM-2026-1234'));
      expect(booking.status, equals(BookingStatus.confirmed));
    });

    test('throws HttpStatusException on VEHICLE_OWNERSHIP_MISMATCH 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Vehicle does not belong to the booking user.',
            'error': {'code': 'VEHICLE_OWNERSHIP_MISMATCH'},
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      expect(
        () => service.createBooking(
          vehicleId: 'other_user_veh',
          serviceId: 'srv_1',
          scheduledDate: DateTime.now(),
          scheduledTime: '10:00 AM',
          subtotal: 2000,
          totalAmount: 2000,
        ),
        throwsA(isA<HttpStatusException>().having(
          (e) => e.errorCode,
          'errorCode',
          'VEHICLE_OWNERSHIP_MISMATCH',
        )),
      );
    });

    test('throws HttpStatusException on DUPLICATE_BOOKING_NUMBER 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Booking number already exists.',
            'error': {'code': 'DUPLICATE_BOOKING_NUMBER'},
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      expect(
        () => service.createBooking(
          vehicleId: 'veh_1',
          serviceId: 'srv_1',
          scheduledDate: DateTime.now(),
          scheduledTime: '10:00 AM',
          subtotal: 2000,
          totalAmount: 2000,
        ),
        throwsA(isA<HttpStatusException>().having(
          (e) => e.errorCode,
          'errorCode',
          'DUPLICATE_BOOKING_NUMBER',
        )),
      );
    });
  });

  group('BookingService - rescheduleBooking', () {
    test('sends PATCH request with new date/time and returns updated Booking', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/bookings/67b8a1000000000000000099'));
        expect(request.method, equals('PATCH'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['scheduledTime'], equals('04:00 PM'));

        final updatedJson = Map<String, dynamic>.from(sampleBookingJson);
        updatedJson['scheduledTime'] = '04:00 PM';

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Booking details updated successfully',
            'data': updatedJson,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      final updated = await service.rescheduleBooking(
        '67b8a1000000000000000099',
        scheduledDate: DateTime.parse('2026-03-20T10:00:00.000Z'),
        scheduledTime: '04:00 PM',
      );

      expect(updated.timeSlot, equals('04:00 PM'));
    });

    test('throws HttpStatusException when booking is completed/cancelled (BOOKING_NOT_MODIFIABLE)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Cannot update booking details in terminal status.',
            'error': {'code': 'BOOKING_NOT_MODIFIABLE'},
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      expect(
        () => service.rescheduleBooking(
          '67b8a1000000000000000099',
          scheduledDate: DateTime.now(),
          scheduledTime: '10:00 AM',
        ),
        throwsA(isA<HttpStatusException>().having(
          (e) => e.errorCode,
          'errorCode',
          'BOOKING_NOT_MODIFIABLE',
        )),
      );
    });
  });

  group('BookingService - cancelBooking', () {
    test('sends status PATCH and returns cancelled Booking', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/bookings/67b8a1000000000000000099/status'));
        expect(request.method, equals('PATCH'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['status'], equals('cancelled'));

        final cancelledJson = Map<String, dynamic>.from(sampleBookingJson);
        cancelledJson['status'] = 'cancelled';

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Booking status updated successfully',
            'data': cancelledJson,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      final cancelled = await service.cancelBooking('67b8a1000000000000000099');

      expect(cancelled.status, equals(BookingStatus.cancelled));
      expect(cancelled.backendStatus, equals('cancelled'));
      expect(cancelled.statusText, equals('Cancelled'));
    });

    test('throws HttpStatusException on INVALID_STATUS_TRANSITION 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Cannot cancel booking in terminal status.',
            'error': {'code': 'INVALID_STATUS_TRANSITION'},
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      expect(
        () => service.cancelBooking('67b8a1000000000000000099'),
        throwsA(isA<HttpStatusException>().having(
          (e) => e.errorCode,
          'errorCode',
          'INVALID_STATUS_TRANSITION',
        )),
      );
    });
  });

  group('BookingService - deleteBooking', () {
    test('sends DELETE request to /api/v1/bookings/:id', () async {
      var deleteCalled = false;
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/bookings/67b8a1000000000000000099'));
        expect(request.method, equals('DELETE'));
        deleteCalled = true;

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Booking deleted successfully',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      await service.deleteBooking('67b8a1000000000000000099');
      expect(deleteCalled, isTrue);
    });

    test('throws HttpStatusException when deleting active booking', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Cannot delete an active booking.',
            'error': {'code': 'CANNOT_DELETE_ACTIVE_BOOKING'},
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: testBaseUrl,
        client: mockClient,
        tokenProvider: () async => 'test_access_token',
      );

      final service = BookingService(apiClient: apiClient);
      expect(
        () => service.deleteBooking('67b8a1000000000000000099'),
        throwsA(isA<HttpStatusException>().having(
          (e) => e.errorCode,
          'errorCode',
          'CANNOT_DELETE_ACTIVE_BOOKING',
        )),
      );
    });
  });

  group('BookingService - getErrorMessage', () {
    test('maps VEHICLE_OWNERSHIP_MISMATCH to friendly message', () {
      final ex = HttpStatusException(
        statusCode: 400,
        message: 'Vehicle does not belong to user',
        errorCode: 'VEHICLE_OWNERSHIP_MISMATCH',
      );
      expect(
        BookingService.getErrorMessage(ex),
        equals('The selected vehicle does not belong to your account.'),
      );
    });

    test('maps DUPLICATE_BOOKING_NUMBER to friendly message', () {
      final ex = HttpStatusException(
        statusCode: 400,
        message: 'Duplicate number',
        errorCode: 'DUPLICATE_BOOKING_NUMBER',
      );
      expect(
        BookingService.getErrorMessage(ex),
        contains('already exists'),
      );
    });

    test('maps INVALID_STATUS_TRANSITION to friendly message', () {
      final ex = HttpStatusException(
        statusCode: 400,
        message: 'Terminal status',
        errorCode: 'INVALID_STATUS_TRANSITION',
      );
      expect(
        BookingService.getErrorMessage(ex),
        contains('cannot be updated or cancelled'),
      );
    });

    test('maps BOOKING_NOT_MODIFIABLE to friendly message', () {
      final ex = HttpStatusException(
        statusCode: 400,
        message: 'Not modifiable',
        errorCode: 'BOOKING_NOT_MODIFIABLE',
      );
      expect(
        BookingService.getErrorMessage(ex),
        contains('cannot be modified'),
      );
    });

    test('maps CANNOT_DELETE_ACTIVE_BOOKING to friendly message', () {
      final ex = HttpStatusException(
        statusCode: 400,
        message: 'Active delete',
        errorCode: 'CANNOT_DELETE_ACTIVE_BOOKING',
      );
      expect(
        BookingService.getErrorMessage(ex),
        contains('Cannot delete an active booking'),
      );
    });

    test('maps 401, 403, 404, 500 status codes', () {
      expect(
        BookingService.getErrorMessage(HttpStatusException(statusCode: 401, message: '')),
        contains('sign in to manage'),
      );
      expect(
        BookingService.getErrorMessage(HttpStatusException(statusCode: 403, message: '')),
        contains('do not have permission'),
      );
      expect(
        BookingService.getErrorMessage(HttpStatusException(statusCode: 404, message: '')),
        contains('could not be found'),
      );
      expect(
        BookingService.getErrorMessage(HttpStatusException(statusCode: 500, message: '')),
        contains('Server error'),
      );
    });

    test('maps NetworkException, ApiTimeoutException, ApiResponseFormatException', () {
      expect(
        BookingService.getErrorMessage(NetworkException('Failed host lookup')),
        contains('internet connection'),
      );
      expect(
        BookingService.getErrorMessage(
          ApiTimeoutException('Timeout', timeout: const Duration(seconds: 15)),
        ),
        contains('timed out'),
      );
      expect(
        BookingService.getErrorMessage(
          const ApiResponseFormatException('Malformed body', rawBody: '<not json>'),
        ),
        contains('malformed data'),
      );
    });
  });
}
