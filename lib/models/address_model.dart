class Address {
  final int userLocationId;
  final int? userId;

  final String? title;
  final String? address;

  final String? streetNameOrNumber;
  final String? buildingNameOrNumber;
  final String? floorNumber;
  final String? apartment;
  final String? nearestLandmark;

  final double? lat;
  final double? lng;

  // Country (⚠️ côté API = string)
  final int? countryId;           // obsolète côté API (gardé pour compat lecture)
  final String? countryName;      // ✅ à envoyer

  // Governorate (⚠️ côté API = string)
  final int? governorateId;       // obsolète côté API (compat lecture)
  final String? governorateName;  // ✅ à envoyer

  // District = city (ID)
  final int? districtId;          // ✅ à envoyer
  final String? districtName;

  final bool isHome;
  final bool isWork;
  final bool isDeleted;

  final String? createdAt;
  final String? updatedAt;

  const Address({
    required this.userLocationId,
    this.userId,
    this.title,
    this.address,
    this.streetNameOrNumber,
    this.buildingNameOrNumber,
    this.floorNumber,
    this.apartment,
    this.nearestLandmark,
    this.lat,
    this.lng,
    this.countryId,
    this.countryName,
    this.governorateId,
    this.governorateName,
    this.districtId,
    this.districtName,
    this.isHome = false,
    this.isWork = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  /* ---------------- helpers parse ---------------- */
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = ('$v').replaceAll(',', '.');
    return double.tryParse(s);
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = '$v'.toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  factory Address.fromJson(Map<String, dynamic> j) {
    return Address(
      userLocationId: _toInt(j['userLocationId'] ?? j['UserLocationID']) ?? 0,
      userId: _toInt(j['userId'] ?? j['UserID']),
      title: j['title'] ?? j['LabelName'],
      address: j['address'] ?? j['Address'],
      streetNameOrNumber: j['streetNameOrNumber'] ?? j['StreetNameOrNumber'],
      buildingNameOrNumber: j['buildingNameOrNumber'] ?? j['BuildingNameOrNumber'],
      floorNumber: j['floorNumber'] ?? j['FloorNumber'],
      apartment: j['apartment'] ?? j['Apartment'],
      nearestLandmark: j['nearestLandmark'] ?? j['NearestLandmark'],
      lat: _toDouble(j['lat'] ?? j['Latitude']),
      lng: _toDouble(j['lng'] ?? j['Longitude']),

      // lecture compatible avec anciens champs
      countryId: _toInt(j['countryId'] ?? j['CountryID']),
      countryName: j['countryName'] ?? j['CountryName'],
      governorateId: _toInt(j['governorateId'] ?? j['GovernorateID']),
      governorateName: j['governorateName'] ?? j['GovernorateName'],
      districtId: _toInt(j['districtId'] ?? j['DistrictID']),
      districtName: j['districtName'] ?? j['DistrictName'],

      isHome: _toBool(j['isHome'] ?? j['IsHome']),
      isWork: _toBool(j['isWork'] ?? j['IsWork']),
      isDeleted: _toBool(j['isDeleted'] ?? j['IsDeleted']),
      createdAt: j['createdAt'] ?? j['CreationDate']?.toString(),
      updatedAt: j['updatedAt'] ?? j['LastDateModified']?.toString(),
    );
  }

  // util: enlève les nulls dans un body JSON
  static Map<String, dynamic> _clean(Map<String, dynamic> m) {
    final r = <String, dynamic>{};
    m.forEach((k, v) {
      if (v != null) r[k] = v;
    });
    return r;
  }

  /// Body pour POST /orders/addresses (CreateAddressDto) — ✅ strings côté API
    /// Body pour POST /orders/addresses (CreateAddressDto)
  /// -> on N'ENVOIE PAS lat/lng.
  Map<String, dynamic> toCreateJson() {
    final m = <String, dynamic>{
      'title': title,
      'address': address,
      'streetNameOrNumber': streetNameOrNumber,
      'buildingNameOrNumber': buildingNameOrNumber,
      'floorNumber': floorNumber,
      'apartment': apartment,
      'nearestLandmark': nearestLandmark,

      // ✅ nouveau contrat back : strings
      'countryName': countryName,
      'governorateName': governorateName,
      'districtId': districtId,

      'isHome': isHome,
      'isWork': isWork,
    };

    // (Optionnel) si tu veux NE les envoyer QUE s'ils sont *tous les deux* présents :
    // if (lat != null && lng != null) {
    //   m['lat'] = lat;
    //   m['lng'] = lng;
    // }

    return _clean(m);
  }

  /// Body pour PUT /orders/addresses/:id (UpdateAddressDto)
  /// -> idem, pas de lat/lng par défaut.
  Map<String, dynamic> toUpdateJson() {
    final m = <String, dynamic>{
      'title': title,
      'address': address,
      'streetNameOrNumber': streetNameOrNumber,
      'buildingNameOrNumber': buildingNameOrNumber,
      'floorNumber': floorNumber,
      'apartment': apartment,
      'nearestLandmark': nearestLandmark,

      'countryName': countryName,
      'governorateName': governorateName,
      'districtId': districtId,

      'isHome': isHome,
      'isWork': isWork,
    };

    // (Optionnel) n’envoie lat/lng que si les deux existent :
    // if (lat != null && lng != null) {
    //   m['lat'] = lat;
    //   m['lng'] = lng;
    // }

    return _clean(m);
  }

  /// Body pour PUT /orders/addresses/:id (UpdateAddressDto)
  

  Address copyWith({
    int? userLocationId,
    int? userId,
    String? title,
    String? address,
    String? streetNameOrNumber,
    String? buildingNameOrNumber,
    String? floorNumber,
    String? apartment,
    String? nearestLandmark,
    double? lat,
    double? lng,
    int? countryId,
    String? countryName,
    int? governorateId,
    String? governorateName,
    int? districtId,
    String? districtName,
    bool? isHome,
    bool? isWork,
    bool? isDeleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return Address(
      userLocationId: userLocationId ?? this.userLocationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      address: address ?? this.address,
      streetNameOrNumber: streetNameOrNumber ?? this.streetNameOrNumber,
      buildingNameOrNumber: buildingNameOrNumber ?? this.buildingNameOrNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      apartment: apartment ?? this.apartment,
      nearestLandmark: nearestLandmark ?? this.nearestLandmark,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      countryId: countryId ?? this.countryId,
      countryName: countryName ?? this.countryName,
      governorateId: governorateId ?? this.governorateId,
      governorateName: governorateName ?? this.governorateName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      isHome: isHome ?? this.isHome,
      isWork: isWork ?? this.isWork,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Address(id=$userLocationId, title=$title, address=$address, '
      'lat=$lat, lng=$lng, countryName=$countryName, governorateName=$governorateName, '
      'districtId=$districtId, home=$isHome, work=$isWork)';
}
