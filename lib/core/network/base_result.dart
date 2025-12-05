class BaseResult<T> {
  bool success;
  String? code;
  String? message;
  String? messageParams;
  T? data;

  BaseResult({
    this.success = true,
    this.code,
    this.message,
    this.messageParams,
    this.data,
  });
}

class BaseArray<T> {
  bool success;
  String? code;
  String? message;
  String? messageParams;
  List<T>? data;

  BaseArray({
    this.success = true,
    this.code,
    this.message,
    this.messageParams,
    this.data,
  });
}
