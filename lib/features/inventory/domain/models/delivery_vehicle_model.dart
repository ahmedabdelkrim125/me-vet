class DeliveryVehicleModel {
  final String id;
  final String plateNumber;
  final String driverName;
  final String? repId;

  const DeliveryVehicleModel({
    required this.id,
    required this.plateNumber,
    required this.driverName,
    this.repId,
  });

  factory DeliveryVehicleModel.fromMap(Map<String, dynamic> map) {
    return DeliveryVehicleModel(
      id: map['id'] as String,
      plateNumber: map['plate_number'] as String,
      driverName: map['driver_name'] as String,
      repId: map['rep_id'] as String?,
    );
  }
}
