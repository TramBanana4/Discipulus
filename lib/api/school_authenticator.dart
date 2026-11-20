import 'package:discipulus/api/api_provider.dart';

/// Provider-neutral credentials returned by a school authenticator.
///
/// This value is deliberately independent of Isar and OAuth endpoint details.
/// Provider-specific values that cannot be represented by the common fields
/// can be kept in [metadata] by an adapter until a stable shared need emerges.
class AuthSession {
  final ApiProviderType provider;
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime? expiresAt;
  final Map<String, Object?> metadata;

  const AuthSession({
    required this.provider,
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresAt,
    this.metadata = const {},
  });

  bool get isExpired =>
      expiresAt != null && !DateTime.now().isBefore(expiresAt!);
}

/// Owns the complete sign-in lifecycle for one school platform.
///
/// Implementations decide how interactive sign-in works (OAuth redirect,
/// PKCE, web login, or another supported flow). Shared application code must
/// not know provider-specific token URLs, scopes, or client identifiers.
abstract interface class SchoolAuthenticator {
  ApiProviderType get providerType;

  Future<AuthSession> authenticate();

  Future<AuthSession> refresh(AuthSession session);

  Future<void> logout(AuthSession session);
}
