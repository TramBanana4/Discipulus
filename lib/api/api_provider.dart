import 'package:dio/dio.dart';

/// Identifies the school platform behind an API client.
///
/// Keep provider-specific authentication and endpoint details out of shared
/// application services. New integrations (for example Somtoday) should
/// implement [ApiProviderClient] rather than extending Magister-specific code.
enum ApiProviderType {
  magister,
  somtoday,
}

/// The provider-neutral HTTP/authentication boundary used by API clients.
///
/// This is intentionally a small first extraction: domain operations and
/// normalized models will be moved behind provider-neutral interfaces in
/// follow-up refactors. A provider owns its Dio configuration and credential
/// refresh lifecycle.
abstract interface class ApiProviderClient {
  ApiProviderType get providerType;

  Dio get dio;

  /// Refresh credentials before retrying a request when required.
  Future<void> refreshCredentials();
}
