import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Автор поста. Содержит ВЛОЖЕННЫЕ модели Address и Company.
/// explicitToJson: true — чтобы вложенные объекты тоже превращались в JSON.
@JsonSerializable(explicitToJson: true)
class User {
  final int id;
  final String name;
  final String username;

  // Необязательные данные — nullable.
  final String? email;
  final String? phone;
  final String? website;
  final Address? address;
  final Company? company;

  const User({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class Address {
  final String? street;
  final String? suite;
  final String? city;
  final String? zipcode;

  const Address({this.street, this.suite, this.city, this.zipcode});

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable()
class Company {
  final String? name;
  final String? catchPhrase;

  const Company({this.name, this.catchPhrase});

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);

  Map<String, dynamic> toJson() => _$CompanyToJson(this);
}
