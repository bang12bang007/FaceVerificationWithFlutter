import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thesis/core/enums/bloc_status.dart';
import 'package:thesis/feature/instruction/infractructure/model/detail_model.dart';
import 'package:thesis/feature/instruction/infractructure/repository/instruction_repository.dart';

import '../../../../common/contranst/colors.dart';
import '../../../../shared/services/image_picker_service.dart';
import '../../infractructure/model/student_model.dart';

part 'instruction_state.dart';

class InstructionCubit extends Cubit<InstructionState> {
  InstructionCubit() : super(InstructionState());

  Future<void> fetchDetail(String id) async {
    emit(state.copyWith(status: BlocStatus.loading));
    final result = await InstructionRepository().getDetail({'id': id});
    if (result.success) {
      emit(state.copyWith(detail: result.data, status: BlocStatus.success));
    } else if (!result.success) {
      emit(state.copyWith(status: BlocStatus.error));
    } else {
      emit(state.copyWith(status: BlocStatus.hasData));
    }
  }

  Future<void> fetchStudents() async {
    emit(state.copyWith(status: BlocStatus.loading));
    final result = await InstructionRepository().getListStudent();
    if (result.success) {
      emit(state.copyWith(students: result.data, status: BlocStatus.success));
    } else {
      emit(state.copyWith(status: BlocStatus.error));
    }
  }

  Future<void> verifyStudent(BuildContext context) async {
    try {
      final File? imageFile = await ImagePickerService.showImageSourceDialog(
        context,
      );

      if (imageFile != null) {
        debugPrint('Selected image: ${imageFile.path}');

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Đã chọn ảnh thẻ sinh viên thành công!'),
        //     backgroundColor: UIColors.green,
        //   ),
        // );
      }
    } catch (e) {
      debugPrint('Error in verification: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Có lỗi xảy ra khi chọn ảnh'),
      //     backgroundColor: UIColors.redLight,
      //   ),
      // );
    }
  }

  Future<void> scanBarcode(BuildContext context) async {
    try {
      await ImagePickerService.showBarcodeScanner(context);
    } catch (e) {
      debugPrint('Error in barcode scanning: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Có lỗi xảy ra khi quét mã vạch'),
      //     backgroundColor: UIColors.redLight,
      //   ),
      // );
    }
  }
}
