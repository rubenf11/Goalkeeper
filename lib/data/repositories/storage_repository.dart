import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

class StorageRepository {
  Future<SupabaseClient> _client() async {
    try {
      return Supabase.instance.client;
    } on AssertionError {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      return Supabase.instance.client;
    }
  }

  Future<String> uploadImage(
    File file,
    String path, {
    String bucket = 'moments',
  }) async {
    try {
      final SupabaseClient supabase = await _client();

      await supabase.storage.from(bucket).upload(path, file);

      final String publicUrl = supabase.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload to Supabase: $e');
    }
  }

  Future<String> uploadProfileImage(File file, String userId) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String path = 'profiles/$userId/$fileName';
    return uploadImage(file, path);
  }
}
