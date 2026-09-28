import '../datasources/backlog_datasource.dart';
import '../models/user_story_model.dart';
import 'backlog_repository.dart';

class BacklogRepositoryImpl implements BacklogRepository {
  final BacklogDataSource _dataSource;

  BacklogRepositoryImpl({BacklogDataSource? dataSource})
      : _dataSource = dataSource ?? BacklogDataSource();

  @override
  Stream<List<UserStoryModel>> streamUserStories(String projectId) {
    return _dataSource.streamUserStories(projectId);
  }

  @override
  Future<List<UserStoryModel>> getUserStories(String projectId) {
    return _dataSource.getUserStories(projectId);
  }

  @override
  Future<UserStoryModel?> getUserStory(String projectId, String storyId) {
    return _dataSource.getUserStory(projectId, storyId);
  }

  @override
  Future<void> saveUserStory(String projectId, UserStoryModel story) {
    return _dataSource.saveUserStory(projectId, story);
  }

  @override
  Future<void> seedMockStories(String projectId) {
    return _dataSource.seedMockStories(projectId);
  }
}
