import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/repositories/project_repository.dart';
import '../../auth/widgets/auth_button.dart';
import '../bloc/create_project_cubit.dart';
import '../bloc/create_project_state.dart';

class CreateProjectScreen extends StatelessWidget {
  const CreateProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateProjectCubit(context.read<ProjectRepository>()),
      child: const _CreateProjectView(),
    );
  }
}

class _CreateProjectView extends StatefulWidget {
  const _CreateProjectView();

  @override
  State<_CreateProjectView> createState() => _CreateProjectViewState();
}

class _CreateProjectViewState extends State<_CreateProjectView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<CreateProjectCubit>().submit(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo project')),
      body: BlocListener<CreateProjectCubit, CreateProjectState>(
        listener: (context, state) {
          if (state is CreateProjectSuccess) {
            Navigator.of(context).pop(true);
          } else if (state is CreateProjectFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên project *',
                    hintText: 'Nhập tên dự án',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Vui lòng nhập tên project'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mục tiêu hoặc mô tả dự án',
                    hintText: 'Mục tiêu của dự án, định hướng backlog & sprint...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                BlocBuilder<CreateProjectCubit, CreateProjectState>(
                  builder: (context, state) {
                    return AuthButton(
                      text: 'Tạo project',
                      isLoading: state is CreateProjectSubmitting,
                      onPressed: _submit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
