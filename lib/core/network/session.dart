import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/offline_mutation_queue.dart';
import 'package:edstream_mobile/core/network/offline_sync_service.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';

/// Signs out: sends any saved changes first (best effort), then removes the
/// token, the user's cached school data and the change queue, so the next
/// person on this phone sees nothing of theirs. App-level flags such as
/// "onboarding seen" are kept.
Future<void> signOut() async {
  await OfflineSyncService.instance.flushPendingMutations().catchError((_) {});
  ApiClient.instance.setAuthToken(null);
  await OfflineMutationQueue.instance.clear();
  await LocalCacheStore.instance.removeAllExcept((key) => key.toLowerCase().contains('onboard'));
}
