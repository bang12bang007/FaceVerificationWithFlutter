import 'package:thesis/core/network/base_result.dart';

import 'package:thesis/feature/start/infractructure/interface/i_start.dart';
import 'package:thesis/feature/start/infractructure/model/list_classroom_model.dart';
import 'package:thesis/feature/start/infractructure/path/start_path.dart';

import '../../../../core/network/api.dart';
import '../../../../core/network/endpoint.dart';
import '../../../../core/network/method.dart';

class StartRepository implements IStart {
  final RestfulRequest apiClient = RestfulRequest();

  @override
  Future<BaseResult<List<ListClassroomModel>>> fetchList() async {
    final response = await apiClient.requestData(
      EndpointType(method: DioHttpMethod.get, path: StartPath.getDetail),
    );
    if (response.isSuccess && response.data is List) {
      List<ListClassroomModel> classroomList = [];
      classroomList = (response.data as List)
          .map((item) => ListClassroomModel.fromJson(item))
          .toList();
      return BaseResult(success: true, data: classroomList);
    } else {
      return BaseResult(success: false, message: response.message);
    }
  }
}
