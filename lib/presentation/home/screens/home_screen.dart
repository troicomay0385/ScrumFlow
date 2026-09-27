import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/repositories/project_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../projects/bloc/project_list_bloc.dart';
import '../../projects/bloc/project_list_event.dart';
import '../../projects/bloc/project_list_state.dart';
import '../../projects/widgets/project_list_tile.dart';
import '../../settings/widgets/security_settings_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocProvider(
        create: (context) => ProjectListBloc(context.read<ProjectRepository>())
          ..add(ProjectListRequested()),
        child: Builder(builder: (context) {
          final authState = context.watch<AuthBloc>().state;
          final userName =
              authState is AuthAuthenticated ? authState.user.fullName : '';

          return Scaffold(
            appBar: AppBar(
              title: Text(userName.isEmpty ? 'ScrumFlow' : 'Xin chào, $userName'),
              actions: [
                IconButton(
                  tooltip: 'Cài đặt tài khoản & Bảo mật',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => SecuritySettingsDialog.show(context),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<ProjectListBloc>().add(ProjectListRequested());
              },
              child: BlocBuilder<ProjectListBloc, ProjectListState>(
                builder: (context, state) {
                  if (state is ProjectListLoading || state is ProjectListInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ProjectListError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    );
                  }

                  final projects = (state as ProjectListLoaded).projects;
                  if (projects.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Bạn chưa tham gia project nào')),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final summary = projects[index];
                      return ProjectListTile(
                        summary: summary,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.projectDetail,
                          arguments: summary.project.id,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Tạo project'),
              onPressed: () async {
                final created = await Navigator.of(context)
                    .pushNamed(AppRoutes.createProject);
                if (created == true && context.mounted) {
                  context.read<ProjectListBloc>().add(ProjectListRequested());
                }
              },
            ),
          );
        }),
      ),
    );
  }
}
