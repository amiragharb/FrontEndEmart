class UserLocation {
  final int userLocationID;
  final String address;
  final String? streetNameOrNumber;
  final String? buildingNameOrNumber;
  final String? floorNumber;
  final String? apartment;
  final String? nearestLandmark;
  final bool isHome;
  final bool isWork;
  final int userID;
  final int? districtID;
  final String? labelName;
  final double? latitude;
  final double? longitude;

  UserLocation({
    required this.userLocationID,
    required this.address,
    required this.userID,
    this.streetNameOrNumber,
    this.buildingNameOrNumber,
    this.floorNumber,
    this.apartment,
    this.nearestLandmark,
    this.isHome = false,
    this.isWork = false,
    this.districtID,
    this.labelName,
    this.latitude,
    this.longitude,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userLocationID: json['UserLocationID'],
      address: json['Address'],
      streetNameOrNumber: json['StreetNameOrNumber'],
      buildingNameOrNumber: json['BuildingNameOrNumber'],
      floorNumber: json['FloorNumber'],
      apartment: json['Apartment'],
      nearestLandmark: json['NearestLandmark'],
      isHome: json['IsHome'] ?? false,
      isWork: json['IsWork'] ?? false,
      userID: json['UserID'],
      districtID: json['DistrictID'],
      labelName: json['LabelName'],
      latitude: json['Latitude'] != null ? (json['Latitude'] as num).toDouble() : null,
      longitude: json['Longitude'] != null ? (json['Longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserLocationID': userLocationID,
      'Address': address,
      'StreetNameOrNumber': streetNameOrNumber,
      'BuildingNameOrNumber': buildingNameOrNumber,
      'FloorNumber': floorNumber,
      'Apartment': apartment,
      'NearestLandmark': nearestLandmark,
      'IsHome': isHome,
      'IsWork': isWork,
      'UserID': userID,
      'DistrictID': districtID,
      'LabelName': labelName,
      'Latitude': latitude,
      'Longitude': longitude,
    };
  }
}
