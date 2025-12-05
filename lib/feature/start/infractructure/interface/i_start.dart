import '../../../../core/network/base_result.dart';
import '../model/list_classroom_model.dart';

abstract class IStart{
  Future<BaseResult<List<ListClassroomModel>>> fetchList();
}