import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/story_repository_impl.dart';
import '../../../domain/repositories/story_repository.dart';
import '../../../domain/usecases/story/update_story_status_usecase.dart';

/// Các trạng thái của [UpdateStoryStatusCubit] (US-048).
abstract class UpdateStoryStatusState extends Equatable {
  const UpdateStoryStatusState();

  @override
  List<Object?> get props => [];
}

class UpdateStoryStatusInitial extends UpdateStoryStatusState {
  const UpdateStoryStatusInitial();
}

class UpdateStoryStatusLoading extends UpdateStoryStatusState {
  const UpdateStoryStatusLoading();
}

class UpdateStoryStatusSuccess extends UpdateStoryStatusState {
  final String newStatus;

  const UpdateStoryStatusSuccess({required this.newStatus});

  @override
  List<Object?> get props => [newStatus];
}

class UpdateStoryStatusFailure extends UpdateStoryStatusState {
  final String message;

  const UpdateStoryStatusFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Cubit điều khiển việc cập nhật trạng thái User Story (US-048).
class UpdateStoryStatusCubit extends Cubit<UpdateStoryStatusState> {
  final UpdateStoryStatusUseCase _useCase;

  UpdateStoryStatusCubit({
    UpdateStoryStatusUseCase? useCase,
    StoryRepository? repository,
  })  : _useCase = useCase ??
            UpdateStoryStatusUseCase(repository ?? StoryRepositoryImpl()),
        super(const UpdateStoryStatusInitial());

  /// Cập nhật trạng thái story
  Future<void> updateStatus({
    required String projectId,
    required String storyId,
    required String newStatus,
  }) async {
    emit(const UpdateStoryStatusLoading());
    try {
      await _useCase(
        projectId: projectId,
        storyId: storyId,
        newStatus: newStatus,
      );
      emit(UpdateStoryStatusSuccess(newStatus: newStatus));
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      emit(UpdateStoryStatusFailure(raw));
    }
  }

  /// Reset trạng thái về Initial
  void reset() {
    emit(const UpdateStoryStatusInitial());
  }
}
