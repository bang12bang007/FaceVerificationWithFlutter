class BaseResponse {
  final String? code;
  final String? message;
  final dynamic data;
  final bool isSuccess;
  final dynamic messageParams;

  const BaseResponse({
    this.code,
    this.message,
    this.data,
    this.isSuccess = false,
    this.messageParams,
  });

  factory BaseResponse.fromSuccessJson(dynamic json) {
    return BaseResponse(
      isSuccess: true,
      data: json,
    );
  }

  factory BaseResponse.fromErrorJson(Map<String, dynamic> json) {
    return BaseResponse(
      isSuccess: false,
      code: json['code'],
      message: json['message'] ?? json['code'],
      messageParams: json['messageParams'],
    );
  }
}
