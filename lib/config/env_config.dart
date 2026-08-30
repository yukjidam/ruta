import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to the values in `.env`, so the rest of the app never
/// touches `dotenv.env['SOME_STRING']` directly and a missing key fails
/// loudly instead of silently returning null somewhere deep in a widget.
///
/// Nothing in this UI-only build reads from here yet — this exists so
/// the backend pass (Supabase, R2, routing) is a drop-in later rather
/// than a re-architecture.
class EnvConfig {
  EnvConfig._();

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty || value.startsWith('your-')) {
      throw StateError(
        'Missing or placeholder value for "$key" in .env. '
        'Copy .env.example to .env and fill in real values.',
      );
    }
    return value;
  }

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String get r2AccountId => _require('R2_ACCOUNT_ID');
  static String get r2AccessKeyId => _require('R2_ACCESS_KEY_ID');
  static String get r2SecretAccessKey => _require('R2_SECRET_ACCESS_KEY');
  static String get r2BucketName => _require('R2_BUCKET_NAME');
  static String get r2PublicUrl => _require('R2_PUBLIC_URL');

  static String get orsApiKey => _require('ORS_API_KEY');

  /// Map tiles default to public OpenStreetMap tiles if unset, since
  /// that endpoint doesn't require a key.
  static String get mapTileUrl =>
      dotenv.env['MAP_TILE_URL'] ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
