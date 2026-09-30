import 'dart:async';
import '../datasources/sprint_datasource.dart';
import '../models/sprint_model.dart';
import 'sprint_repository.dart';

class SprintRepositoryImpl implements SprintRepository {
  final SprintDataSource _dataSource;

  SprintRepositoryImpl({SprintDataSource? dataSource})
      : _dataSource = dataSource ?? SprintDataSource();

  @override
  Stream<List<SprintModel>> streamSprints(String projectId) {
    return _dataSource.streamSprints(projectId);
  }

  @override
  Future<void> seedMockSprints(String projectId) {
    return _dataSource.seedMockSprints(projectId);
  }
}
