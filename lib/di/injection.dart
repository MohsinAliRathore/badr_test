import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/auth_session.dart';
import '../core/network/graphql_client.dart';
import '../core/network/rest_client.dart';
import '../core/network/session_store.dart';
import '../core/network/sse_client.dart';
import '../core/network/ws_client.dart';
import '../features/alerts/data/repositories/alert_repository_impl.dart';
import '../features/alerts/domain/repositories/alert_repository.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/chat/data/repositories/chat_repository.dart';
import '../features/dashboard/data/repositories/kpi_repository_impl.dart';
import '../features/dashboard/domain/repositories/kpi_repository.dart';
import '../features/drivers/data/repositories/driver_admin_repository.dart';
import '../features/realtime/data/realtime_hub.dart';
import '../features/riders/data/repositories/rider_admin_repository.dart';
import '../features/trips/data/repositories/trip_repository_impl.dart';
import '../features/trips/domain/repositories/trip_repository.dart';
import '../features/users/data/repositories/user_repository_impl.dart';

class AppDependencies {
  AppDependencies._({
    required this.prefs,
    required this.sessionStore,
    required this.authSession,
    required this.restClient,
    required this.graphqlClient,
    required this.sseClient,
    required this.wsClient,
    required this.realtimeHub,
    required this.authRepository,
    required this.kpiRepository,
    required this.tripRepository,
    required this.alertRepository,
    required this.userRepository,
    required this.driverAdminRepository,
    required this.riderAdminRepository,
    required this.chatRepository,
  });

  final SharedPreferences prefs;
  final SessionStore sessionStore;
  final AuthSession authSession;
  final RestClient restClient;
  final GraphqlClient graphqlClient;
  final SseClient sseClient;
  final WsClient wsClient;
  final RealtimeHub realtimeHub;
  final AuthRepository authRepository;
  final KpiRepository kpiRepository;
  final TripRepository tripRepository;
  final AlertRepository alertRepository;
  final UserRepository userRepository;
  final DriverAdminRepository driverAdminRepository;
  final RiderAdminRepository riderAdminRepository;
  final ChatRepository chatRepository;

  static Future<AppDependencies> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = SessionStore(prefs);
    final session = AuthSession(initialToken: store.token);
    final rest = RestClient(session: session);
    final graphql = GraphqlClient(rest: rest, session: session);
    final sse = SseClient(session: session, prefs: prefs);
    final ws = WsClient(session: session);
    final hub = RealtimeHub(sse: sse, ws: ws);

    return AppDependencies._(
      prefs: prefs,
      sessionStore: store,
      authSession: session,
      restClient: rest,
      graphqlClient: graphql,
      sseClient: sse,
      wsClient: ws,
      realtimeHub: hub,
      authRepository: AuthRepositoryImpl(
        rest: rest,
        store: store,
        session: session,
      ),
      kpiRepository: KpiRepositoryImpl(graphql),
      tripRepository: TripRepositoryImpl(graphql: graphql, rest: rest),
      alertRepository: AlertRepositoryImpl(graphql: graphql, rest: rest),
      userRepository: UserRepositoryImpl(rest),
      driverAdminRepository: DriverAdminRepositoryImpl(
        graphql: graphql,
        rest: rest,
      ),
      riderAdminRepository: RiderAdminRepositoryImpl(
        graphql: graphql,
        rest: rest,
      ),
      chatRepository: ChatRepositoryImpl(rest: rest, hub: hub),
    );
  }

  void dispose() {
    sseClient.dispose();
    wsClient.dispose();
    authSession.dispose();
  }
}
