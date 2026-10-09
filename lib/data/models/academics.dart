import 'package:json_annotation/json_annotation.dart';

part 'academics.g.dart';

enum AttendanceStatus {
  @JsonValue('present')
  present,
  @JsonValue('absent')
  absent,
  @JsonValue('late')
  lateArrival,
  @JsonValue('holiday')
  holiday,
}

enum PeriodKind {
  @JsonValue('class')
  klass,
  @JsonValue('break')
  breakTime,
  @JsonValue('recess')
  recess,
}

enum HomeworkStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('submitted')
  submitted,
  @JsonValue('graded')
  graded,
}

enum ExamStatus {
  @JsonValue('upcoming')
  upcoming,
  @JsonValue('completed')
  completed,
}

@JsonSerializable()
class AttendanceDay {
  const AttendanceDay({
    required this.studentId,
    required this.date,
    required this.status,
  });

  factory AttendanceDay.fromJson(Map<String, dynamic> json) =>
      _$AttendanceDayFromJson(json);

  final String studentId;
  final DateTime date;
  final AttendanceStatus status;

  Map<String, dynamic> toJson() => _$AttendanceDayToJson(this);
}

@JsonSerializable()
class PeriodSlot {
  const PeriodSlot({
    required this.id,
    required this.subject,
    required this.start,
    required this.end,
    required this.room,
    required this.kind,
    this.teacherId,
  });

  factory PeriodSlot.fromJson(Map<String, dynamic> json) =>
      _$PeriodSlotFromJson(json);

  final String id;
  final String subject;
  final String? teacherId;
  final String start;
  final String end;
  final String room;
  final PeriodKind kind;

  Map<String, dynamic> toJson() => _$PeriodSlotToJson(this);
}

@JsonSerializable()
class TimetableDay {
  const TimetableDay({
    required this.classId,
    required this.day,
    required this.periods,
  });

  factory TimetableDay.fromJson(Map<String, dynamic> json) =>
      _$TimetableDayFromJson(json);

  final String classId;
  final String day;
  final List<PeriodSlot> periods;

  Map<String, dynamic> toJson() => _$TimetableDayToJson(this);
}

@JsonSerializable()
class HomeworkSubmission {
  const HomeworkSubmission({
    required this.studentId,
    required this.status,
    this.submittedAt,
    this.fileName,
    this.marks,
    this.grade,
    this.feedback,
  });

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) =>
      _$HomeworkSubmissionFromJson(json);

  final String studentId;
  final HomeworkStatus status;
  final DateTime? submittedAt;
  final String? fileName;
  final int? marks;
  final String? grade;
  final String? feedback;

  HomeworkSubmission copyWith({
    HomeworkStatus? status,
    DateTime? submittedAt,
    String? fileName,
    int? marks,
    String? grade,
    String? feedback,
  }) {
    return HomeworkSubmission(
      studentId: studentId,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      fileName: fileName ?? this.fileName,
      marks: marks ?? this.marks,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
    );
  }

  Map<String, dynamic> toJson() => _$HomeworkSubmissionToJson(this);
}

@JsonSerializable()
class Homework {
  const Homework({
    required this.id,
    required this.classId,
    required this.subject,
    required this.title,
    required this.description,
    required this.assignedOn,
    required this.dueOn,
    required this.teacherId,
    required this.maxMarks,
    required this.attachments,
    required this.submissions,
  });

  factory Homework.fromJson(Map<String, dynamic> json) => _$HomeworkFromJson(json);

  final String id;
  final String classId;
  final String subject;
  final String title;
  final String description;
  final DateTime assignedOn;
  final DateTime dueOn;
  final String teacherId;
  final int maxMarks;
  final List<String> attachments;
  final List<HomeworkSubmission> submissions;

  HomeworkSubmission? forStudent(String studentId) {
    for (final submission in submissions) {
      if (submission.studentId == studentId) return submission;
    }
    return null;
  }

  Homework copyWith({List<HomeworkSubmission>? submissions}) => Homework(
    id: id,
    classId: classId,
    subject: subject,
    title: title,
    description: description,
    assignedOn: assignedOn,
    dueOn: dueOn,
    teacherId: teacherId,
    maxMarks: maxMarks,
    attachments: attachments,
    submissions: submissions ?? this.submissions,
  );

  Map<String, dynamic> toJson() => _$HomeworkToJson(this);
}

@JsonSerializable()
class Exam {
  const Exam({
    required this.id,
    required this.name,
    required this.classId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.subjects,
  });

  factory Exam.fromJson(Map<String, dynamic> json) => _$ExamFromJson(json);

  final String id;
  final String name;
  final String classId;
  final DateTime startDate;
  final DateTime endDate;
  final ExamStatus status;
  final List<String> subjects;

  Map<String, dynamic> toJson() => _$ExamToJson(this);
}

@JsonSerializable()
class SubjectMark {
  const SubjectMark({
    required this.subject,
    required this.marks,
    required this.maxMarks,
    required this.grade,
  });

  factory SubjectMark.fromJson(Map<String, dynamic> json) =>
      _$SubjectMarkFromJson(json);

  final String subject;
  final int marks;
  final int maxMarks;
  final String grade;

  Map<String, dynamic> toJson() => _$SubjectMarkToJson(this);
}

@JsonSerializable()
class TrendPoint {
  const TrendPoint({required this.label, required this.percent});

  factory TrendPoint.fromJson(Map<String, dynamic> json) =>
      _$TrendPointFromJson(json);

  final String label;
  final double percent;

  Map<String, dynamic> toJson() => _$TrendPointToJson(this);
}

@JsonSerializable()
class ExamResult {
  const ExamResult({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.overallPercent,
    required this.grade,
    required this.rank,
    required this.totalStudents,
    required this.subjects,
    required this.trend,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) =>
      _$ExamResultFromJson(json);

  final String id;
  final String examId;
  final String studentId;
  final double overallPercent;
  final String grade;
  final int rank;
  final int totalStudents;
  final List<SubjectMark> subjects;
  final List<TrendPoint> trend;

  Map<String, dynamic> toJson() => _$ExamResultToJson(this);
}
