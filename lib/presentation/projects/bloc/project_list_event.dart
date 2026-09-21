import 'package:equatable/equatable.dart';

abstract class ProjectListEvent extends Equatable {
  const ProjectListEvent();

  @override
  List<Object?> get props => [];
}

/// Tải (hoặc tải lại) danh sách project của user hiện tại.
class ProjectListRequested extends ProjectListEvent {}
