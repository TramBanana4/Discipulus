# Accountopslag en berichten: resterende migratie

Dit document beschrijft concreet wat nog moet gebeuren om accountopslag en berichten los te maken van Magister. Dit werk is nog niet uitgevoerd.

## 1. Accountopslag: huidige koppelingen

De hoofdimplementatie staat in lib/models/account.dart.

| Huidig onderdeel | Probleem | Gewenste wijziging |
| --- | --- | --- |
| DiscipulusAccount.id (int) | Beschreven als Magister-ID | Externe account-/persoon-ID met provider- en schoolcontext; kies string als IDs niet gegarandeerd numeriek zijn |
| TokenSet? tokenSet | Magister-tokenmodel met Magister-refreshgedrag | Provider-neutraal persistent sessiemodel, los van authenticatiecode |
| String endPoint | Magister API-endpoint en onderdeel van UUID | Expliciete provider- en schoolidentiteit; endpoint alleen als providerconfiguratie nodig is |
| String? magisterUuid | Magister UUID voor aanvullende agenda-items | Alleen in Magister-adapter/accountmetadata of Magister-capability houden |
| Magister get api | Maakt altijd Magister of DummyMagister | Providerbundle via registry/factory laten resolven |
| schoolData getter | Bouwt altijd MagisterSchoolDataApi(api) | SchoolDataApi van de opgeslagen provider gebruiken |
| fill()/refreshPermissions() | Gebruiken ApiAccount, ApiChild en Magister-permissions | Gedeelde account-/profielmodellen en provider-capabilities gebruiken |

De huidige account-UUID wordt berekend uit endPoint + id. Dit is geen duurzame generieke sleutel. SchoolIdentity en SchoolPersonIdentity bestaan al in lib/api/school_identity.dart, maar zijn nog niet geïntegreerd in Isar.

Ook Profile is nog providergebonden: numerieke id, UUID afgeleid van account-UUID plus ID, magisterBase64ProfilePicture en ouder-kindverwerking via Magister ApiAccount/ApiChild. Deze onderdelen moeten mee veranderen. Anders wordt alleen de accountlaag generiek terwijl profielen nog Magister-identiteiten verwachten.

## 2. Concreet werk voor accountopslag

1. **Identiteit vastleggen.** Definieer wat een account is: schoollogin, persoon binnen school of ouderlogin met gekoppelde profielen. Sla provider, school-ID en externe persoon/account-ID op. Maak samengestelde sleutels; ga nooit uit van wereldwijd unieke numerieke IDs.
2. **Sessies persistent maken.** Maak een Isar-opslagmodel voor provider, access token, refresh token, ID-token, vervaltijd en versieerbare metadata. AuthSession is een runtimecontract, niet automatisch het definitieve Isar-schema. Houd serialisatie/opslag gescheiden van authenticatie. Onderzoek veilige opslag van secrets.
3. **Providercomponenten resolven.** Verwijder de vaste Magister get api uit gedeelde accountlogica. Laat accountservices de juiste SchoolApiProvider via registry/factory ophalen. Behoud offline accounts als expliciete offline implementatie.
4. **Profielen normaliseren.** Maak Profile-ID's provider-/schoolscoped. Herzie Profile.uuid, gekoppelde kinderen en magisterBase64ProfilePicture (generieke oorspronkelijke profielfoto of provider-specifieke brondata).
5. **Rechten abstraheren.** Permission/PermissionType zijn nu Magister-georiënteerd en worden gebruikt voor schermen en mutaties. Maak gedeelde capabilities/rechten en vertaal providerrechten in de adapter. Onderscheid niet ondersteund, niet gemachtigd en netwerkfout.
6. **Isar veilig migreren.** Voeg schema-velden additief toe. Hergebruik endPoint, tokenSet of magisterUuid niet met een nieuwe betekenis. Migreer oude records expliciet naar provider=Magister en behoud tijdelijk een compatibele reader indien nodig. Genereer Isar-code opnieuw na schemawijzigingen.
7. **Alle accountflows bijwerken.** Login, account toevoegen, refresh, logout, verwijderen, offline account en herstel moeten het nieuwe model gebruiken. Werk ook utils/account_manager.dart bij: checkAccountPermissions() loopt nu alle accounts langs en roept Magister-specifieke refreshPermissions() aan. Controleer actieve profielselectie, accountwisselen, widgets en live activities op aannames over UUID.
8. **Migratietests schrijven.** Test bestaande databasebestanden, lege databases, offline/gedeeltelijke accounts, meerdere accounts van één school en accounts van verschillende providers. Controleer dat profielen, links en lokale gegevens behouden blijven.

## 3. Berichten: huidige Magister-koppelingen

Het belangrijkste model staat in lib/api/models/messages.dart. Mappen ophalen gebeurt ook in Profile.getBerichtMappen in lib/models/account.dart.

| Locatie | Huidige Magister-afhankelijkheid | Nodige verandering |
| --- | --- | --- |
| Profile.getBerichtMappen | account.api.messages.folders; maakt conceptenmap met /api/berichten/concepten | Ophalen van mappen en conceptenmap-semantiek naar MessagingApi |
| Bericht.fill() | Magister.dio, ItemLinks en verwijderen van /api/ uit links | Adapter haalt details en bijlagen op; gedeelde modellen kennen geen route |
| Bericht.markAsRead() | PATCH /berichten/berichten met Magister JSON Patch | MessagingApi.markAsRead met gedeeld bericht-ID |
| Bericht.moveToFolder() | api.messages.moveToFolder | MessagingApi.moveMessage |
| Bericht.remove() | Concepten verwijderen via /berichten/concepten; map-ID 3 voor verwijderd | Adapteroperaties; geen hardcoded map-ID's in gedeelde logica |
| Bericht.syncConcept() | PUT Magister-conceptendpoint en Magister-payload | Gedeeld compose-/draft-contract |
| MessagesFolder.getMessages() | berichtenLink, Magister-queryparameters en responseveld items | Adapter verzorgt zoeken, filters, paginering en mapping |
| MessagesFolder.createChildFolder/editFolder/remove | Rechtstreekse Dio-requests en Magister-mapsemantiek | Folderbeheer via capability-methoden |
| fromMap-methoden | Provider-JSON parsing in Isar-modellen | DTO parsing en mapping in adapter |
| Bericht.fromMapAnnouncement() | Controleert .magister.net in endPoint | Aankondigingen als aparte bron/capability behandelen |

Bericht en MessagesFolder combineren momenteel JSON-parsing, Isar-opslag en netwerkacties. ItemLinks bevat providerlinks. Bericht.uuid en MessagesFolder.uuid combineren profiel-UUID met numerieke ID; zulke IDs kunnen bij een andere provider botsen. Aankondigingen van Discipulus zijn bovendien een aparte bron en moeten niet worden voorgesteld als gewone provider-mail.

## 4. Gewenste berichtenarchitectuur

Introduceer een aparte MessagingApi capability. Laat de interface domeinmodellen en parameters gebruiken, nooit Dio, URL's of provider-JSON. De benodigde operaties zijn:
- mappen ophalen en ondersteunde mapacties beschrijven;
- berichten ophalen met paginering en filters;
- berichtdetails ophalen;
- bijlagen ophalen/downloaden;
- gelezen/ongelezen wijzigen;
- verplaatsen en verwijderen;
- concept opslaan/verzenden;
- ontvangers zoeken, indien ondersteund.

Maak ondersteuning expliciet. Een provider kan bijvoorbeeld wel berichten lezen maar geen eigen mappen of BCC ondersteunen. Maak capabilitybeschrijvingen of optionele interfaces; neem niet aan dat iedere methode op elk platform beschikbaar is.

Maak gedeelde modellen, bijvoorbeeld:
- Message: lokale ID, provider-scoped externe ID, onderwerp, inhoud, afzender, ontvangers, tijdstippen, leesstatus, prioriteit en bijlage-indicatie.
- MessageFolder: lokale ID, externe ID, naam, ongelezen aantal en foldertype.
- MessageAttachment: externe ID, bestandsnaam, MIME-type/grootte indien beschikbaar en downloadstatus.
- MessageRecipient: weergavenaam en provider-scoped ontvangerreferentie.
- MessageQuery: zoekterm, leesstatus, prioriteit, bijlagefilter, map en paginering.
- ComposeMessage: onderwerp, inhoud, ontvangers, CC/BCC, prioriteit en bijlagen.

Gebruik geen Magister ItemLinks als gedeelde identifier. De adapter mag intern een route/cursor bewaren als de API dat vereist, maar de UI mag die niet interpreteren.

Bestaande schermen gebruiken waarschijnlijk Bericht, MessagesFolder, Ontvanger en ItemLinks. Migreer gecontroleerd: introduceer contract en modellen, implementeer MagisterMessagingApi, migreer schermen en acties, en verwijder pas daarna de oude routeafhankelijkheden.

## 5. Uitvoerbare migratievolgorde

### Fase A: accountopslag
- [ ] Alle create/read/update/delete-paden van DiscipulusAccount inventariseren.
- [ ] Account-, school- en persoonidentiteit definiëren.
- [ ] Isar-schema voor provider en sessie ontwerpen.
- [ ] Migratie voor bestaande Magister-records schrijven.
- [ ] Profile-ID, UUID, profielfoto en gekoppelde kinderen herzien.
- [ ] Login en refresh aansluiten op SchoolAuthenticator.
- [ ] Permission-refresh provider-/capability-neutraal maken.
- [ ] Migratie-, offline- en multi-accounttests toevoegen.

### Fase B: berichtencontract
- [ ] Alle schermen en acties die huidige berichtmodellen gebruiken inventariseren.
- [ ] MessagingApi en gedeelde query-/domeinmodellen definiëren.
- [ ] Niet-ondersteunde acties expliciet modelleren.
- [ ] Provider-scoped IDs bepalen voor bericht, map, bijlage en ontvanger.
- [ ] Aankondigingen als aparte bron behandelen.

### Fase C: Magister achter het contract zetten
- [ ] MagisterMessagingApi implementeren met bestaande routes/payloads.
- [ ] Dio-requests uit Bericht en MessagesFolder naar de adapter verplaatsen.
- [ ] Magister JSON parsing naar DTO's/mappers verplaatsen.
- [ ] UI tijdelijk werkend houden via mapping/compatibiliteitslaag.
- [ ] Lezen, zoeken, paginering, details, bijlagen, gelezen-status, verplaatsen, verwijderen, mappen en concepten testen.

### Fase D: opslag en UI
- [ ] Isar-modellen aanpassen zonder bestaande berichten te verliezen.
- [ ] Oude bericht-/map-ID's migreren naar provider-scoped externe sleutels.
- [ ] Schermen alleen gedeelde modellen en MessagingApi laten gebruiken.
- [ ] Spotlight-indexering, lokale aankondigingen en offlinegedrag controleren.
- [ ] Oude Magister-routevelden pas verwijderen als alle callsites gemigreerd zijn.

### Fase E: Somtoday
- [ ] Ondersteunde berichtfuncties controleren in het geverifieerde Somtoday-contract.
- [ ] Alleen daadwerkelijk ondersteunde MessagingApi-operaties implementeren.
- [ ] Mappingtests met geanonimiseerde fixtures toevoegen.
- [ ] Testen dat overlappende externe IDs van Magister en Somtoday niet botsen.
- [ ] Berichten pas inschakelen als opslag, rechten en UI de capability correct afhandelen.

## 6. Ontwerpbeslissingen die eerst vast moeten staan
1. Wat is precies een account en hoe verhoudt een ouderlogin zich tot meerdere leerlingprofielen?
2. Hoe worden credentials beveiligd en wat doen logout/accountverwijdering met secrets?
3. Hoe onderscheiden we niet ondersteund, niet gemachtigd en tijdelijk onbeschikbaar?
4. Hoe blijven favorieten, berichten, opdrachten, spotlight-items en Isar-links behouden bij UUID-wijzigingen?
5. Welke data blijft offline leesbaar als sessie of provideradapter ontbreekt?

## 7. Klaar-criteria
Accountopslag is pas klaar als bestaande Magister-databases zonder dataverlies openen, login/refresh/logout blijven werken en account-/profielidentiteiten provider-scoped zijn.

Berichten zijn pas klaar als gedeelde modellen geen Magister-routekennis bevatten, alle netwerkacties via MessagingApi lopen, Magister-regressietests slagen en een tweede provider veilig geen of slechts een deel van de messaging-capabilities kan aanbieden. Een Somtoday-login alleen betekent dus niet dat Somtoday-berichten werken.
