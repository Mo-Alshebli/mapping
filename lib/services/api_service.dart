import 'package:dio/dio.dart';
import '../models/land_parcel.dart';
import '../models/crop_statistics.dart';
import '../models/ndvi_layer.dart';

/// API Service for server communication
class ApiService {
  late final Dio _dio;
  final String baseUrl;

  ApiService({this.baseUrl = 'https://your-api-url.com/api'}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging (optional)
    _dio.interceptors.add(LogInterceptor(
      request: true,
      responseBody: true,
      error: true,
      requestBody: true,
    ));
  }

  /// Send GeoJSON to server and receive NDVI data and statistics
  Future<ParcelAnalysisResponse> analyzeParcel(LandParcel parcel) async {
    try {
      final response = await _dio.post(
        '/parcels/analyze',
        data: parcel.toGeoJSON(),
      );

      return ParcelAnalysisResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('خطأ غير متوقع: $e');
    }
  }

  /// Get historical data for a parcel
  Future<List<HistoricalData>> getHistoricalData(String parcelId) async {
    try {
      final response = await _dio.get('/parcels/$parcelId/history');
      return (response.data['history'] as List)
          .map((h) => HistoricalData.fromJson(h))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Upload parcel to server
  Future<void> uploadParcel(LandParcel parcel) async {
    try {
      await _dio.post(
        '/parcels',
        data: {
          'geojson': parcel.toGeoJSON(),
          'metadata': {
            'name': parcel.name,
            'crop_type': parcel.cropType,
            'created_at': parcel.createdAt.toIso8601String(),
          },
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors
  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? 'خطأ في السيرفر';
        return ApiException('خطأ ($statusCode): $message');

      case DioExceptionType.cancel:
        return ApiException('تم إلغاء الطلب');

      case DioExceptionType.connectionError:
        return ApiException('خطأ في الاتصال. تحقق من اتصالك بالإنترنت.');

      default:
        return ApiException('حدث خطأ غير متوقع: ${error.message}');
    }
  }
}

/// Response from parcel analysis API
class ParcelAnalysisResponse {
  final String overlayUrl;
  final CropStatistics statistics;
  final NDVILayer ndviLayer;

  ParcelAnalysisResponse({
    required this.overlayUrl,
    required this.statistics,
    required this.ndviLayer,
  });

  factory ParcelAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return ParcelAnalysisResponse(
      overlayUrl: json['overlay_url'],
      statistics: CropStatistics.fromJson(json['statistics']),
      ndviLayer: NDVILayer.fromJson({
        'overlay_url': json['overlay_url'],
        ...json['layer_info'],
      }),
    );
  }
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
