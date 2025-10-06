// models/card_input.dart
class CardInput {
  final String holderName;
  final String number;     // non masqué ici, à chiffrer côté prod
  final int expMonth;      // 1..12
  final int expYear;       // ex: 2028
  final String cvv;        // 3-4 digits

  CardInput({
    required this.holderName,
    required this.number,
    required this.expMonth,
    required this.expYear,
    required this.cvv,
  });

  String get last4 => number.length >= 4 ? number.substring(number.length - 4) : number;
}
