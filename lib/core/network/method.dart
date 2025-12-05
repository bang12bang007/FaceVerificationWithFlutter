enum DioHttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH');

  const DioHttpMethod(this.value);
  final String value;
}
