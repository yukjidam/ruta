# RUTA — Ride Logbook

A keepsake app for motorcycle touring — solo or with a crew. Track a ride
live on the road with your group, then seal it into a personal logbook
with a photo, a route, and the riders who were there.

Built with Flutter, targeting Android first.

> **Status:** UI/UX complete and clickable end-to-end on dummy data,
> including a persistent app shell, settings, and app branding.
> No backend yet — see [Roadmap](#roadmap) below for what's next.
> Contributor setup instructions live in
> [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

---

## What it does

**Ride together, tracked live.**
Add a friend, then invite them into a ride. Whoever sets the destination
becomes ride leader — they control pause/resume/end while everyone in the
group sees the same live map, turn-by-turn directions, and each other's
position in real time.

**Every ride becomes a keepsake.**
Ending a ride requires a photo before it can be saved. That photo, the
route, the distance, the duration, and who rode it get bundled into a
summary card and filed automatically into your logbook feed.

**A garage, not just a profile.**
Every motorcycle you own gets registered — make, year, running odometer —
so your ride history always knows what you were riding.

**A small social layer.**
Search for other riders, view their profile and logbook, heart and
comment on their rides. Simple, chronological, no algorithm.

**A home that doesn't flash.**
Logbook, Garage, Crew, and Notifications live inside one persistent app
shell (`HomeShell`) — the bottom nav and its four tabs are kept alive
together, so switching tabs never re-triggers a full screen transition.

---

## Tech stack

Chosen to stay genuinely free at this stage — no credit card required
anywhere in the stack below.

| Layer | Choice | Why |
|---|---|---|
| App framework | **Flutter** (Dart) | Cross-platform, Android-first for this project |
| Auth, database | **Supabase** (Postgres) | Free tier: unlimited-ish auth, 500MB DB, no card needed |
| Live ride tracking | **Supabase Realtime** | Free channel broadcasting for rider positions during a ride |
| Photo storage | **Cloudflare R2** | 10GB free storage, and — the important part — free egress forever, so a growing photo feed doesn't rack up bandwidth costs |
| Maps | **flutter_map** + OpenStreetMap tiles | Free, no API key, no quota |
| Device GPS | **geolocator** (Flutter package) | Native device location, not an API call — free regardless of usage |
| Routing / turn-by-turn | **OpenRouteService** (fallback: self-hosted OSRM) | Free tier for directions and route calculation |
| Push notifications | **Firebase Cloud Messaging** | Still free and unlimited; used only for messaging, not storage |

Firebase Storage was deliberately ruled out — as of Feb 2026 it requires a
linked billing account (Blaze plan) even to stay within the free quota.
Cloudflare R2 covers the same need without that requirement.

---

## APIs & services

| Service | Used for | Docs |
|---|---|---|
| Supabase | Auth, Postgres database, Realtime channels | https://supabase.com/docs |
| Cloudflare R2 | Ride photo storage | https://developers.cloudflare.com/r2/ |
| OpenStreetMap | Map tiles | https://wiki.openstreetmap.org/wiki/Tile_servers |
| OpenRouteService | Routing / turn-by-turn directions | https://openrouteservice.org/dev/#/api-docs |
| Firebase Cloud Messaging | Push notifications (ride invites, comments) | https://firebase.google.com/docs/cloud-messaging |

Environment variable placeholders for all of the above already exist in
[`.env.example`](.env.example) — see `docs/DEVELOPMENT.md` for how `.env`
is wired into the app via `flutter_dotenv`.

---

## Roadmap

### ✅ Phase 1 — UI/UX foundation
13-screen design pass: onboarding, auth, feed, garage, crew, and the full
ride cycle (plan → lobby → live → paused → capture → summary). Design
tokens (color, type, the dashed route-line motif) established.

### ✅ Phase 2 — Flutter UI build
Every screen built as real Flutter widgets, fully navigable on hardcoded
dummy data. No backend, no API keys, nothing to configure to demo it.

### ✅ Phase 3 — Dev tooling
`.env` / `.env.example`, `.gitignore`, `.gitattributes`, lint rules, a
GitHub Actions CI workflow (`flutter analyze` + `flutter test`), and
VS Code launch configs.

### ✅ Phase 4 — Social layer (UI only)
Shared Profile screen (yours or any friend's), a Search screen across all
riders, working Crew search/filter, and heart + comment interactions on
ride posts. Still local widget state only — nothing persisted yet.

### ✅ Phase 5 — App shell, settings & branding
- Fixed a full-screen "flash" on every bottom-nav tap: Feed, Garage, Crew,
  and Notifications now live inside one persistent `HomeShell`
  (`IndexedStack` + a single shared `AppBottomNav`) instead of each being
  its own route.
- New Settings screen, reachable from Profile — grouped account/
  preferences/support rows and an "About Ruta" modal (maker credit,
  live-fetched GitHub avatar, link to
  [github.com/yukjidam](https://github.com/yukjidam)).
- A real app icon: the "R" mark traced as an actual vector outline from
  the app's own Anton typeface (not a font-dependent `<text>` tag), shipped
  as `assets/icon/ruta_icon.{svg,png,ico}`. Used on the login screen, in
  the About modal, and ready to become the real Android/iOS launcher icon
  via `flutter_launcher_icons` (config already in `pubspec.yaml` — run
  `flutter pub run flutter_launcher_icons` to generate it).

### 🔜 Phase 6 — Map integration
Replace the gradient placeholders on Plan a Ride and Live Ride with a
real `flutter_map` + OpenStreetMap view. No account or backend needed for
this step, which is why it's next.

### ⏳ Phase 7 — Backend foundation
Stand up the Supabase project: real auth (Register/Login stop being
decorative), and the core schema — accounts, motorcycles, friends, rides.

### ⏳ Phase 8 — Live ride tracking
Wire `geolocator` to the Live Ride screen for real device GPS, and
Supabase Realtime channels to broadcast every rider's position to the
rest of their group during a ride.

### ⏳ Phase 9 — Photo storage
`image_picker` for the Capture screen's camera flow, uploading to
Cloudflare R2 and referencing the resulting URL from Supabase.

### ⏳ Phase 10 — Routing engine
OpenRouteService integration for real turn-by-turn directions and ETA on
the Live Ride screen, replacing the static direction card.

### ⏳ Phase 11 — Social backend
Move hearts, comments, and friend requests from local dummy data into
real Supabase tables, with Realtime subscriptions so likes/comments
update live.

### ⏳ Phase 12 — Push notifications
Firebase Cloud Messaging for ride invites, new comments, and friend
requests.

### ⏳ Phase 13 — Polish & release
Splash screen, offline handling, a proper Play Store listing, and a full
testing pass. (App icon itself is already done — see Phase 5.)

---

## Getting started

Full setup (Flutter requirements, environment variables, git, CI) lives
in [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md). The short version:

```bash
cp .env.example .env
flutter create .      # only needed once, to generate platform folders
flutter pub get
flutter pub run flutter_launcher_icons   # generates the real app icon
flutter run
```
