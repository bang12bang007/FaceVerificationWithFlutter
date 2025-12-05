part of 'instruction_cubit.dart';


final class InstructionState {
  final BlocStatus status;
  final InstructionModel? detail;
  final List<StudentModel>? students;
  final int present;
  InstructionState({
    this.status = BlocStatus.init,
    this.detail,
    this.students,
    this.present = 0,
});
  InstructionState copyWith({
    BlocStatus? status,
    InstructionModel? detail,
    List<StudentModel>? students,
    int? present,
}){
    return InstructionState(
      detail: detail ?? this.detail,
      students: students ?? this.students,
      status: status ?? this.status,
      present: present ?? this.present,
    );
  }
}
