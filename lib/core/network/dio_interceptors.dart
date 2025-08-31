import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioInterceptors {
  static List<Interceptor> getInterceptors() {
    return [
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
      // يمكنك إضافة المزيد من الـ interceptors هنا (مثل: TokenInterceptor)
    ];
  }
}