import 'package:equatable/equatable.dart';
import '../../../data/models/user_story_model.dart';

abstract class BacklogState extends Equatable {
  const BacklogState();

  @override
  List<Object?> get props => [];
}

class BacklogInitial extends BacklogState {}

class BacklogLoading extends BacklogState {}

class BacklogLoaded extends BacklogState {
  final List<UserStoryModel> stories;
  final bool isSeeding;

  const BacklogLoaded({
    required this.stories,
    this.isSeeding = false,
  });

  @override
  List<Object?> get props => [stories, isSeeding];

  BacklogLoaded copyWith({
    List<UserStoryModel>? stories,
    bool? isSeeding,
  }) {
    return BacklogLoaded(
      stories: stories ?? this.stories,
      isSeeding: isSeeding ?? this.isSeeding,
    );
  }
}

class BacklogError extends BacklogState {
  final String message;

  const BacklogError(this.message);

  @override
  List<Object?> get props => [message];
}
