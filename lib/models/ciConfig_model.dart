class CiconfigModel {
  final String ciPrimaryColor;
  final String ciSecondaryColor;
  final String ciClientName;
  final String ciLogo;
  final bool ciShowBrands;
  final bool ciShowTopSeller;
  final bool ciShowCategories;
  final bool ciEnableGoogleLogin;
  final bool ciEnableFacebookLogin;
  final bool ciEnableAppleLogin;
  final String ciDefaultLanguage;

  CiconfigModel({
    required this.ciPrimaryColor,
    required this.ciSecondaryColor,
    required this.ciClientName,
    required this.ciLogo,
    required this.ciShowBrands,
    required this.ciShowTopSeller,
    required this.ciShowCategories,
    required this.ciEnableGoogleLogin,
    required this.ciEnableFacebookLogin,
    required this.ciEnableAppleLogin,
    required this.ciDefaultLanguage,
  });

  factory CiconfigModel.fromJson(Map<String, dynamic> json) {
    return CiconfigModel(
      ciPrimaryColor: json['CIPrimaryColor'] ?? '',
      ciSecondaryColor: json['CISecondaryColor'] ?? '',
      ciClientName: json['CIClientName'] ?? '',
      ciLogo: json['CILogo'] ?? '',
      ciShowBrands: json['CIShowBrands'] ?? false,
      ciShowTopSeller: json['CIShowTopSeller'] ?? false,
      ciShowCategories: json['CIShowCategories'] ?? false,
      ciEnableGoogleLogin: json['CIEnableGoogleLogin'] ?? false,
      ciEnableFacebookLogin: json['CIEnableFacebookLogin'] ?? false,
      ciEnableAppleLogin: json['CIEnableAppleLogin'] ?? false,
      ciDefaultLanguage: json['CIDefaultLanguage'] ?? 'en',
    );
  }
}
