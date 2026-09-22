import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  Stream<NetworkStatus> get onStatusChange {
    return _connectivity.onConnectivityChanged.map(_mapResults);
  }

  Future<NetworkStatus> currentStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }

  NetworkStatus _mapResults(List<ConnectivityResult> results) {
    final hasInterface = results.any((r) => r != ConnectivityResult.none);
    return hasInterface ? NetworkStatus.online : NetworkStatus.offline;
  }
}
