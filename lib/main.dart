import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'data/datasources/firebase_auth_datasource.dart';
import 'data/datasources/firestore_datasource.dart';
import 'data/datasources/local_cache_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/auth/bloc/auth_event.dart';
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

  // Khởi tạo Repository
  final authRepository = AuthRepositoryImpl(
    authDataSource: firebaseAuthDataSource,
    firestoreDataSource: firestoreDataSource,
    localCacheDataSource: localCacheDataSource,
    connectivityService: connectivityService,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authRepository)..add(AuthCheckRequested()),
        ),
      ],
      child: const ScrumFlowApp(),
    ),
  );
}

class ScrumFlowApp extends StatelessWidget {
  const ScrumFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScrumFlow',
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
