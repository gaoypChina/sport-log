import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:hive/hive.dart';
import 'package:sport_log/api/api.dart';
import 'package:sport_log/config.dart';
import 'package:sport_log/data_provider/data_provider.dart';
import 'package:sport_log/database/database.dart';
import 'package:sport_log/database/keys.dart';
import 'package:sport_log/helpers/logger.dart';
import 'package:sport_log/helpers/typedefs.dart';
import 'package:sport_log/settings.dart';

import 'data_providers/all.dart';

class Sync extends ChangeNotifier {
  final _logger = Logger('Sync');

  Timer? _syncTimer;

  bool _isSyncing;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _box.get(Keys.lastSync);

  late final Box<DateTime> _box;

  static final Sync instance = Sync._();
  Sync._() : _isSyncing = false;

  Future<void> init() async {
    _box = await Hive.openBox<DateTime>(Keys.lastSync);
    if (Config.deleteDatabase) {
      _removeLastSync();
    }
    if (Settings.instance.userExists()) {
      Future(() => sync());
      startSync();
    }
  }

  Future<void> sync({VoidCallback? onNoInternet}) async {
    if (_isSyncing == true) {
      _logger.d('Sync is alread running.');
      return;
    }
    if (!Settings.instance.userExists()) {
      _logger.d('Sync cannot be run: no user.');
      return;
    }
    _isSyncing = true;
    notifyListeners();
    final syncStart = DateTime.now();
    if (await _downSync(onNoInternet: onNoInternet)) {
      await _upSync();
      _setLastSync(syncStart);
    }
    _isSyncing = false;
    notifyListeners();
  }

  void startSync() {
    assert(Settings.instance.userExists());
    if (_syncTimer != null && _syncTimer!.isActive) {
      _logger.d('Login, but timer is active.');
      return;
    }
    _logger.d('First sync');
    Future(() => sync());
    _logger.d('Starting sync timer...');
    _syncTimer = Timer.periodic(Settings.instance.syncInterval, (_) => sync());
  }

  void stopSync() {
    if (_syncTimer != null) {
      // TODO: what if sync is running and database will be deleted?
      _logger.d('Stopping sync timer...');
      _syncTimer?.cancel();
      _syncTimer = null;
    }
  }

  void _setLastSync(DateTime dateTime) {
    _logger.i('Setting last sync to $dateTime...');
    _box.put(Keys.lastSync, dateTime);
  }

  void _removeLastSync() {
    _logger.i('Removing last sync...');
    _box.delete(Keys.lastSync);
  }

  List<DataProvider> get allDataProviders => [
        MovementDataProvider.instance,
        StrengthDataProvider.instance,
        MetconDataProvider.instance,
        DiaryDataProvider.instance,
        WodDataProvider.instance,
        ActionEventDataProvider.instance,
        ActionRuleDataProvider.instance,
        PlatformCredentialDataProvider.instance,
      ];

  Future<void> _upSync() async {
    for (final dp in allDataProviders) {
      // TODO: this can be sped up
      await dp.pushToServer();
    }
    // TODO: upsync routes, cardio sessions, metcon sessions, movement muscle, training plan, metcon item, strength blueprint, cardio blueprint
    // TODO: deal with user updates
  }

  Future<bool> _downSync({VoidCallback? onNoInternet}) async {
    final accountDataResult = await Api.instance.accountData.get(lastSync);
    if (accountDataResult.isFailure) {
      if (accountDataResult.failure == ApiError.noInternetConnection) {
        _logger.d('Tried sync but got no Internet connection.',
            accountDataResult.failure);
        if (onNoInternet != null) {
          onNoInternet();
        }
      } else {
        _logger.e('Tried down sync, but got error.', accountDataResult.failure);
      }
      return false;
    } else {
      final accountData = accountDataResult.success;
      AppDatabase.instance!.upsertAccountData(accountData, synchronized: true);

      // TODO: deal with user updates
      return true;
    }
  }
}
