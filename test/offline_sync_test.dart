// End-to-end check of offline reads, queued writes and sync, against a real
// (local) Edstream API. Skipped unless run with, e.g.:
//   flutter test test/offline_sync_test.dart \
//     --dart-define=API_URL=http://localhost:3031/api/v1/ \
//     --dart-define=QA_EMAIL=... --dart-define=QA_PASSWORD=...
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edstream_mobile/core/network/api_client.dart';
import 'package:edstream_mobile/core/network/connectivity_controller.dart';
import 'package:edstream_mobile/core/network/offline_mutation_queue.dart';
import 'package:edstream_mobile/core/network/offline_sync_service.dart';
import 'package:edstream_mobile/core/storage/local_cache_store.dart';

const _email = String.fromEnvironment('QA_EMAIL');
const _password = String.fromEnvironment('QA_PASSWORD');

void main() {
  test('reads come from cache offline and queued writes sync on reconnect', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalCacheStore.instance.init();
    await OfflineMutationQueue.instance.init();
    await OfflineMutationQueue.instance.clear();
    final api = ApiClient.instance;

    // Online: sign in and load classes (cached on the way).
    final login = await api.post('staff/login', body: {'email': _email, 'password': _password});
    api.setAuthToken(login['token'] as String);
    final online = await api.get('class', queryParams: {'limit': 200});
    expect(ApiClient.isOffline(online), isFalse);
    expect(ConnectivityController.instance.isOnline, isTrue);

    // Server unreachable: the same read is answered from the cache.
    ApiClient.baseUrlOverride = 'http://127.0.0.1:9/api/v1/';
    final offline = await api.get('class', queryParams: {'limit': 200});
    expect(ApiClient.isOffline(offline), isTrue);
    expect(offline['data'], equals(online['data']));
    expect(ConnectivityController.instance.isOffline, isTrue);

    // A write while offline is queued, not lost.
    final title = 'QA mobile offline ${DateTime.now().millisecondsSinceEpoch}';
    final queued = await api.send('POST', 'calendar',
        body: {'title': title, 'category': 'event', 'startDate': '2026-12-01'}, feature: 'calendar', label: title);
    expect(ApiClient.isQueued(queued), isTrue);
    expect(OfflineMutationQueue.instance.count(), 1);

    // A change the server will reject is parked as failed, not blocking others.
    await api.send('POST', 'calendar', body: {'category': 'event'}, feature: 'calendar', label: 'invalid');
    expect(OfflineMutationQueue.instance.count(), 2);

    // Back online: the queue is sent; the good change lands, the bad one is marked failed.
    ApiClient.baseUrlOverride = null;
    await OfflineSyncService.instance.flushPendingMutations();
    expect(OfflineMutationQueue.instance.count(), 0);
    expect(OfflineMutationQueue.instance.failedCount(), 1);

    final events = await api.get('calendar', cacheLocally: false);
    final list = (events is Map ? (events['data'] ?? []) : events) as List;
    expect(list.any((e) => e['title'] == title), isTrue);
  }, skip: _email.isEmpty ? 'needs QA_EMAIL/QA_PASSWORD and a local API' : false);
}
