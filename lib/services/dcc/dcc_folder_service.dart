import '../../models/dcc/dcc_folder.dart';
import 'dcc_api_client.dart';
import 'dcc_session.dart';
class DccFolderService {
 static const String tableName='dcc_folders';
 static bool get _isDcc => DccSession.currentUser?.role.trim().toUpperCase()=='DCC' || DccSession.currentUser?.role.trim().toUpperCase()=='ADMIN';
 static Future<List<DccFolder>> getFolders() async {
  final rows = await DccApiClient.get(
   '/folders',
   authenticated: false,
  ) as List;

  return rows
      .map(
       (r) => DccFolder.fromMap(
    Map<String, dynamic>.from(r as Map),
   ),
  )
      .toList();
 }
 static Future<DccFolder> createFolder(String name) async { if(!_isDcc) throw Exception('Only DCC users can create folders.'); final n=name.trim(); if(n.isEmpty) throw Exception('Folder name is required.'); final u=DccSession.currentUser; final result=await DccApiClient.post('/folders',body:{'data':{'id':DateTime.now().microsecondsSinceEpoch.toString(),'name':n,'created_by_name':u?.name??'','created_by_email':u?.email??''}}); if(result is Map && result['data'] is Map) return DccFolder.fromMap(Map<String,dynamic>.from(result['data'])); return DccFolder(id:DateTime.now().microsecondsSinceEpoch.toString(),name:n,createdByName:u?.name??'',createdByEmail:u?.email??''); }
 static Future<void> deleteFolder(String folderId) async { if(!_isDcc) throw Exception('Only DCC users can delete folders.'); await DccApiClient.delete('/folders/${Uri.encodeComponent(folderId.trim())}'); }
}
