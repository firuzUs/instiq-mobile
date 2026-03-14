import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase URL и Anon Key из FLUTTER_DEV_BRIEF.
const String supabaseUrl = 'https://xbkhqyzbmshzlxvbfpcr.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhia2hxeXpibXNoemx4dmJmcGNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkyNzI5NTUsImV4cCI6MjA4NDg0ODk1NX0.y8REnc5kPTvMGJY2bfso7HNaSFcLnjhtrJyCFnzuZ84';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
