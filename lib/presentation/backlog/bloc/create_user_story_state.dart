import 'package:equatable/equatable.dart';

import '../../../data/models/user_story_model.dart';

abstract class CreateUserStoryState extends Equatable {
  const CreateUserStoryState();

  @override
  List<Object?> get props => [];
}

class CreateUserStoryIdle extends CreateUserStoryState {}

class CreateUserStorySubmitting extends CreateUserStoryState {}

class CreateUserStorySuccess extends CreateUserStoryState {
  final UserStoryModel story;

  const CreateUserStorySuccess(this.story);

  @override
  List<Object?> get props => [story];
}

class CreateUserStoryFailure extends CreateUserStoryState {
  final String message;

  const CreateUserStoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
