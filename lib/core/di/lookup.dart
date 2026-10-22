import 'package:get_it/get_it.dart';

/// Der zentrale Service-Locator der App.
final GetIt getIt = GetIt.instance;

/// Holt eine registrierte Abhängigkeit aus [getIt].
///
/// Überall statt `GetIt.instance<T>()` verwenden, z. B.
/// `BlocProvider(create: (_) => lookup<HomeCubit>())`. Cubits mit Parameter (per
/// `registerFactoryParam`) bekommen ihn über [param1], z. B. `lookup<CategoryDetailCubit>(param1: id)`.
T lookup<T extends Object>({String? instanceName, Object? param1, Object? param2}) =>
    getIt<T>(instanceName: instanceName, param1: param1, param2: param2);
