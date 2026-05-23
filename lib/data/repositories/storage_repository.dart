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

  Future<String> uploadImage(File file, String path) async {
    try {
      final SupabaseClient supabase = await _client();

      // Upload file to 'moments' bucket
      await supabase.storage.from('moments').upload(path, file);

      // Get the public URL for the uploaded file
      final String publicUrl = supabase.storage.from('moments').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload to Supabase: $e');
    }
  }
}
