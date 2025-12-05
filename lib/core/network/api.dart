import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'base_reponse.dart';
import 'endpoint.dart';
import 'method.dart';

abstract class RestfulRequestProtocol {
  Future<BaseResponse> requestData(
    EndpointType endpoint, {
    CancelToken? cancelToken,
  });
}

class RestfulRequest extends RestfulRequestProtocol {
  RestfulRequest() {
    baseUrl = 'https://64583bd90c15cb14821a2a60.mockapi.io/';

    _dio = Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('-------BEGIN REQUEST---------');
          debugPrint('${options.method}: ${options.baseUrl}${options.path}');
          if (options.data != null) {
            debugPrint(options.data.toString());
          }
          debugPrint(options.queryParameters.toString());
          debugPrint(options.headers.toString());
          debugPrint('-------END REQUEST---------');
          return handler.next(options);
        },
        onResponse: (e, handler) async {
          debugPrint('-------BEGIN RESPONSE---------');
          debugPrint(e.requestOptions.path);
          if (e.data.toString().length > 500) {
            debugPrint('${e.data.toString().substring(0, 500)}...');
          } else {
            debugPrint(e.data.toString());
          }
          debugPrint('-------END RESPONSE---------');

          return handler.resolve(e);
        },
        onError: (ex, handler) async {
          if (ex.type == DioExceptionType.connectionTimeout ||
              ex.type == DioExceptionType.receiveTimeout) {
            handler.next(ex);
          }
          if ((ex.response?.statusCode ?? 0) >= 500) {
            if (ex.response?.statusCode == 503) {
              //MAINTAIN
              return handler.next(ex);
            } else {
              handler.reject(ex);
            }
          }
          debugPrint(ex.message?.toString());
        },
      ),
    );
  }

  late String baseUrl;
  late Dio _dio;

  @override
  Future<BaseResponse> requestData(
    EndpointType endpoint, {
    CancelToken? cancelToken,
  }) async {
    final header = endpoint.header;
    Response response;
    if (endpoint.method == DioHttpMethod.get) {
      response = await _dio
          .request(
            endpoint.path!,
            queryParameters: endpoint.params,
            cancelToken: cancelToken,
            options: Options(
              headers: header,
              method: endpoint.method!.value,
              responseType: endpoint.responseType,
              validateStatus: (status) {
                if (status == null) {
                  return false;
                }
                return status <= 500;
              },
            ),
          )
          .timeout(Duration(seconds: 30));
    } else {
      response = await _dio
          .request(
            endpoint.path!,
            data: endpoint.params,
            options: Options(
              headers: header,
              method: endpoint.method!.value,
              responseType: endpoint.responseType,
              validateStatus: (status) {
                if (status == null) {
                  return false;
                }
                return status <= 500;
              },
            ),
          )
          .timeout(Duration(seconds: 30));
    }
    final json = response.data;
    int statusCode = response.statusCode!;
    if (json == null) {
      return const BaseResponse();
    }
    if (statusCode >= 200 && statusCode < 300) {
      return BaseResponse.fromSuccessJson(json);
    }
    // Handle error response - check if json is Map or String
    if (json is Map<String, dynamic>) {
      return BaseResponse.fromErrorJson(json);
    } else {
      return BaseResponse(isSuccess: false, message: json.toString());
    }
  }
}
