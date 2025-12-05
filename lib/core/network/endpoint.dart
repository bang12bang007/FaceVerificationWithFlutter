import 'package:dio/dio.dart';

import 'method.dart';


class EndpointType {
  EndpointType({
    this.path,
    this.method,
    this.params,
    this.header = const {'Content-Type': 'application/json'},
    this.responseType,
  });

  final String? path;
  final DioHttpMethod? method;
  final Map<String, dynamic>? params;
  final Map<String, String> header;
  final ResponseType? responseType;
}

class DefaultHeader {
  DefaultHeader._();

  static final DefaultHeader instance = DefaultHeader._();

  Map<String, String> get emptyHeader {
    Map<String, String> header = <String, String>{};
    return header;
  }
}
