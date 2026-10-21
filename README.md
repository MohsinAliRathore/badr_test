# badrgo Ops Console

Flutter web operations dashboard for the **badr Technology** take-home assessment. Talks to the hosted sandbox at `https://sandbox.badrgo.com`.

## Run

```bash
flutter pub get
flutter run -d chrome --dart-define=API_URL=https://sandbox.badrgo.com
```

Override the API host with `--dart-define=API_URL=...` (no secrets in the repo).

Demo password for all accounts: `Demo@12345`.

```bash
flutter test
flutter build web --dart-define=API_URL=https://sandbox.badrgo.com
```

## Architecture

Clean **MVVM + BLoC**, organised **by feature**:

```
feature/
  presentation/   View (widgets) + ViewModel (Bloc/Cubit)
  domain/         entities, repository interfaces
  data/           repository impls, DTO mappers, transport calls
```

Dependencies point inward only: **View → ViewModel → Domain ← Data**.

Shared transports live under `lib/core/network/` and are owned by `AuthBloc` / `RealtimeHub` (start on sign-in, stop on sign-out / 401). Typed clients live under `lib/generated/` (B7).

### Transports (required mapping)

| Transport | Use |
|-----------|-----|
| **REST** (Dio) | Sign-in / sign-out, `GET /api/me`, every write (assign, cancel, refund, acknowledge, users, drivers, riders), health, chat history |
| **GraphQL** | KPIs, trip list & detail, drivers/riders lists, cities |
| **SSE** (`package:web` EventSource) | Live KPIs, trip list patches, alerts; resumes with persisted `lastEventId` |
| **WebSocket** | Live driver map (`drivers.locations`) + driver chat (`driver.messages` / `driver.message.send`) |

### Why these packages

- **flutter_bloc** — required ViewModels
- **go_router** — permission-aware routes + shell + auth refresh
- **dio** — bearer interceptors, unified REST/GraphQL errors
- **package:web EventSource** — browsers cannot set SSE headers; `?token=` + native retry + Last-Event-ID resume
- **web_socket_channel** — map + chat with backoff reconnect
- **flutter_map** — OSM tiles, no API key
- **fl_chart** — trips-over-time series
- **shared_preferences** — session + locale/theme + SSE last event id
- **connectivity_plus** — offline banner (B4)
- **flutter_localizations** — English / Arabic + RTL (B5)

## Must-haves

1. **Auth** — server errors shown; session survives refresh; sign-out revokes; any 401 closes realtime and returns to sign-in without looping; 403 refreshes `/api/me` (role change / ban)
2. **Role-aware shell** — nav, routes and actions from permissions only; forbidden URLs → “No access”; shows user, role, city
3. **Dashboard** — GraphQL `kpis` + SSE `kpi`; multi-currency revenue; Last 24h / 7 days chart
4. **Trips** — cursor pagination; status + **date range** + search; SSE create/update highlights; detail with assign / cancel / refund; clear 409 messaging
5. **Live map** — WS locations, status colours, driver panel, reconnect banner
6. **Alerts** — SSE feed, acknowledge when permitted, SOS banner app-wide
7. **Maintenance** — full overlay + health backoff recovery while staying signed in; light reconnect hint when only realtime drops

## Bonuses included

| # | Item |
|---|------|
| B1 | Driver chat (WS send + channel, REST history) from the map panel |
| B2 | User admin for `user:list` / create / re-role / ban / unban |
| B3 | Drivers & riders create/edit for ops roles |
| B4 | SSE `Last-Event-ID` / `lastEventId` resume + offline banner |
| B5 | English ↔ Arabic with correct RTL |
| B6 | Tablet bottom nav (&lt;900px) + dark / light / system theme |
| B7 | Generated OpenAPI models + typed GraphQL ops in `lib/generated/` (`openapi.json` checked in) |
| B8 | Extra role permission tests + live API smoke test |

## Tests

```bash
flutter test
```

- Unit: permission → destinations / actions
- Widget: viewer hides trip actions; dispatcher shows assign
- Role matrix: support / viewer / dispatcher / super_admin
- Integration: optional live sign-in + `/api/me` (skips if sandbox down)

## Screen recording (submission)

Record 3–5 minutes:

1. Sign in as **dispatcher**, **support**, and **viewer** — show nav/actions differ
2. Assign a waiting trip; show the live list update
3. (Optional) Toggle Arabic/RTL, dark mode, open driver chat, maintenance if available

## Trade-offs / more time

- GraphQL codegen via `graphql_codegen`/`ferry` not wired into a build_runner pipeline; typed documents are checked in under `lib/generated/graphql_operations.dart`
- OpenAPI models are hand-aligned to `openapi.json` rather than a full generator CLI
- Trip SSE stubs refetch detail when payload is incomplete

## API feedback

- WS subscribe: `{ "type":"subscribe", "id":"…", "payload":{ "channel":"drivers.locations" } }`
- SSE events: `ready`, `kpi`, `trip.created`, `trip.updated`, `alert.created`, `alert.acknowledged`, `ping`
- GraphQL `SeriesPoint` uses `bucket` / `total` / `completed` / `cancelled`
- Shared sandbox: demo account roles/cities may be mutated by others — always trust `/api/me`
- Never ban/edit the shared demo accounts unless they are users you created (super_admin rule)

## Project layout (high level)

```
lib/
  core/           config, errors, network, permissions, theme, l10n
  generated/      OpenAPI models + GraphQL documents
  features/       auth, dashboard, trips, map, alerts, users, drivers,
                  riders, chat, connectivity, settings, shell, realtime
  di/             composition root
openapi.json      sandbox contract snapshot
```
