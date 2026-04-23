class VehicleWithOwnerResponse {
  final VehicleResponse vehicle;
  final OwnerInfoResponse owner;

  VehicleWithOwnerResponse({required this.vehicle, required this.owner});

  factory VehicleWithOwnerResponse.fromJson(Map<String, dynamic> json) =>
      VehicleWithOwnerResponse(
        vehicle: VehicleResponse.fromJson(json['vehicle']),
        owner: OwnerInfoResponse.fromJson(json['owner']),
      );
}

class VehicleResponse {
  final String id;
  final String licensePlate;
  final String brand;
  final String model;

  VehicleResponse({required this.id, required this.licensePlate, required this.brand, required this.model});

  factory VehicleResponse.fromJson(Map<String, dynamic> json) => VehicleResponse(
    id: json['id'],
    licensePlate: json['licensePlate'],
    brand: json['brand'],
    model: json['model'],
  );
}

class OwnerInfoResponse {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;

  OwnerInfoResponse({required this.id, required this.firstName, required this.lastName, required this.email, this.phoneNumber});

  factory OwnerInfoResponse.fromJson(Map<String, dynamic> json) => OwnerInfoResponse(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
  );
}