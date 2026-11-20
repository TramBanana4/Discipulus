# Somtoday adapter handoff

This folder is reserved for the Somtoday implementation. No endpoint, OAuth
flow, client identifier, scope, or response shape is assumed here.

## Required pieces

1. **Authentication**
   - Implement `SchoolAuthenticator`.
   - Return an `AuthSession` with `provider: ApiProviderType.somtoday`.
   - Keep redirects, PKCE/state validation, token exchange, refresh, and logout
     inside the Somtoday authenticator.
   - Never persist client secrets in the app or commit them to the repository.

2. **HTTP client**
   - Implement `ApiProviderClient` with
     `providerType == ApiProviderType.somtoday`.
   - Own the Dio configuration, authorization headers, refresh/retry policy,
     and Somtoday-specific error translation.

3. **School data**
   - Implement `SchoolDataApi` and set its `providerType` to
     `ApiProviderType.somtoday`.
   - Map Somtoday responses into the shared application models at the adapter
     boundary.
   - If a capability is not available from the verified API, expose that
     limitation explicitly rather than returning fabricated data.

4. **Registration**
   - Register the completed adapters in the application's composition root
     using `ApiProviderRegistry.register(ApiProviderType.somtoday, ...)`.
   - Build a `SchoolApiProvider` from the Somtoday client, authenticator, and
     school-data adapter.

## Identity and persistence

Use `SchoolIdentity` and `SchoolPersonIdentity` to namespace provider IDs.
Do not reuse a Magister numeric person ID as a Somtoday ID.

The current Isar `DiscipulusAccount` schema is still Magister-shaped. Before
enabling Somtoday accounts, add provider and school identity fields through an
additive schema migration, regenerate Isar code, and preserve a compatibility
path for existing Magister records. Do not repurpose `endPoint`,
`magisterUuid`, or `TokenSet` for Somtoday.

## Completion checklist

- [ ] Confirm official/authorized Somtoday authentication and API contract.
- [ ] Implement and test the Somtoday authenticator.
- [ ] Implement the Somtoday HTTP client and credential lifecycle.
- [ ] Map verified endpoints to shared school-data models.
- [ ] Add provider-aware Isar persistence and migration tests.
- [ ] Register Somtoday in the app composition root.
- [ ] Add integration tests with sanitized fixtures.
