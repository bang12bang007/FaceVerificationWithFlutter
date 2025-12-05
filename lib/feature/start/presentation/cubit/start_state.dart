
part of 'start_cubit.dart';

final class StartState {
  final String roomCode;
  final bool isDisableButton;
  final BlocStatus status;
  final List<ListClassroomModel>? roomList;

  StartState({
    this.roomCode = '',
    this.isDisableButton = false,
    this.status = BlocStatus.init,
    this.roomList,
  });

  StartState copyWith({
    String? roomCode,
    bool? isDisableButton,
    BlocStatus? status,
    List<ListClassroomModel>? roomList,
  }) {
    return StartState(
      roomCode: roomCode ?? this.roomCode,
      isDisableButton: isDisableButton ?? this.isDisableButton,
      status: status ?? this.status,
      roomList: roomList ?? this.roomList,
    );
  }
}