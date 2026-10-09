import 'dart:convert';
import 'dart:math';

import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/services/session_bus.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/date_seed.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/models/student.dart';
import 'package:edunest/data/models/user.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class MockJsonDataSource {
  final _random = Random();
  var _ready = false;

  List<AppUser> users = [];
  List<Student> students = [];
  List<SchoolClass> classes = [];
  List<Teacher> teachers = [];
  List<AttendanceDay> attendance = [];
  List<TimetableDay> timetable = [];
  List<Homework> homework = [];
  List<Exam> exams = [];
  List<ExamResult> results = [];
  List<FeeAccount> fees = [];
  List<Notice> notices = [];
  List<SchoolEvent> events = [];
  List<ChatThread> threads = [];
  List<ChatMessage> messages = [];
  List<LibraryBook> books = [];
  List<TransportInfo> transport = [];
  List<LeaveRequest> leaves = [];
  List<GalleryAlbum> albums = [];
  List<AppNotification> notifications = [];
  SchoolInfo? school;
  final Map<String, Map<String, int>> marks = {};

  Future<void> ensureLoaded() async {
    if (_ready) return;
    users = await _list('users.json', AppUser.fromJson);
    students = await _list('students.json', Student.fromJson);
    classes = await _list('classes.json', SchoolClass.fromJson);
    teachers = await _list('teachers.json', Teacher.fromJson);
    attendance = await _list('attendance.json', AttendanceDay.fromJson);
    timetable = await _list('timetable.json', TimetableDay.fromJson);
    homework = await _list('homework.json', Homework.fromJson);
    exams = await _list('exams.json', Exam.fromJson);
    results = await _list('results.json', ExamResult.fromJson);
    fees = await _list('fees.json', FeeAccount.fromJson);
    notices = await _list('notices.json', Notice.fromJson);
    events = await _list('events.json', SchoolEvent.fromJson);
    threads = await _list('chat_threads.json', ChatThread.fromJson);
    messages = await _list('messages.json', ChatMessage.fromJson);
    books = await _list('library_books.json', LibraryBook.fromJson);
    transport = await _list('transport.json', TransportInfo.fromJson);
    leaves = await _list('leave_requests.json', LeaveRequest.fromJson);
    albums = await _list('gallery.json', GalleryAlbum.fromJson);
    notifications = await _list('notifications.json', AppNotification.fromJson);
    final info = await _object('school_info.json');
    school = SchoolInfo.fromJson(info);
    _ready = true;
  }

  Future<T> guard<T>(T Function() body) async {
    await ensureLoaded();
    final span = AppConfig.mockDelayMaxMs - AppConfig.mockDelayMinMs;
    final extra = span <= 0 ? 0 : _random.nextInt(span + 1);
    final wait = AppConfig.mockDelayMinMs + extra;
    if (wait > 0) {
      await Future<void>.delayed(Duration(milliseconds: wait));
    }
    if (AppConfig.simulateErrors.value) {
      throw const AppException('errors.simulated');
    }
    return body();
  }

  void bump() {
    if (Get.isRegistered<SessionBus>()) Get.find<SessionBus>().bump();
  }

  String nextId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  Future<List<T>> _list<T>(
    String file,
    T Function(Map<String, dynamic> json) decode,
  ) async {
    final raw = await rootBundle.loadString('assets/mock/$file');
    final resolved = DateSeed.resolve(jsonDecode(raw));
    if (resolved is! List) {
      throw const AppException('errors.bad_mock');
    }
    return resolved
        .map((item) => decode(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> _object(String file) async {
    final raw = await rootBundle.loadString('assets/mock/$file');
    final resolved = DateSeed.resolve(jsonDecode(raw));
    return Map<String, dynamic>.from(resolved as Map);
  }
}
