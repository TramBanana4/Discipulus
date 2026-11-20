import 'package:discipulus/api/api_provider.dart';
import 'package:discipulus/api/school_authenticator.dart';
import 'package:discipulus/api/school_data_api.dart';

/// The runtime components required to connect an account to one school
/// platform. The bundle keeps transport, authentication, and school-data
/// access paired so they cannot accidentally come from different providers.
class SchoolApiProvider {
  final ApiProviderClient client;
  final SchoolAuthenticator authenticator;
  final SchoolDataApi schoolData;

  SchoolApiProvider({
    required this.client,
    required this.authenticator,
    required this.schoolData,
  }) {
    final provider = client.providerType;
    if (authenticator.providerType != provider) {
      throw ArgumentError(
        'Authenticator provider (${authenticator.providerType}) does not '
        'match client provider ($provider).',
      );
    }
  }

  ApiProviderType get providerType => client.providerType;
}

/// Creates provider-specific adapters without making shared app code depend
/// on concrete Magister or Somtoday classes.
///
/// Register Magister and Somtoday from the composition root once their
/// concrete authenticators and adapters are available.
class ApiProviderRegistry {
  final Map<ApiProviderType, SchoolApiProvider Function()> _factories = {};

  Iterable<ApiProviderType> get registeredProviders =>
      List.unmodifiable(_factories.keys);

  bool supports(ApiProviderType provider) => _factories.containsKey(provider);

  void register(
    ApiProviderType provider,
    SchoolApiProvider Function() factory,
  ) {
    if (_factories.containsKey(provider)) {
      throw StateError('An API provider is already registered: $provider');
    }
    _factories[provider] = factory;
  }

  SchoolApiProvider create(ApiProviderType provider) {
    final factory = _factories[provider];
    if (factory == null) {
      throw UnsupportedError(
        'No API implementation has been registered for $provider yet.',
      );
    }

    final instance = factory();
    if (instance.providerType != provider) {
      throw StateError(
        'Registered factory for $provider returned ${instance.providerType}.',
      );
    }
    return instance;
  }
}
