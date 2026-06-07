import 'package:dio/dio.dart';
import 'package:x_oqs/core/network/api_endpoints.dart';

Dio createDio() {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );
}

Dio createLrclibDio() {
  final d = createDio();
  d.options.baseUrl = ApiEndpoints.lrclibBase;
  return d;
}

Dio createSponsorBlockDio() {
  final d = createDio();
  d.options.baseUrl = ApiEndpoints.sponsorBlockBase;
  return d;
}
