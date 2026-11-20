import 'package:discipulus/api/api_provider.dart';

/// Stable identity for a school connected through a provider.
///
/// Keep the provider and school key alongside provider-owned user IDs. A
/// Magister person ID and a Somtoday person ID are unrelated namespaces and
/// must never be compared or persisted as if they were globally unique.
class SchoolIdentity {
  final ApiProviderType provider;
  final String schoolId;

  const SchoolIdentity({
    required this.provider,
    required this.schoolId,
  }) : assert(schoolId != '');

  String get storageKey => '${provider.name}:$schoolId';

  @override
  bool operator ==(Object other) =>
      other is SchoolIdentity &&
      other.provider == provider &&
      other.schoolId == schoolId;

  @override
  int get hashCode => Object.hash(provider, schoolId);
}

/// Provider-scoped identity for a person/student within a school.
class SchoolPersonIdentity {
  final SchoolIdentity school;
  final String externalId;

  const SchoolPersonIdentity({
    required this.school,
    required this.externalId,
  }) : assert(externalId != '');

  String get storageKey => '${school.storageKey}:$externalId';

  @override
  bool operator ==(Object other) =>
      other is SchoolPersonIdentity &&
      other.school == school &&
      other.externalId == externalId;

  @override
  int get hashCode => Object.hash(school, externalId);
}
