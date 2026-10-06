import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'data/datasources/backlog_datasource.dart';
import 'data/datasources/firebase_auth_datasource.dart';
import 'data/datasources/firestore_datasource.dart';
import 'data/datasources/local_cache_datasource.dart';
import 'data/datasources/project_datasource.dart';
import 'data/datasources/project_member_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/backlog_repository.dart';
import 'data/repositories/backlog_repository_impl.dart';
import 'data/repositories/project_member_repository.dart';
import 'data/repositories/project_member_repository_impl.dart';
import 'data/repositories/project_repository.dart';
import 'data/repositories/project_repository_impl.dart';
import 'data/datasources/sprint_datasource.dart';
import 'data/repositories/sprint_repository.dart';
import 'data/repositories/sprint_repository_impl.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/standup_repository.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/auth/bloc/auth_event.dart';
import 'presentation/standup/bloc/standup_bloc.dart';
import 'app/services/connectivity_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  );
  final SprintRepository sprintRepository = SprintRepositoryImpl(
    dataSource: SprintDataSource(firestore: firestore),
  );
  final StandupRepository standupRepository = StandupRepository(firestore: firestore);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProjectRepository>.value(value: projectRepository),
        RepositoryProvider<ProjectMemberRepository>.value(
          value: projectMemberRepository,
        ),
        RepositoryProvider<BacklogRepository>.value(value: backlogRepository),
        RepositoryProvider<SprintRepository>.value(value: sprintRepository),
        RepositoryProvider<TaskRepository>(create: (_) => TaskRepository(firestore: firestore)),
        RepositoryProvider<StandupRepository>.value(value: standupRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepository)..add(AuthCheckRequested()),
          ),
          BlocProvider<StandupBloc>(
            create: (context) => StandupBloc(repository: standupRepository),
          ),
        ],
        child: const ScrumFlowApp(),
      ),
    ),
  );
}

class ScrumFlowApp extends StatelessWidget {
  const ScrumFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScrumFlow',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
