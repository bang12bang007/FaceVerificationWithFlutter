import '../../domain/status_enum.dart';

class StudentModel {
  StudentModel({
    this.name,
    this.classroom,
    this.avatar,
    this.male,
    this.birthdate,
    this.born,
    this.major,
    this.course,
    this.type,
    this.id,
    this.status,
  });

  StudentModel.fromJson(dynamic json) {
    Map<String, dynamic> data;
    if (json is List && json.isNotEmpty) {
      data = json.first as Map<String, dynamic>;
    } else if (json is Map<String, dynamic>) {
      data = json;
    } else {
      return;
    }
    name = data['name']?.toString();
    classroom = data['class']?.toString();
    avatar = data['avatar']?.toString();
    male = data['male']?.toString();
    birthdate = data['birthdate']?.toString();
    born = data['born']?.toString();
    major = data['major']?.toString();
    course = data['course']?.toString();
    type = data['type']?.toString();
    id = data['id']?.toString();
    if (data['status'] != null) {
      status = data['status'] == true ? StatusEnum.present : StatusEnum.absent;
    } else {
      status = StatusEnum.absent;
    }
  }
  String? name;
  String? classroom;
  String? avatar;
  String? male;
  String? birthdate;
  String? born;
  String? major;
  String? course;
  String? type;
  String? id;
  StatusEnum? status;
  StudentModel copyWith({
    String? name,
    String? classroom,
    String? avatar,
    String? male,
    String? birthdate,
    String? born,
    String? major,
    String? course,
    String? type,
    String? id,
    StatusEnum? status,
  }) => StudentModel(
    name: name ?? this.name,
    classroom: classroom ?? this.classroom,
    avatar: avatar ?? this.avatar,
    male: male ?? this.male,
    birthdate: birthdate ?? this.birthdate,
    born: born ?? this.born,
    major: major ?? this.major,
    course: course ?? this.course,
    type: type ?? this.type,
    id: id ?? this.id,
    status: status ?? this.status,
  );
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['class'] = classroom;
    map['avatar'] = avatar;
    map['male'] = male;
    map['birthdate'] = birthdate;
    map['born'] = born;
    map['major'] = major;
    map['course'] = course;
    map['type'] = type;
    map['id'] = id;
    map['status'] = status == StatusEnum.present;
    return map;
  }
}
