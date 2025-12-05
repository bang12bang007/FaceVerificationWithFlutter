class InstructionModel {
  InstructionModel({
    this.id,
    this.sourceCode,
    this.present,
    this.total,
    this.classroom,
    this.period,
    this.branch,
    this.subjectName,
  });

  InstructionModel.fromJson(dynamic json) {
    Map<String, dynamic> data;
    if (json is List && json.isNotEmpty) {
      data = json.first as Map<String, dynamic>;
    } else if (json is Map<String, dynamic>) {
      data = json;
    } else {
      return;
    }

    id = data['id']?.toString();
    sourceCode = data['sourceCode']?.toString();
    present = data['present'] is int
        ? data['present']
        : int.tryParse(data['present'].toString());
    total = data['total'] is int
        ? data['total']
        : int.tryParse(data['total'].toString());
    classroom = data['class']?.toString();
    period = data['period']?.toString();
    branch = data['branch']?.toString();
    subjectName = data['subjectName']?.toString();
  }

  String? id;
  String? sourceCode;
  int? present;
  int? total;
  String? classroom;
  String? period;
  String? branch;
  String? subjectName;
  InstructionModel copyWith({
    String? id,
    String? sourceCode,
    int? present,
    int? total,
    String? classroom,
    String? period,
    String? branch,
    String? subjectName,
  }) => InstructionModel(
    id: id ?? this.id,
    sourceCode: sourceCode ?? this.sourceCode,
    present: present ?? this.present,
    total: total ?? this.total,
    classroom: classroom ?? this.classroom,
    period: period ?? this.period,
    branch: branch ?? this.branch,
    subjectName: subjectName ?? subjectName,
  );
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['sourceCode'] = sourceCode;
    map['present'] = present;
    map['total'] = total;
    map['class'] = classroom;
    map['period'] = period;
    map['branch'] = branch;
    return map;
  }
}
