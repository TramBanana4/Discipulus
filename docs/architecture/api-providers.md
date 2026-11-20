# API provider architecture

## Goal

Support multiple school platforms (initially Magister and Somtoday) without
letting provider-specific authentication, identifiers, endpoints, or response
formats leak into shared application features.

The existing Magister integration is the compatibility baseline. Somtoday
must be added as a separate provider, not by adding Somtoday conditionals to
Magister routes.

## Current state

- `ApiProviderType` identifies the provider (`magister`, `somtoday`).
- `ApiProviderClient` defines the first shared HTTP/authentication boundary:
  provider identity, Dio client, and credential refresh.
- `Magister` implements this contract.
- `DummyMagister` remains the offline implementation and follows the same
  Magister client contract.

This is an incremental extraction. The account and profile layers still call
Magister-specific routes and models. They are not provider-neutral yet.

## Target boundaries

```
UI
 |
Application/domain services
 |-- SchoolDataApi       calendar, school years, assignments, grades
 |-- MessagingApi        inbox, compose, attachments
 |-- AttendanceApi       absences and attendance
 |
Provider adapters
 |-- Magister adapter    Magister OAuth, endpoints, DTO mapping
 |-- Somtoday adapter    Somtoday authentication, endpoints, DTO mapping
 |
Shared application models + persistence
```

Keep capabilities separate instead of creating one large interface. A
provider may implement only the capabilities it actually supports. The UI
should be able to ask whether a capability is available rather than infer
support from a provider name.

## Rules for the implementation

1. **Provider-owned authentication.** OAuth URLs, client IDs, scopes, token
   refresh requests, and login flows belong to the provider adapter. Do not
   put Magister's token endpoint in a provider-neutral token/session type.
2. **Normalized domain models.** Convert provider responses at the adapter
   boundary into shared models. Do not make shared features parse raw
   Magister or Somtoday JSON.
3. **Stable namespaced identifiers.** External IDs are not assumed to be
   globally unique. Persist provider and school identity with external IDs;
   do not silently reinterpret existing Magister IDs.
4. **Capability-based features.** Calendar, assignments, grades, messages,
   and attendance can have different support levels per provider.
5. **Backward-compatible persistence.** Existing Isar account records must
   continue to load. Additive schema changes and an explicit migration or
   compatibility path are required before replacing fields such as
   `endPoint`, `tokenSet`, or `magisterUuid`.
6. **No speculative Somtoday endpoints.** Implement Somtoday requests only
   after confirming the authentication flow and API contract. Keep its adapter
   boundary ready without inventing endpoints or response shapes.

## Incremental migration plan

1. Establish the provider client contract (in progress).
2. Extract provider-neutral domain capability interfaces and shared models.
3. Introduce provider-owned authenticators and a provider-neutral persisted
   session, while retaining a reader for existing Magister account records.
4. Move application features from direct Magister route calls to capability
   interfaces. Keep a Magister adapter as the first implementation and verify
   parity.
5. Add the Somtoday authenticator and adapters one capability at a time.
6. Add adapter tests, persistence compatibility tests, and regression tests
   before enabling Somtoday in the login UI.

## Current limitations

The current `ApiProviderClient` is deliberately not presented as the final
application API. It is only the transport/authentication seam. A Somtoday
client should not be considered feature-integrated until the account,
profile, and feature layers consume provider-neutral capabilities.
