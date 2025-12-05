import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/bloc_status.dart';
import '../../../instruction/infractructure/model/student_model.dart';
import '../../../instruction/infractructure/repository/instruction_repository.dart';

part 'verification_state.dart';

class VerificationCubit extends Cubit<VerificationState> {
  VerificationCubit() : super(VerificationState());

  Future<void> fetchStudents(String mssv) async {
    emit(state.copyWith(status: BlocStatus.loading));
    if (mssv.isEmpty) {
      debugPrint('MSSV is empty, not calling API');
      emit(state.copyWith(status: BlocStatus.error));
      return;
    }
    emit(state.copyWith(status: BlocStatus.loading));
    final result = await InstructionRepository().getListStudent();
    if (result.success && result.data != null) {
      final student = result.data!.firstWhere(
        (student) => student.id == mssv,
        orElse: () => StudentModel(),
      );

      if (student.id != null && student.id!.isNotEmpty) {
        debugPrint('Student found: ${student.name}');
        emit(
          state.copyWith(
            detail: student,
            status: BlocStatus.success,
          ),
        );
      } else {
        debugPrint('Student not found with mssv: $mssv');
        emit(state.copyWith(status: BlocStatus.error,mssv: mssv.toString()));

      }
    } else {
      debugPrint('Failed to fetch students list');
      emit(state.copyWith(status: BlocStatus.error));
    }
  }
}
