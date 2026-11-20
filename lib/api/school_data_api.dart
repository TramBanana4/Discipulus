import 'package:discipulus/api/api_provider.dart';
import 'package:discipulus/api/models/activities.dart';
import 'package:discipulus/api/models/account.dart';
import 'package:discipulus/api/models/assignments.dart';
import 'package:discipulus/api/models/calendar.dart';
import 'package:discipulus/api/models/schoolyears.dart';
import 'package:discipulus/api/models/studiewijzers.dart';
import 'package:flutter/material.dart';

/// Provider-neutral access to the school data used by application features.
///
/// Implementations translate provider-specific endpoints and payloads into the
/// existing application models. A provider can expose only the capabilities
/// it supports; this interface is the initial common subset.
abstract interface class SchoolDataApi {
  ApiProviderType get providerType;
  Future<List<Schoolyear>> schoolyears(
    int personId, {
    DateTimeRange? range,
  });

  Future<List<CalendarEvent>> calendarEvents(
    int personId,
    DateTimeRange range, {
    bool includeAbsences = true,
  });

  Future<List<Assignment>> assignments(int personId, DateTimeRange range);

  Future<List<Activity>> activities(int personId);

  Future<List<Studiewijzer>> studyGuides(
    int personId, {
    bool includeProjects = true,
    bool includeStudyGuides = true,
  });

  Future<String?> profilePicture(int personId);

  Future<List<ApiChild>> children(int personId);
}
