/// Snapshot of route/visit performance for a given period.
class ClientVisitStatsModel {
  final int totalAssignedClients;
  final int visitedClients; // any status other than pending
  final int completedOrSoldClients; // counts as a "finished" visit
  final int noOrderClients;
  final int notReachedClients;

  const ClientVisitStatsModel({
    required this.totalAssignedClients,
    required this.visitedClients,
    required this.completedOrSoldClients,
    required this.noOrderClients,
    required this.notReachedClients,
  });

  int get remainingClients => totalAssignedClients - visitedClients;

  double get completionRate => totalAssignedClients == 0
      ? 0
      : completedOrSoldClients / totalAssignedClients;

  static const empty = ClientVisitStatsModel(
    totalAssignedClients: 0,
    visitedClients: 0,
    completedOrSoldClients: 0,
    noOrderClients: 0,
    notReachedClients: 0,
  );
}
