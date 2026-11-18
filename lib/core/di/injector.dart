import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/discovery_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/relationship_repository.dart';
import '../../data/repositories/safety_repository.dart';
import '../network/dio_client.dart';
import '../storage/token_storage.dart';

final sl = GetIt.instance;

/// Registers the Model layer (network + repositories). ViewModels (Blocs) are
/// created by BlocProvider in the widget tree and receive repositories from here.
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl
    ..registerSingleton<TokenStorage>(TokenStorage(prefs))
    ..registerLazySingleton<DioClient>(() => DioClient(tokenStorage: sl()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepository(sl(), sl()))
    ..registerLazySingleton<ProfileRepository>(() => ProfileRepository(sl()))
    ..registerLazySingleton<DiscoveryRepository>(() => DiscoveryRepository(sl()))
    ..registerLazySingleton<MatchRepository>(() => MatchRepository(sl()))
    ..registerLazySingleton<RelationshipRepository>(() => RelationshipRepository(sl()))
    ..registerLazySingleton<SafetyRepository>(() => SafetyRepository(sl()));
}
