import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_router.dart';
import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'di/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

class BadrgoApp extends StatefulWidget {
  const BadrgoApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<BadrgoApp> createState() => _BadrgoAppState();
}

class _BadrgoAppState extends State<BadrgoApp> {
  late final AuthBloc _authBloc = AuthBloc(
    authRepository: widget.deps.authRepository,
    authSession: widget.deps.authSession,
    sseClient: widget.deps.sseClient,
    wsClient: widget.deps.wsClient,
  )..add(const AuthBootstrapRequested());

  late final ConnectivityBloc _connectivityBloc = ConnectivityBloc(
    rest: widget.deps.restClient,
    realtimeHub: widget.deps.realtimeHub,
  )..add(const ConnectivityStarted());

  late final SettingsCubit _settingsCubit = SettingsCubit(widget.deps.prefs);

  late final ChatBloc _chatBloc =
      ChatBloc(repository: widget.deps.chatRepository);

  late final router =
      createRouter(authBloc: _authBloc, deps: widget.deps);

  @override
  void dispose() {
    _authBloc.close();
    _connectivityBloc.close();
    _settingsCubit.close();
    _chatBloc.close();
    widget.deps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: widget.deps,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _connectivityBloc),
          BlocProvider.value(value: _settingsCubit),
          BlocProvider.value(value: _chatBloc),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) {
            return MaterialApp.router(
              title: 'badrgo Ops Console',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: settings.themeMode,
              locale: settings.locale,
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppStringsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: router,
              builder: (context, child) {
                return Directionality(
                  textDirection: settings.locale.languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
