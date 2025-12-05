part of 'verification_cubit.dart';

final class VerificationState {
  final BlocStatus status;
  final StudentModel? detail;
  final String? mssv;

  VerificationState({this.status = BlocStatus.init, this.detail, this.mssv});

  VerificationState copyWith({BlocStatus? status, StudentModel? detail,String? mssv}) {
    return VerificationState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      mssv:  mssv ?? this.mssv,
    );
  }
}
