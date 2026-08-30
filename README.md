# RUTA — Flutter UI/UX Starter

A keepsake ride-logbook app for motorcycle touring, solo or with a crew.
This build is **UI only** — every screen renders with hardcoded dummy data,
no backend, no API keys, no network calls. It's meant to be clickable and
demoable on its own before we wire up Supabase, storage, maps, and GPS.

---

## 1. Requirements

- Flutter SDK 3.19+ (Dart 3.3+)
- Android Studio or VS Code with the Flutter extension
- An Android emulator or physical device (this was designed mobile-first for Android)

Check your setup with:

```bash
flutter doctor
```

## 2. Getting it running

```bash
# from inside the project folder
cp .env.example .env      # create your local env file (already gitignored)
flutter pub get
flutter run
```

That's it — no real API keys needed yet. `.env` is loaded at startup by
`flutter_dotenv`, but nothing in this UI-only build actually reads a value
out of it — it's wired up so the backend pass is a drop-in later instead
of a re-architecture. The app opens on the Onboarding screen and every
button navigates somewhere real.

## 2.1 Environment variables

- **`.env.example`** — tracked in git. The reference template with every
  key the app will eventually need (Supabase, Cloudflare R2, OpenRouteService).
- **`.env`** — your local copy, gitignored, never committed. Already created
  for you in this zip with the same placeholder values — replace them with
  real ones when you start the backend pass.
- **`lib/config/env_config.dart`** — typed getters (`EnvConfig.supabaseUrl`,
  etc.) instead of scattering `dotenv.env['SOME_STRING']` across the app.
  Each getter throws a clear error if the value is still a placeholder,
  so a missing key fails loudly at the call site instead of silently
  returning null deep in a widget.
- Firebase Cloud Messaging is the one exception — it's configured via
  `google-services.json` / `GoogleService-Info.plist` files (downloaded
  from the Firebase console), not `.env`. Both filenames are already
  gitignored.

## 3. Git setup

This project isn't a git repo yet — the zip doesn't include a `.git`
folder. To start one:

```bash
git init
git add .
git commit -m "Initial UI-only build"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

`.gitignore` already excludes `.env`, build output, IDE folders, and
platform-specific secrets (`google-services.json`, keystores, etc.) so
none of that risks landing in a public repo by accident.
`.gitattributes` normalizes line endings across Windows/Mac/Linux
contributors.

## 4. CI

`.github/workflows/flutter_ci.yml` runs `flutter analyze` and
`flutter test` on every push/PR to `main`, using `.env.example` as a
placeholder `.env` so the build doesn't fail on a missing file. A
minimal smoke test lives in `test/widget_test.dart`. Once real secrets
exist, add them as repo secrets in GitHub and generate `.env` from
them in the workflow instead of copying the example.

## 5. Editor setup

`.vscode/` includes launch configs for debug/profile/release, a
`settings.json` with format-on-save and a 100-char ruler, and a
recommended-extensions list (Dart + Flutter). Delete the folder if you
prefer Android Studio defaults — nothing else in the project depends
on it.

## 6. What's actually wired up

Every screen is reachable and the primary buttons navigate to the next
logical screen in the ride flow, so you can click through the whole app:

```
Onboarding → Register/Login → Feed (home)
Feed → Garage / Crew (bottom nav)
Feed (+) → Plan a Ride → Lobby → Live Ride → Paused → Capture → Summary → back to Feed
```

Text fields, toggles, and lists are **not functional** — they're static
placeholders showing what the finished UI looks like. No data is saved,
no auth actually happens, no photo is actually taken.

## 7. Project structure

```
.env.example                 # Tracked template for environment variables
.env                          # Your local copy (gitignored)
.gitignore
.gitattributes
analysis_options.yaml         # Lint rules
.github/workflows/flutter_ci.yml  # Analyze + test on push/PR
.vscode/                      # Launch configs, editor settings, extensions
test/
  widget_test.dart            # Minimal smoke test
lib/
  main.dart                  # App shell + dotenv.load() + all named routes (AppRoutes)
  config/
    env_config.dart           # Typed getters over .env (Supabase, R2, ORS keys)
  theme/
    app_colors.dart          # Color tokens (asphalt/paper/route/rust/pine palette)
    app_text.dart             # Anton / Work Sans / JetBrains Mono type system
    app_theme.dart            # ThemeData pulling the above together
  widgets/                   # Shared, reusable pieces used across screens
    app_button.dart           # Primary / outline / danger button variants
    app_avatar.dart           # Circular initials avatar (riders, crew, pins)
    app_text_field.dart       # Styled input used on the auth screens
    app_bottom_nav.dart       # Feed / Garage / Crew bottom nav
    dashed_route_line.dart    # The signature dashed "route line" motif
    stat_column.dart          # Value-over-label stat (km, duration, ETA…)
    section_eyebrow.dart      # Small mono label used above headings
  models/
    dummy_data.dart           # Hardcoded rides, bikes, and crew for the UI
  screens/
    onboarding_screen.dart
    register_screen.dart
    login_screen.dart
    forgot_password_screen.dart
    feed_screen.dart           # "Logbook" home — thread of past rides
    garage_screen.dart         # Registered motorcycles + lifetime stats
    crew_screen.dart           # Friends list / invite
    plan_ride_screen.dart      # Set destination + invite crew (become leader)
    lobby_screen.dart          # Waiting room before a ride starts
    live_ride_screen.dart      # Map, turn-by-turn, leader controls
    paused_ride_screen.dart    # Rest-stop overlay state
    capture_memory_screen.dart # Forced photo capture at ride-end
    ride_summary_screen.dart   # Final keepsake card, saved to the feed
```

## 8. Design tokens, if you touch styling

Everything pulls from `lib/theme/`, so a palette or type change happens in
one place instead of forty:

- **Dark "asphalt" screens** (auth, live ride, paused) use `AppColors.asphalt`
  as the background — anything happening *on the road*.
- **Warm "paper" screens** (feed, ride summary) use `AppColors.paper` —
  anything you're *looking back on*.
- **Anton** (`AppText.display`) for headings, **Work Sans** (`AppText.body`)
  for everything readable, **JetBrains Mono** (`AppText.mono`) for anything
  that reads like a data readout — distance, ETA, timestamps, odometer.

`google_fonts` downloads these at first run. If you need the app to work
fully offline, swap to bundled font files under `assets/fonts/` and update
`pubspec.yaml` before shipping.

## 9. What's intentionally NOT here yet

This pass leaves out everything backend-related on purpose, to keep this
step cheap and fast to review:

- No Supabase client, no auth, no database calls
- No real map (the map screens are gradient placeholders — swap in
  `flutter_map` + OpenStreetMap tiles later)
- No real GPS (`geolocator` isn't wired in yet)
- No real photo capture (`image_picker` / camera isn't wired in yet)
- No routing engine (OpenRouteService / OSRM) for actual turn-by-turn
- No persisted state between screens — navigating away and back resets
  everything to the same dummy data

## 10. Suggested next steps, in order

Env, git, and CI scaffolding are already in place — the list below is
purely feature work now.

1. **Wire real navigation state** — pass actual ride/crew objects between
   screens instead of dummy data, even before the backend exists.
2. **Supabase** — fill in `SUPABASE_URL`/`SUPABASE_ANON_KEY` in `.env`,
   add the `supabase_flutter` package, and make auth (register/login
   screens) go from decorative to real, then the accounts/friends/
   motorcycles/rides tables.
3. **flutter_map + OpenStreetMap** — replace the gradient placeholders on
   Plan a Ride and Live Ride with an actual map, using `EnvConfig.mapTileUrl`.
4. **geolocator** — real device GPS feeding into Live Ride.
5. **Supabase Realtime** — broadcast rider positions during a live ride.
6. **image_picker + Cloudflare R2** — real camera capture on the Capture
   screen, uploaded via `EnvConfig.r2*` values, referenced from Supabase.
7. **OpenRouteService / OSRM** — real turn-by-turn directions using
   `EnvConfig.orsApiKey`.

Each of these can be built and tested as its own isolated piece without
touching the screens that are already working.
