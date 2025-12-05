import 'package:thesis/core/network/base_result.dart';
import 'package:thesis/feature/instruction/infractructure/interface/i_instruction.dart';
import 'package:thesis/feature/instruction/infractructure/model/detail_model.dart';
import 'package:thesis/feature/instruction/infractructure/model/student_model.dart';
import 'package:thesis/feature/instruction/infractructure/path/path.dart';

import '../../../../core/network/api.dart';
import '../../../../core/network/endpoint.dart';
import '../../../../core/network/method.dart';

class InstructionRepository implements InstructionInterface {
  final RestfulRequest apiClient = RestfulRequest();

  @override
  Future<BaseResult<InstructionModel>> getDetail(
    Map<String, dynamic>? params,
  ) async {
    final response = await apiClient.requestData(
      EndpointType(
        method: DioHttpMethod.get,
        path: InstructionPath.getDetail,
        params: params,
      ),
    );
    if (response.isSuccess) {
      if (response.data is List && (response.data as List).isNotEmpty) {
        final model = InstructionModel.fromJson((response.data as List).first);
        return BaseResult(success: true, data: model);
      } else {
        final model = InstructionModel.fromJson(response.data);
        return BaseResult(success: true, data: model);
      }
    } else {
      return BaseResult(success: false, message: response.message);
    }
  }

  @override
  Future<BaseResult<List<StudentModel>>> getListStudent() async {
    final response = await apiClient.requestData(
      EndpointType(method: DioHttpMethod.get, path: InstructionPath.getStudent),
    );
    if (response.isSuccess && response.data is List) {
      List<StudentModel> classroomList = [];
      classroomList = (response.data as List)
          .map((item) => StudentModel.fromJson(item))
          .toList();
      return BaseResult(success: true, data: classroomList);
    } else {
      return BaseResult(success: false, message: response.message);
    }
  }

  @override
  Future<BaseResult<StudentModel>> getStudentDetail(
    Map<String, dynamic>? params,
  ) async {
    final response = await apiClient.requestData(
      EndpointType(
        method: DioHttpMethod.get,
        path: InstructionPath.getStudent,
        params: params,
      ),
    );
    if (response.isSuccess) {
      // Xử lý trường hợp response.data là object đơn lẻ
      if (response.data is Map<String, dynamic>) {
        final model = StudentModel.fromJson(response.data);
        return BaseResult(success: true, data: model);
      }
      // Xử lý trường hợp response.data là array
      else if (response.data is List && (response.data as List).isNotEmpty) {
        final model = StudentModel.fromJson((response.data as List).first);
        return BaseResult(success: true, data: model);
      } else {
        return BaseResult(success: false, message: 'No student data found');
      }
    } else {
      return BaseResult(success: false, message: response.message);
    }
  }
}
