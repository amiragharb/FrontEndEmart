class Category {
  final int id;
  final String nameEn;
  final String nameAr;
  final bool? showInMenu;
  final bool? showInHome;
  final String logo; // champ pour l'image

  Category({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.showInMenu,
    this.showInHome,
    required this.logo, // <-- il faut l'ajouter ici
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
      showInMenu: json['showInMenu'],
      showInHome: json['showInHome'],
      logo: json['logo'] ?? '', // <-- fallback si null
    );
  }
}
