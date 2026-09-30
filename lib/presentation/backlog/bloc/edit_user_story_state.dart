import 'package:equatable/equatable.dart';

import '../../../data/models/user_story_model.dart';

abstract class EditUserStoryState extends Equatable {
  const EditUserStoryState();

  @override
  List<Object?> get props => [];
}

class EditUserStoryIdle extends EditUserStoryState {}

class EditUserStorySubmitting extends EditUserStoryState {}

class EditUserStorySuccess extends EditUserStoryState {
  final UserStoryModel story;

  const EditUserStorySuccess(this.story);

  @override
  List<Object?> get props => [story];
}

class EditUserStoryFailure extends EditUserStoryState {
  final String message;

  const EditUserStoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
