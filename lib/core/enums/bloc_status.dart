enum BlocStatus {
  init,
  loading,
  hasData,
  success,
  checking,
  error,
  validateError,
  initial;

  bool get isLoading {
    return this == loading;
  }

  bool get isError {
    return this == error;
  }
}
