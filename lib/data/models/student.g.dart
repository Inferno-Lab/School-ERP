// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
  id: json['id'] as String,
  name: json['name'] as String,
  classId: json['classId'] as String,
  rollNo: json['rollNo'] as String,
  dob: json['dob'] as String,
  bloodGroup: json['bloodGroup'] as String,
  house: json['house'] as String,
  avatarUrl: json['avatarUrl'] as String,
  guardianName: json['guardianName'] as String,
  guardianPhone: json['guardianPhone'] as String,
  address: json['address'] as String,
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
  'id': instance.id,
  'userId': ?instance.userId,
  'name': instance.name,
  'classId': instance.classId,
  'rollNo': instance.rollNo,
  'dob': instance.dob,
  'bloodGroup': instance.bloodGroup,
  'house': instance.house,
  'avatarUrl': instance.avatarUrl,
  'guardianName': instance.guardianName,
  'guardianPhone': instance.guardianPhone,
  'address': instance.address,
};

SchoolClass _$SchoolClassFromJson(Map<String, dynamic> json) => SchoolClass(
  id: json['id'] as String,
  name: json['name'] as String,
  section: json['section'] as String,
  classTeacherId: json['classTeacherId'] as String,
  room: json['room'] as String,
  studentIds: (json['studentIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SchoolClassToJson(SchoolClass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'section': instance.section,
      'classTeacherId': instance.classTeacherId,
      'room': instance.room,
      'studentIds': instance.studentIds,
    };

Teacher _$TeacherFromJson(Map<String, dynamic> json) => Teacher(
  id: json['id'] as String,
  name: json['name'] as String,
  subject: json['subject'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  avatarUrl: json['avatarUrl'] as String,
  classIds: (json['classIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  userId: json['userId'] as String?,
);

Map<String, dynamic> _$TeacherToJson(Teacher instance) => <String, dynamic>{
  'id': instance.id,
  'userId': ?instance.userId,
  'name': instance.name,
  'subject': instance.subject,
  'email': instance.email,
  'phone': instance.phone,
  'avatarUrl': instance.avatarUrl,
  'classIds': instance.classIds,
};

SchoolInfo _$SchoolInfoFromJson(Map<String, dynamic> json) => SchoolInfo(
  name: json['name'] as String,
  tagline: json['tagline'] as String,
  address: json['address'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String,
  website: json['website'] as String,
  principal: json['principal'] as String,
  founded: (json['founded'] as num).toInt(),
  officeHours: json['officeHours'] as String,
  about: json['about'] as String,
);

Map<String, dynamic> _$SchoolInfoToJson(SchoolInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'tagline': instance.tagline,
      'address': instance.address,
      'phone': instance.phone,
      'email': instance.email,
      'website': instance.website,
      'principal': instance.principal,
      'founded': instance.founded,
      'officeHours': instance.officeHours,
      'about': instance.about,
    };
