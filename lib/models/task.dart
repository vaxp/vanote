import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskStatus {
  @HiveField(0)
  notStarted,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  completed,
}

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String description;
  @HiveField(3)
  String category;
  @HiveField(4)
  TaskStatus status;
  @HiveField(5)
  DateTime createdAt;
  @HiveField(6)
  DateTime? updatedAt;

  Task({
    String? id,
    required this.title,
    required this.description,
    required this.category,
    this.status = TaskStatus.notStarted,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        // ignore: unnecessary_this
        this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: TaskStatus.values[json['status'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
    )..updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null;
  }

  Task copyWith({
    String? title,
    String? description,
    String? category,
    TaskStatus? status,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt,
    )..updatedAt = DateTime.now();
  }
}