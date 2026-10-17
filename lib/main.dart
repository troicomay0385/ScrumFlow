import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'data/datasources/backlog_datasource.dart';
import 'data/datasources/comment_datasource.dart';
import 'data/datasources/firebase_auth_datasource.dart';
import 'data/datasources/firestore_datasource.dart';
import 'data/datasources/local_cache_datasource.dart';
import 'data/datasources/project_datasource.dart';
import 'data/datasources/project_member_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/backlog_repository.dart';
import 'data/repositories/backlog_repository_impl.dart';
import 'data/repositories/comment_repository.dart';
import 'data/repositories/comment_repository_impl.dart';
import 'data/repositories/project_member_repository.dart';
import 'data/repositories/project_member_repository_impl.dart';
import 'data/datasources/attachment_datasource.dart';
import 'data/repositories/attachment_repository.dart';
import 'data/repositories/attachment_repository_impl.dart';
import 'data/repositories/project_repository.dart';
import 'data/repositories/project_repository_impl.dart';
import 'data/datasources/sprint_datasource.dart';
import 'data/repositories/sprint_repository.dart';
import 'data/repositories/sprint_repository_impl.dart';
import 'data/repositories/task_repository.dart';
import 'data/datasources/work_log_datasource.dart';
import 'data/repositories/work_log_repository.dart';
import 'data/repositories/work_log_repository_impl.dart';
import 'data/repositories/standup_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'domain/repositories/story_repository.dart';
import 'data/repositories/story_repository_impl.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/auth/bloc/auth_event.dart';
import 'presentation/standup/bloc/standup_bloc.dart';
import 'presentation/settings/cubit/theme_cubit.dart';
import 'presentation/settings/cubit/theme_state.dart';
import 'app/services/connectivity_service.dart';
import 'app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'presentation/notifications/bloc/notification_bloc.dart';
import 'presentation/common/widgets/network_status_banner.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Firebase Messaging Background Handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Khởi tạo các DataSources
  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final googleSignIn = GoogleSignIn();

  final firebaseAuthDataSource = FirebaseAuthDataSource(
    auth: firebaseAuth,
    googleSignIn: googleSignIn,
  );
  final firestoreDataSource = FirestoreDataSource(firestore: firestore);
  final localCacheDataSource = LocalCacheDataSource();
  final connectivityService = ConnectivityService();
  final projectDataSource = ProjectDataSource(firestore: firestore);
  final projectMemberDataSource = ProjectMemberDataSource(firestore: firestore);

  final notificationRepository = NotificationRepository(firestore: firestore);

  // Khởi tạo Repository
  final authRepository = AuthRepositoryImpl(
    authDataSource: firebaseAuthDataSource,
    firestoreDataSource: firestoreDataSource,
    localCacheDataSource: localCacheDataSource,
    connectivityService: connectivityService,
  );
  final ProjectRepository projectRepository = ProjectRepositoryImpl(
    projectDataSource: projectDataSource,
    memberDataSource: projectMemberDataSource,
    authDataSource: firebaseAuthDataSource,
    notificationRepository: notificationRepository,
    localCache: localCacheDataSource,
  );
  final ProjectMemberRepository projectMemberRepository = ProjectMemberRepositoryImpl(
    memberDataSource: projectMemberDataSource,
    userDataSource: firestoreDataSource,
    authDataSource: firebaseAuthDataSource,
  );
  final BacklogRepository backlogRepository = BacklogRepositoryImpl(
    dataSource: BacklogDataSource(firestore: firestore),
    memberDataSource: projectMemberDataSource,
    authDataSource: firebaseAuthDataSource,
    notificationRepository: notificationRepository,
    localCache: localCacheDataSource,
  );
  final SprintRepository sprintRepository = SprintRepositoryImpl(
    dataSource: SprintDataSource(firestore: firestore),
  );
  final StandupRepository standupRepository = StandupRepository(firestore: firestore);
  final CommentRepository commentRepository = CommentRepositoryImpl(
    dataSource: CommentDataSource(firestore: firestore),
    memberDataSource: projectMemberDataSource,
    userDataSource: firestoreDataSource,
    authDataSource: firebaseAuthDataSource,
    notificationRepository: notificationRepository,
    firestore: firestore,
  );
  final AttachmentRepository attachmentRepository = AttachmentRepositoryImpl(
    dataSource: AttachmentDataSource(firestore: firestore),
    memberDataSource: projectMemberDataSource,
    userDataSource: firestoreDataSource,
    authDataSource: firebaseAuthDataSource,
  );
  final StoryRepository storyRepository = StoryRepositoryImpl(
    dataSource: BacklogDataSource(firestore: firestore),
    memberDataSource: projectMemberDataSource,
    authDataSource: firebaseAuthDataSource,
  );
  final TaskRepository taskRepository = TaskRepository(
    firestore: firestore,
    notificationRepository: notificationRepository,
    localCache: localCacheDataSource,
  );
  final WorkLogRepository workLogRepository = WorkLogRepositoryImpl(
    dataSource: WorkLogDataSource(firestore: firestore),
    memberRepository: projectMemberRepository,
    taskRepository: taskRepository,
    userDataSource: firestoreDataSource,
    authDataSource: firebaseAuthDataSource,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProjectRepository>.value(value: projectRepository),
        RepositoryProvider<ProjectMemberRepository>.value(
          value: projectMemberRepository,
        ),
        RepositoryProvider<BacklogRepository>.value(value: backlogRepository),
        RepositoryProvider<StoryRepository>.value(value: storyRepository),
        RepositoryProvider<SprintRepository>.value(value: sprintRepository),
        RepositoryProvider<TaskRepository>.value(value: taskRepository),
        RepositoryProvider<WorkLogRepository>.value(value: workLogRepository),
        RepositoryProvider<StandupRepository>.value(value: standupRepository),
        RepositoryProvider<CommentRepository>.value(value: commentRepository),
        RepositoryProvider<AttachmentRepository>.value(
          value: attachmentRepository,
        ),
        RepositoryProvider<NotificationRepository>.value(value: notificationRepository),
        RepositoryProvider<ConnectivityService>.value(
          value: connectivityService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(),
          ),
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepository)..add(AuthCheckRequested()),
          ),
          BlocProvider<StandupBloc>(
            create: (context) => StandupBloc(repository: standupRepository),
          ),
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(
              notificationRepository: notificationRepository,
            ),
          ),
        ],
        child: ScrumFlowApp(
          networkStatus: connectivityService.onStatusChanged,
        ),
      ),
    ),
  );
}

class ScrumFlowApp extends StatelessWidget {
  /// Trạng thái có/không có mạng để hiện dải cảnh báo toàn app (US-063).
  /// `null` = không hiện (vd. trong test).
  final Stream<bool>? networkStatus;

  const ScrumFlowApp({super.key, this.networkStatus});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'ScrumFlow',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeState.themeMode,
          initialRoute: AppRoutes.login,
          // Luôn khởi động từ Login, bỏ qua URL của trình duyệt. Trên Web, khi
          // reload ở một màn con (vd. `#/projects/detail`), Flutter sẽ dựng lại
          // route đó mà KHÔNG có `arguments` (projectId) → crash màn hình đỏ.
          // Login tự chuyển sang Home nếu phiên đăng nhập còn hiệu lực.
          onGenerateInitialRoutes: (_) => [
            AppRoutes.generateRoute(const RouteSettings(name: AppRoutes.login)),
          ],
          onGenerateRoute: AppRoutes.generateRoute,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final content = child ?? const SizedBox.shrink();
            final status = networkStatus;
            if (status == null) return content;
            return NetworkStatusBanner(statusStream: status, child: content);
          },
        );
      },
    );
  }
}

