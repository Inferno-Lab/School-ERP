import 'package:json_annotation/json_annotation.dart';

part 'student.g.dart';

@JsonSerializable()
class Student {
  const Student({
    required this.id,
    required this.name,
    required this.classId,
    required this.rollNo,
    required this.dob,
    required this.bloodGroup,
    required this.house,
    required this.avatarUrl,
    required this.guardianName,
    required this.guardianPhone,
    required this.address,
    this.userId,
  });

  factory Student.fromJson(Map<String, dynamic> json) => _$StudentFromJson(json);

  final String id;
  final String? userId;
  final String name;
  final String classId;
  final String rollNo;
  final String dob;
  final String bloodGroup;
  final String house;
  final String avatarUrl;
  final String guardianName;
  final String guardianPhone;
  final String address;

  Map<String, dynamic> toJson() => _$StudentToJson(this);
}

@JsonSerializable()
class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.section,
    required this.classTeacherId,
    required this.room,
    required this.studentIds,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) =>
      _$SchoolClassFromJson(json);

  final String id;
  final String name;
  final String section;
  final String classTeacherId;
  final String room;
  final List<String> studentIds;

  String get label => '$name $section';

  Map<String, dynamic> toJson() => _$SchoolClassToJson(this);
}

@JsonSerializable()
class Teacher {
  const Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.classIds,
    this.userId,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) => _$TeacherFromJson(json);

  final String id;
  final String? userId;
  final String name;
  final String subject;
  final String email;
  final String phone;
  final String avatarUrl;
  final List<String> classIds;

  Map<String, dynamic> toJson() => _$TeacherToJson(this);
}

@JsonSerializable()
class SchoolInfo {
  const SchoolInfo({
    required this.name,
    required this.tagline,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.principal,
    required this.founded,
    required this.officeHours,
    required this.about,
  });

  factory SchoolInfo.fromJson(Map<String, dynamic> json) =>
      _$SchoolInfoFromJson(json);

  final String name;
  final String tagline;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String principal;
  final int founded;
  final String officeHours;
  final String about;

  Map<String, dynamic> toJson() => _$SchoolInfoToJson(this);
}
