import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.isOnboarded = false,
  });

  final String id;
  final String name;
  final String email;

  /// False until the user finished profile setup (photos, intent, prompts...).
  final bool isOnboarded;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        isOnboarded: json['is_onboarded'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'is_onboarded': isOnboarded,
      };

  AppUser copyWith({String? name, bool? isOnboarded}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        isOnboarded: isOnboarded ?? this.isOnboarded,
      );

  @override
  List<Object?> get props => [id, name, email, isOnboarded];
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.refreshToken, required this.user});

  final String accessToken;
  final String refreshToken;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
