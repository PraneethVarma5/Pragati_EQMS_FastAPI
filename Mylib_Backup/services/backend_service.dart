import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central backend access point for Digital ARR / eQMS.
///
/// Demo:
///   Supabase is used as the shared backend.
///
/// Production:
///   This layer can be changed to communicate with the
///   company's backend API without changing the UI layer.
class BackendService {
  static SupabaseClient get supabase {
    return Supabase.instance.client;
  }

  static bool get isWeb => kIsWeb;
}