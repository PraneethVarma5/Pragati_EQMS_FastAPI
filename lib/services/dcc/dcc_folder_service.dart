import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/dcc/dcc_folder.dart';
import 'dcc_session.dart';

class DccFolderService {
  static const String tableName = 'dcc_folders';

  static SupabaseClient get _client => Supabase.instance.client;

  static bool get _isDcc =>
      DccSession.currentUser?.role.trim().toUpperCase() == 'DCC';

  static Future<List<DccFolder>> getFolders() async {
    final response = await _client
        .from(tableName)
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((row) => DccFolder.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<DccFolder> createFolder(String name) async {
    if (!_isDcc) {
      throw Exception('Only DCC users can create folders.');
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Folder name is required.');
    }

    final user = DccSession.currentUser;
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    final response = await _client
        .from(tableName)
        .insert({
          'id': id,
          'name': trimmed,
          'created_by_name': user?.name ?? '',
          'created_by_email': user?.email ?? '',
        })
        .select()
        .single();

    return DccFolder.fromMap(Map<String, dynamic>.from(response));
  }
  static Future<void> deleteFolder(String folderId) async {
    if (!_isDcc) {
      throw Exception('Only DCC users can delete folders.');
    }

    final id = folderId.trim();
    if (id.isEmpty) {
      throw Exception('Folder id is required.');
    }

    await _client
        .from(tableName)
        .delete()
        .eq('id', id);
  }

}
