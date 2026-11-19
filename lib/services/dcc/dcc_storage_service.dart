import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'dcc_api_client.dart';
class DccStorageService {
 static const String bucketName='dcc-documents';
 static Future<String> _upload(Uint8List bytes,String path,String filename) async {if(bytes.isEmpty)throw Exception('Selected file is empty.');final result=await DccApiClient.upload('/files/upload?path=${Uri.encodeQueryComponent(path)}',bytes,filename,contentType:lookupMimeType(filename)??'application/octet-stream');return result['path']?.toString()??path;}
 static Future<String> uploadSourceDocument({required Uint8List fileBytes,required String documentId,required String originalFileName})=>_upload(fileBytes,'source/$documentId/${_safeName(originalFileName)}',originalFileName);
 static Future<String> uploadConvertedPdf({required Uint8List fileBytes,required String documentId,required int revision,required String originalFileName})=>_upload(fileBytes,'released/$documentId/rev_$revision/${_safeName(originalFileName)}',originalFileName);
 static Future<String> uploadRevisedDocument({required Uint8List fileBytes,required String requestId,required String originalFileName})=>_upload(fileBytes,'revised/$requestId/${_safeName(originalFileName)}',originalFileName);
 static Future<String> uploadDccRevisedPdf({required Uint8List fileBytes,required String requestId,required String originalFileName}){if(!_safeName(originalFileName).toLowerCase().endsWith('.pdf'))throw Exception('Only PDF files are allowed.');return _upload(fileBytes,'revised/$requestId/${_safeName(originalFileName)}',originalFileName);}
 static Future<String> promoteRevisedToReleased({required String revisedPath,required String documentId,required int revision,required String originalFileName}) async {final bytes=await DccApiClient.downloadBytes(revisedPath);return uploadConvertedPdf(fileBytes:bytes,documentId:documentId,revision:revision,originalFileName:originalFileName);}
 static Future<void> deleteFile(String storagePath) async {if(storagePath.trim().isEmpty)return;await DccApiClient.delete('/files/file?path=${Uri.encodeQueryComponent(storagePath)}');}
 static Future<String> createSignedUrl(String storagePath,{int expiresIn=3600,String? downloadFileName}) async {final p=storagePath.trim();if(p.isEmpty)throw Exception('File storage path is empty.');if(p.startsWith('http://')||p.startsWith('https://'))return p;return DccApiClient.fileUrl(p);}
 static String _safeName(String name)=>name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'),'_').isEmpty?'document':name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'),'_');
}
