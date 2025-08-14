class UserModel {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String mobile;       // correspond au champ backend
  final String dateOfBirth;  // format "YYYY-MM-DD"

  UserModel({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
      'dateOfBirth': dateOfBirth,
    };

    print('📤 Payload envoyé au backend: $data'); // debug
    return data;
  }
}
