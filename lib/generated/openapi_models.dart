

class ApiMoney {
  const ApiMoney({required this.amount, required this.currency});
  final double amount;
  final String currency;
  factory ApiMoney.fromJson(Map<String, dynamic> j) => ApiMoney(
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        currency: j['currency']?.toString() ?? '',
      );
  Map<String, dynamic> toJson() => {'amount': amount, 'currency': currency};
}

class ApiVehicle {
  const ApiVehicle({
    required this.make,
    required this.model,
    required this.plate,
    required this.color,
  });
  final String make;
  final String model;
  final String plate;
  final String color;
  factory ApiVehicle.fromJson(Map<String, dynamic> j) => ApiVehicle(
        make: j['make']?.toString() ?? '',
        model: j['model']?.toString() ?? '',
        plate: j['plate']?.toString() ?? '',
        color: j['color']?.toString() ?? '',
      );
  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'plate': plate,
        'color': color,
      };
}

class ApiUser {
  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.banned,
    this.cityId,
    this.banReason,
    this.createdAt,
  });
  final String id;
  final String name;
  final String email;
  final String role;
  final String? cityId;
  final bool banned;
  final String? banReason;
  final DateTime? createdAt;
  factory ApiUser.fromJson(Map<String, dynamic> j) => ApiUser(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        role: j['role']?.toString() ?? '',
        cityId: j['cityId']?.toString(),
        banned: j['banned'] == true,
        banReason: j['banReason']?.toString(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      );
}

class ApiDriver {
  const ApiDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.cityId,
    this.cityName,
    this.vehicle,
    this.rating,
  });
  final String id;
  final String name;
  final String phone;
  final String status;
  final String cityId;
  final String? cityName;
  final ApiVehicle? vehicle;
  final double? rating;
  factory ApiDriver.fromJson(Map<String, dynamic> j) {
    final city = j['city'];
    return ApiDriver(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      cityId: j['cityId']?.toString() ??
          (city is Map ? city['id']?.toString() ?? '' : ''),
      cityName: city is Map ? city['name']?.toString() : null,
      rating: (j['rating'] as num?)?.toDouble(),
      vehicle: j['vehicle'] is Map<String, dynamic>
          ? ApiVehicle.fromJson(j['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiRider {
  const ApiRider({
    required this.id,
    required this.name,
    required this.phone,
    required this.cityId,
    this.cityName,
    this.email,
    this.rating,
    this.tripCount,
  });
  final String id;
  final String name;
  final String phone;
  final String cityId;
  final String? cityName;
  final String? email;
  final double? rating;
  final int? tripCount;
  factory ApiRider.fromJson(Map<String, dynamic> j) {
    final city = j['city'];
    return ApiRider(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      cityId: j['cityId']?.toString() ??
          (city is Map ? city['id']?.toString() ?? '' : ''),
      cityName: city is Map ? city['name']?.toString() : null,
      email: j['email']?.toString(),
      rating: (j['rating'] as num?)?.toDouble(),
      tripCount: (j['tripCount'] as num?)?.toInt(),
    );
  }
}

class ApiDriverMessage {
  const ApiDriverMessage({
    required this.id,
    required this.driverId,
    required this.direction,
    required this.body,
    required this.createdAt,
    this.sentBy,
  });
  final String id;
  final String driverId;
  final String direction;
  final String body;
  final String? sentBy;
  final DateTime createdAt;
  factory ApiDriverMessage.fromJson(Map<String, dynamic> j) =>
      ApiDriverMessage(
        id: j['id']?.toString() ?? '',
        driverId: j['driverId']?.toString() ?? '',
        direction: j['direction']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        sentBy: j['sentBy']?.toString(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
            DateTime.now().toUtc(),
      );
}

class ApiPage<T> {
  const ApiPage({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });
  final List<T> data;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
}

class CreateUserInput {
  const CreateUserInput({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.cityId,
  });
  final String name;
  final String email;
  final String password;
  final String role;
  final String? cityId;
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (cityId != null) 'cityId': cityId,
      };
}

class UpdateUserInput {
  const UpdateUserInput({this.name, this.role, this.cityId});
  final String? name;
  final String? role;
  final String? cityId;
  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (role != null) 'role': role,
        if (cityId != null) 'cityId': cityId,
      };
}

class CreateDriverInput {
  const CreateDriverInput({
    required this.cityId,
    required this.name,
    required this.phone,
    required this.vehicle,
  });
  final String cityId;
  final String name;
  final String phone;
  final ApiVehicle vehicle;
  Map<String, dynamic> toJson() => {
        'cityId': cityId,
        'name': name,
        'phone': phone,
        'vehicle': vehicle.toJson(),
      };
}

class UpdateDriverInput {
  const UpdateDriverInput({this.name, this.phone, this.status, this.vehicle});
  final String? name;
  final String? phone;
  final String? status;
  final ApiVehicle? vehicle;
  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (status != null) 'status': status,
        if (vehicle != null) 'vehicle': vehicle!.toJson(),
      };
}

class CreateRiderInput {
  const CreateRiderInput({
    required this.cityId,
    required this.name,
    required this.phone,
    this.email,
  });
  final String cityId;
  final String name;
  final String phone;
  final String? email;
  Map<String, dynamic> toJson() => {
        'cityId': cityId,
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
      };
}

class UpdateRiderInput {
  const UpdateRiderInput({this.name, this.phone, this.email});
  final String? name;
  final String? phone;
  final String? email;
  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      };
}
