import '../../../../core/network/base_result.dart';
import '../model/detail_model.dart';
import '../model/student_model.dart';

abstract class InstructionInterface{
  Future<BaseResult<InstructionModel>> getDetail(Map<String, dynamic>? params);
  Future<BaseResult<List<StudentModel>>> getListStudent();
  Future<BaseResult<StudentModel>> getStudentDetail(Map<String, dynamic>? params);
}