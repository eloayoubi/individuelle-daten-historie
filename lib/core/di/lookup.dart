import 'package:get_it/get_it.dart';

/// Der zentrale Service-Locator der App.
final GetIt getIt = GetIt.instance;

/// Holt eine registrierte Abhängigkeit aus [getIt].
///
/// Überall statt `GetIt.instance<T>()` verwenden, z. B.
/// `BlocProvider(create: (_) => lookup<HomeCubit>())`.
T lookup<T extends Object>({String? instanceName}) => getIt<T>(instanceName: instanceName);
