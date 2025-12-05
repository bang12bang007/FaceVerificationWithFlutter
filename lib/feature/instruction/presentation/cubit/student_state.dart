part of 'student_cubit.dart';

final class StudentState {
  final BlocStatus status;
  final StudentModel? detail;

  StudentState({this.status = BlocStatus.init, this.detail});

  StudentState copyWith({BlocStatus? status, StudentModel? detail}) {
    return StudentState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
    );
  }
}
