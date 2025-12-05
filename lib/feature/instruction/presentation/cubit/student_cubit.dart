import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thesis/core/enums/bloc_status.dart';
import 'package:thesis/feature/instruction/infractructure/model/student_model.dart';
import 'package:thesis/feature/instruction/infractructure/repository/instruction_repository.dart';

part 'student_state.dart';

class StudentCubit extends Cubit<StudentState> {
  StudentCubit() : super(StudentState());

  Future<void> fetchStudents(String mssv) async {
    emit(state.copyWith(status: BlocStatus.loading));
    final result = await InstructionRepository().getStudentDetail({
      'mssv': mssv,
    });
    if (result.success) {
      emit(state.copyWith(detail: result.data, status: BlocStatus.success));
    } else {
      emit(state.copyWith(status: BlocStatus.error));
    }
  }
}
