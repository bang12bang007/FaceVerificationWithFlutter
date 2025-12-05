class ListClassroomModel {
  ListClassroomModel({
    this.id,
    this.sourceCode,
    this.present,
    this.total,
    this.classroom,
    this.period,
    this.branch,
    this.subjectName,
  });

  ListClassroomModel.fromJson(dynamic json) {
    id = json['id']?.toString();
    sourceCode = json['sourceCode']?.toString();
    present = int.tryParse(json['present'].toString());
    total = int.tryParse(json['total'].toString());
    classroom = json['class']?.toString();
    period = json['period']?.toString();
    branch = json['branch']?.toString();
    subjectName = json['subjectName']?.toString();
  }

  String? id;
  String? sourceCode;
  int? present;
  int? total;
  String? classroom;
  String? period;
  String? branch;
  String? subjectName;

  ListClassroomModel copyWith({
    String? id,
    String? sourceCode,
    int? present,
    int? total,
    String? classroom,
    String? period,
    String? branch,
    String? subjectName,
  }) => ListClassroomModel(
    id: id ?? this.id,
    sourceCode: sourceCode ?? this.sourceCode,
    present: present ?? this.present,
    total: total ?? this.total,
    classroom: classroom ?? this.classroom,
    period: period ?? this.period,
    branch: branch ?? this.branch,
    subjectName: subjectName ?? subjectName,
  );
}
