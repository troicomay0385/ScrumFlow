import 'package:equatable/equatable.dart';

abstract class DeleteUserStoryState extends Equatable {
  const DeleteUserStoryState();

  @override
  List<Object?> get props => [];
}

class DeleteUserStoryIdle extends DeleteUserStoryState {}

class DeleteUserStoryDeleting extends DeleteUserStoryState {}

class DeleteUserStorySuccess extends DeleteUserStoryState {
  final String storyId;
  const DeleteUserStorySuccess(this.storyId);

  @override
  List<Object?> get props => [storyId];
}

class DeleteUserStoryFailure extends DeleteUserStoryState {
  final String message;
  const DeleteUserStoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
