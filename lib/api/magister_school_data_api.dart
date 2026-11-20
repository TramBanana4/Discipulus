import 'package:discipulus/api/magister_api_dart.dart';
import 'package:discipulus/api/school_data_api.dart';
import 'package:discipulus/api/models/activities.dart';
import 'package:discipulus/api/models/assignments.dart';
import 'package:discipulus/api/models/calendar.dart';
import 'package:discipulus/api/models/schoolyears.dart';
import 'package:discipulus/api/models/studiewijzers.dart';
import 'package:flutter/material.dart';

/// Magister implementation of the shared school-data capability.
///
/// All Magister route knowledge stays in this adapter. Application code can
/// depend on [SchoolDataApi] and later receive a Somtoday implementation.
class MagisterSchoolDataApi implements SchoolDataApi {
  final Magister magister;

  const MagisterSchoolDataApi(this.magister);

  @override
  Future<List<Schoolyear>> schoolyears(
    int personId, {
    DateTimeRange? range,
  }) =>
      magister.person(personId).schoolyear().schoolyears(range: range);

  @override
  Future<List<CalendarEvent>> calendarEvents(
    int personId,
    DateTimeRange range, {
    bool includeAbsences = true,
  }) =>
      magister.person(personId).calendarEvents(
        range,
        includeAbsences: includeAbsences,
      );

  @override
  Future<List<Assignment>> assignments(int personId, DateTimeRange range) =>
      magister.person(personId).assignments(range);

  @override
  Future<List<Activity>> activities(int personId) =>
      magister.person(personId).activiteiten;

  @override
  Future<List<Studiewijzer>> studyGuides(
    int personId, {
    bool includeProjects = true,
    bool includeStudyGuides = true,
  }) =>
      magister.person(personId).studiewijzers(
        includeProjects: includeProjects,
        includeStudiewijzers: includeStudyGuides,
      );

  @override
  Future<String?> profilePicture(int personId) =>
      magister.person(personId).profilepicture;

  @override
  Future<List<ApiChild>> children(int personId) =>
      magister.person(personId).children;
}
