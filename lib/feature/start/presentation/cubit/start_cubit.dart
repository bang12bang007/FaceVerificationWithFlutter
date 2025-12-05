import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thesis/core/enums/bloc_status.dart';
import 'package:thesis/feature/start/infractructure/model/list_classroom_model.dart';
import 'package:thesis/feature/start/infractructure/repository/start_repository.dart';

part 'start_state.dart';

class StartCubit extends Cubit<StartState> {
  StartCubit() : super(StartState());
  final TextEditingController roomCodeController = TextEditingController();

  void changeRoomCode(String value) {
    emit(state.copyWith(roomCode: value));
    checkDisableButton();
  }

  void clearRoomCode() {
    emit(state.copyWith(roomCode: null));
  }

  void checkDisableButton() {
    if (state.roomCode.isNotEmpty) {
      emit(state.copyWith(isDisableButton: false));
    } else {
      emit(state.copyWith(isDisableButton: true));
    }
  }

  Future<void> fetchList() async {
    emit(state.copyWith(status: BlocStatus.loading));
    final result = await StartRepository().fetchList();
    if (result.success) {
      emit(state.copyWith(roomList: result.data, status: BlocStatus.success));
    } else {
      emit(state.copyWith(status: BlocStatus.error));
    }
  }

  bool isValidRoomCode(String roomCode) {
    if (state.roomList == null || state.roomList!.isEmpty) return false;
    return state.roomList!.any((room) => room.id == roomCode);
  }

  @override
  Future<void> close() {
    roomCodeController.dispose();
    return super.close();
  }
}
