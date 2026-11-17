import '../models/batch.dart';
import 'supabase_service.dart';

class BatchService {
  BatchService._();

  static Future<List<Batch>> loadBatches() async {
    final response =
    await SupabaseService.getAllBatches();

    return response.map((data) {
      return Batch(
        id: data['batch_id']?.toString() ?? '',
        name: data['batch_name']?.toString() ?? '',
        description:
        data['description']?.toString() ?? '',
        createdOn:
        data['created_at'] != null
            ? DateTime.parse(
          data['created_at'].toString(),
        )
            : DateTime.now(),
        active:
        data['is_active'] == true,
      );
    }).toList();
  }

  static Future<void> addBatch(
      Batch batch,
      ) async {
    await SupabaseService.createBatch(
      batchId: batch.id,
      batchName: batch.name,
      description: batch.description,
    );
  }

  static Future<void> updateBatch(
      Batch batch, {
        String? oldId,
      }) async {
    await SupabaseService.updateBatch(
      oldBatchId: oldId ?? batch.id,
      batchId: batch.id,
      batchName: batch.name,
      description: batch.description,
      isActive: batch.active,
    );
  }

  static Future<void> deleteBatch(
      String id,
      ) async {
    await SupabaseService.deleteBatch(id);
  }
}