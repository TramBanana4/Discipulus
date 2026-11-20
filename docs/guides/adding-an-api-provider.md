# Een nieuwe API provider toevoegen

## Is "API provider" de juiste naam?
Ja. In deze codebase is een API provider een implementatie van een schoolplatform. De provider bestaat uit transport, authenticatie en een of meer capability-adapters. "Schoolplatformprovider" is een begrijpelijk alternatief, maar ApiProvider past bij de bestaande ApiProviderType en ApiProviderClient.

## Huidige architectuur
- lib/api/api_provider.dart: ApiProviderType en ApiProviderClient (providerType, Dio-client, refreshCredentials).
- lib/api/school_authenticator.dart: SchoolAuthenticator en AuthSession.
- lib/api/school_data_api.dart: gedeeld contract voor schoolgegevens.
- lib/api/magister_school_data_api.dart: voorbeeldadapter voor Magister.
- lib/api/provider_registry.dart: SchoolApiProvider bundelt client, authenticator en SchoolDataApi; ApiProviderRegistry maakt providers via factories.
- lib/api/school_identity.dart: provider- en schoolgebonden identiteiten.
- lib/api/somtoday/README.md: Somtoday-handoff.

Let op: dit is een tussenstap. De accountopslag, berichten, rechten en delen van profielverwerking zijn nog Magister-specifiek. De registry is nog niet aangesloten op de centrale app-opbouw (composition root). SchoolDataApi gebruikt nog enkele bestaande modellen die niet volledig provider-neutraal zijn.

## Stap 1. Verifieer eerst het echte API-contract
Verzamel officiële of geautoriseerde documentatie voor login, redirect/state/PKCE waar van toepassing, tokenvernieuwing, logout, schoolidentiteit, persoon-ID's, endpoints, rechten, paginering, rate limits, foutformaten en bijlagen. Leid geen Somtoday-endpoints of authenticatie af uit Magister. Niet-ondersteunde functies moeten expliciet als niet ondersteund worden weergegeven, niet met nepdata worden gevuld.

## Stap 2. Maak de HTTP-client
Maak bijvoorbeeld lib/api/<provider>_api_dart.dart en implementeer ApiProviderClient:
- providerType retourneert de juiste ApiProviderType.
- dio levert de geconfigureerde HTTP-client.
- refreshCredentials verzorgt de provider-eigen credentialvernieuwing.
Configureer base URL, headers, time-outs, foutafhandeling en retrybeleid binnen de adapter. Isoleer clients/tokens per account. Magister in lib/api/magister_api_dart.dart is een voorbeeld van het contract, niet van endpoints of OAuth die je moet kopiëren.

## Stap 3. Maak de authenticator
Maak bijvoorbeeld lib/api/<provider>_authenticator.dart en implementeer SchoolAuthenticator:
- providerType;
- authenticate() voor interactieve login;
- refresh(session);
- logout(session).
Geef een AuthSession terug met provider, accessToken, refreshToken indien aanwezig, idToken indien aanwezig, expiresAt en alleen noodzakelijke metadata. Bewaar geen secrets hardcoded in de app of repository. AuthSession is een runtimecontract; ontwerp apart hoe credentials veilig in Isar/platformopslag worden bewaard.
De bestaande Magister-loginflow gebruikt SchoolAuthenticator nog niet. Alleen een nieuwe authenticator maken maakt een provider dus nog niet aanmeldbaar.

## Stap 4. Maak capability-adapters
Begin met SchoolDataApi. Maak bijvoorbeeld SomtodaySchoolDataApi die alle methoden implementeert: schoolyears, calendarEvents, assignments, activities, studyGuides, profilePicture en children. Gebruik MagisterSchoolDataApi als voorbeeld van de adaptervorm, niet van de routes of datamodellen.
Vertaal providerresponses aan de adaptergrens naar gedeelde domeinmodellen. Controleer bestaande types uit lib/api/models: ApiChild en andere modellen kunnen provider-specifieke aannames bevatten. Normaliseer die eerst als nodig. Maak aparte capability-contracten voor bijvoorbeeld berichten en aanwezigheid in plaats van één allesomvattende API. Een provider mag alleen de capabilities aanbieden die werkelijk ondersteund worden.

## Stap 5. Bundel en registreer
SchoolApiProvider controleert al dat client, authenticator en schoolData dezelfde providerType hebben. Registreer de factory vanuit één centrale composition root:

~~~dart
registry.register(
  ApiProviderType.somtoday,
  () => SchoolApiProvider(
    client: /* concrete providerclient */,
    authenticator: /* concrete authenticator */,
    schoolData: /* concrete schooldata-adapter */,
  ),
);
~~~

Dit is een structuurvoorbeeld, geen direct compileerbare implementatie. De commentaren moeten worden vervangen door concrete objecten. Maak eerst de centrale plek waar app-services worden opgebouwd en registreer Magister daar ook via dezelfde registry. Schermen mogen niet zelf provider-adapters construeren.

## Stap 6. Gebruik provider-scoped identiteiten
Gebruik SchoolIdentity(provider, schoolId) en SchoolPersonIdentity(school, externalId). Een Magister-ID en Somtoday-ID zijn geen uitwisselbare globale sleutels. Gebruik samengestelde sleutels voor opslag en cache. De huidige Isar DiscipulusAccount is nog Magister-vormig; schakel een nieuwe provider niet in voordat providerbewuste opslag en migratie gereed zijn.

## Stap 7. Tests
Test minimaal:
- providerType van client, authenticator en elke capability;
- mismatch tussen providercomponenten en registry factory;
- login, mislukte login, refresh, verlopen/ontbrekend token en logout;
- headers en isolatie tussen gelijktijdige accounts;
- mapping met geanonimiseerde responsefixtures;
- lege resultaten, paginering, foutafhandeling en niet-ondersteunde functies;
- provider-/schoolgebonden identiteit en Isar-migratie.

## Volgorde voor een eerste Somtoday-integratie
- [ ] Verifieer officieel/authorized API- en authenticatiecontract.
- [ ] Kies één capability die aantoonbaar beschikbaar is.
- [ ] Implementeer client en authenticator.
- [ ] Implementeer de capability-adapter en normaliseer de modellen.
- [ ] Maak accountopslag providerbewust en migreer bestaande Magister-records.
- [ ] Sluit registry aan op composition root en registreer Magister en Somtoday.
- [ ] Sluit de loginflow aan op SchoolAuthenticator.
- [ ] Voeg tests toe en schakel de provider pas daarna in de UI in.

Zie ook ../architecture/api-providers.md, ../../lib/api/somtoday/README.md en account-storage-and-messaging-migration.md.
