import 'dart:io';

import 'package:in_app_review/in_app_review.dart';

import '../../features/account/cubit/account_cubit.dart';
import '../../features/attachments/cubit/attachments_cubit.dart';
import '../../features/attachments/data/attachments_repository.dart';
import '../../features/attachments/data/mock_attachments_repository.dart';
import '../../features/attachments/data/supabase_attachments_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/mock_auth_repository.dart';
import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/categories/cubit/categories_cubit.dart';
import '../../features/categories/cubit/category_detail_cubit.dart';
import '../../features/categories/cubit/category_setup_cubit.dart';
import '../../features/categories/cubit/field_editor_cubit.dart';
import '../../features/categories/data/categories_repository.dart';
import '../../features/categories/data/category_templates.dart';
import '../../features/categories/data/local_categories_repository.dart';
import '../../features/categories/data/mock_categories_repository.dart';
import '../../features/categories/data/offline_categories_repository.dart';
import '../../features/categories/data/supabase_categories_repository.dart';
import '../../features/entries/cubit/entry_form_cubit.dart';
import '../../features/entries/cubit/tracker_cubit.dart';
import '../../features/home/cubit/home_cubit.dart';
import '../../features/insights/cubit/insights_cubit.dart';
import '../../features/insights/cubit/what_if_cubit.dart';
import '../../features/onboarding/cubit/onboarding_cubit.dart';
import '../../features/plus/cubit/plus_cubit.dart';
import '../../features/plus/data/plus_repository.dart';
import '../../features/plus/data/plus_store.dart';
import '../../features/plus/data/supabase_plus_repository.dart';
import '../../features/reminders/cubit/reminders_cubit.dart';
import '../../features/reminders/data/local_notification_gateway.dart';
import '../../features/reminders/data/notification_gateway.dart';
import '../../features/reminders/data/reminder_service.dart';
import '../../features/settings/cubit/appearance_cubit.dart';
import '../../features/settings/data/appearance_store.dart';
import '../../features/settings/data/review_prompter.dart';
import '../../features/sharing/cubit/sharing_cubit.dart';
import '../../features/sharing/data/invite_links.dart';
import '../../features/shell/cubit/shell_cubit.dart';
import '../../features/storage/cubit/storage_cubit.dart';
import '../../features/storage/data/storage_categories_repository.dart';
import '../../features/storage/data/storage_mode.dart';
import '../../features/storage/data/storage_transfer.dart';
import '../../features/update/cubit/update_cubit.dart';
import '../../features/update/data/app_release.dart';
import '../../features/update/data/installed_app.dart';
import '../../features/update/data/supabase_release_repository.dart';
import '../config/app_config.dart';
import '../network/supabase_api.dart';
import '../utils/json_store.dart';
import 'lookup.dart';

/// Registriert alle Abhängigkeiten. Einmal in `main()` aufrufen.
///
/// Konvention:
/// - Repositories/Services: `registerLazySingleton`
/// - Cubits/Blocs: `registerFactory` (jeder BlocProvider bekommt eine frische Instanz),
///   mit Parameter `registerFactoryParam` (Abruf über `lookup<T>(param1: …)`)
///
/// Daten: `CategoriesRepository` ist die Weiche [StorageCategoriesRepository] – lokal an die Datei
/// auf dem Gerät, in der Cloud an Supabase (mit Supabase-Konfiguration, siehe [AppConfig]) bzw. an
/// die Mocks mit den Beispieldaten aus dem Design.
Future<void> configureDependencies() async {
  final mode = StorageModeStore(FileJsonStore('storage_mode'));
  await mode.load();
  getIt
    ..registerSingleton<StorageModeStore>(mode)
    ..registerLazySingleton<LocalCategoriesRepository>(() => LocalCategoriesRepository(FileJsonStore('local_data', strict: true)));
  if (AppConfig.hasSupabase) {
    await SupabaseBootstrap.init();
    getIt
      ..registerLazySingleton<SupabaseApi>(() => SupabaseApi(SupabaseBootstrap.client))
      ..registerLazySingleton<AuthRepository>(() => SupabaseAuthRepository(SupabaseBootstrap.client))
      ..registerLazySingleton<SupabaseCategoriesRepository>(() => SupabaseCategoriesRepository(lookup<SupabaseApi>(), lookup<AuthRepository>()))
      // Offline-Schicht: Cache zum Lesen, Warteschlange für Einträge (siehe OfflineCategoriesRepository).
      ..registerLazySingleton<OfflineCategoriesRepository>(
        () => OfflineCategoriesRepository(
          lookup<SupabaseCategoriesRepository>(),
          cache: FileJsonStore('categories_cache'),
          queue: FileJsonStore('entry_queue'),
          userId: () => lookup<AuthRepository>().userId,
          accountChanges: lookup<AuthRepository>().accountChanges,
        ),
      )
      ..registerLazySingleton<CategoriesRepository>(
        () => StorageCategoriesRepository(local: lookup<LocalCategoriesRepository>(), cloud: lookup<OfflineCategoriesRepository>(), mode: lookup<StorageModeStore>()),
      )
      ..registerLazySingleton<StorageTransfer>(
        () => StorageTransfer(
          local: lookup<LocalCategoriesRepository>(),
          remote: lookup<SupabaseCategoriesRepository>(),
          cloud: lookup<OfflineCategoriesRepository>(),
          journal: FileJsonStore('transfer_journal'),
          userId: () => lookup<AuthRepository>().userId,
        ),
      )
      ..registerLazySingleton<AppearanceStore>(FileAppearanceStore.new)
      ..registerLazySingleton<PlusRepository>(() => SupabasePlusRepository(lookup<SupabaseApi>(), lookup<AuthRepository>()))
      // Plus gibt es vorerst nur im App Store; auf Android gilt ein dort gekauftes Abo trotzdem.
      ..registerLazySingleton<PlusStore>(
        () => Platform.isIOS ? AppStorePlusStore(lookup<PlusRepository>(), () => lookup<AuthRepository>().userId) : const UnavailablePlusStore(),
      )
      ..registerLazySingleton<AttachmentsRepository>(() => SupabaseAttachmentsRepository(lookup<SupabaseApi>(), lookup<AuthRepository>()))
      ..registerLazySingleton<ReleaseRepository>(() => SupabaseReleaseRepository(lookup<SupabaseApi>()));
  } else {
    getIt
      ..registerLazySingleton<AuthRepository>(MockAuthRepository.new)
      // Der Mock steht für die Cloud; lokal ist auch im Mock-Modus die Datei auf dem Gerät.
      ..registerLazySingleton<MockCategoriesRepository>(MockCategoriesRepository.new)
      ..registerLazySingleton<CategoriesRepository>(
        () => StorageCategoriesRepository(local: lookup<LocalCategoriesRepository>(), cloud: lookup<MockCategoriesRepository>(), mode: lookup<StorageModeStore>()),
      )
      ..registerLazySingleton<StorageTransfer>(
        () => StorageTransfer(
          local: lookup<LocalCategoriesRepository>(),
          remote: lookup<MockCategoriesRepository>(),
          cloud: lookup<MockCategoriesRepository>(),
          journal: MemoryJsonStore(),
          userId: () => lookup<AuthRepository>().userId,
        ),
      )
      ..registerLazySingleton<AppearanceStore>(MemoryAppearanceStore.new)
      ..registerLazySingleton<PlusRepository>(MockPlusRepository.new)
      ..registerLazySingleton<PlusStore>(() => MockPlusStore(lookup<PlusRepository>()))
      ..registerLazySingleton<AttachmentsRepository>(MockAttachmentsRepository.new)
      ..registerLazySingleton<ReleaseRepository>(NoReleaseRepository.new);
  }
  getIt
    // Echte Benachrichtigungen auch im Mock-Modus; Tests tauschen gegen MemoryNotificationGateway.
    ..registerLazySingleton<NotificationGateway>(LocalNotificationGateway.new)
    ..registerLazySingleton<ReminderService>(() => ReminderService(lookup<CategoriesRepository>(), lookup<NotificationGateway>(), FileJsonStore('reminders')))
    ..registerFactory<RemindersCubit>(() => RemindersCubit(lookup<ReminderService>()))
    // Tests tauschen gegen NoInviteLinks und NoReviewPrompter.
    ..registerLazySingleton<InviteLinks>(AppInviteLinks.new)
    ..registerLazySingleton<ReviewPrompter>(
      () => StoreReviewPrompter(FileJsonStore('review'), available: InAppReview.instance.isAvailable, request: InAppReview.instance.requestReview),
    )
    ..registerFactory<AccountCubit>(() => AccountCubit(lookup<AuthRepository>()))
    ..registerFactory<StorageCubit>(() => StorageCubit(lookup<StorageModeStore>(), lookup<StorageTransfer>(), lookup<AuthRepository>(), lookup<PlusRepository>()))
    ..registerFactory<PlusCubit>(() => PlusCubit(lookup<PlusRepository>(), lookup<PlusStore>()))
    ..registerFactory<UpdateCubit>(() => UpdateCubit(lookup<ReleaseRepository>(), InstalledApp.read))
    ..registerFactory<OnboardingCubit>(() => OnboardingCubit(lookup<CategoriesRepository>(), FileJsonStore('onboarding')))
    ..registerFactory<ShellCubit>(ShellCubit.new)
    ..registerFactory<AppearanceCubit>(() => AppearanceCubit(lookup<AppearanceStore>()))
    ..registerFactory<HomeCubit>(() => HomeCubit(lookup<CategoriesRepository>()))
    ..registerFactory<CategoriesCubit>(() => CategoriesCubit(lookup<CategoriesRepository>()))
    ..registerFactory<InsightsCubit>(() => InsightsCubit(lookup<CategoriesRepository>()))
    // Mit Parameter: lookup<…>(param1: …)
    ..registerFactoryParam<CategorySetupCubit, CategoryTemplate?, void>((template, _) => CategorySetupCubit(lookup<CategoriesRepository>(), template))
    ..registerFactoryParam<CategoryDetailCubit, String, void>((id, _) => CategoryDetailCubit(lookup<CategoriesRepository>(), id))
    ..registerFactoryParam<FieldEditorCubit, FieldEditorArgs, void>((args, _) => FieldEditorCubit(lookup<CategoriesRepository>(), args))
    ..registerFactoryParam<EntryFormCubit, EntryFormArgs, void>((args, _) => EntryFormCubit(lookup<CategoriesRepository>(), args))
    ..registerFactoryParam<TrackerCubit, TrackerArgs, void>((args, _) => TrackerCubit(lookup<CategoriesRepository>(), args))
    ..registerFactoryParam<SharingCubit, String, void>((id, _) => SharingCubit(lookup<CategoriesRepository>(), id))
    ..registerFactoryParam<AttachmentsCubit, AttachmentsArgs, void>((args, _) => AttachmentsCubit(lookup<AttachmentsRepository>(), args))
    ..registerFactoryParam<WhatIfCubit, WhatIfArgs, void>((args, _) => WhatIfCubit(args));
}
