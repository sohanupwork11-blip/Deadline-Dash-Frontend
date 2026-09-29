class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.progress,
    required this.taskCount,
    required this.completedTaskCount,
    this.dueDate,
  });

  final int id;
  final String name;
  final String description;
  final String status;
  final int progress;
  final int taskCount;
  final int completedTaskCount;
  final DateTime? dueDate;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as int,
        name: json['name'] as String? ?? 'Untitled project',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'planning',
        progress: (json['progress_percentage'] as num?)?.round() ?? 0,
        taskCount: json['task_count'] as int? ?? 0,
        completedTaskCount: json['completed_task_count'] as int? ?? 0,
        dueDate: json['due_date'] == null
            ? null
            : DateTime.tryParse(json['due_date'] as String),
      );
}

class DeadlineTask {
  const DeadlineTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.status,
    required this.priority,
    this.dueDate,
  });

  final int id;
  final int projectId;
  final String title;
  final String status;
  final String priority;
  final DateTime? dueDate;

  factory DeadlineTask.fromJson(Map<String, dynamic> json) => DeadlineTask(
        id: json['id'] as int,
        projectId: json['project'] as int,
        title: json['title'] as String? ?? 'Untitled task',
        status: json['status'] as String? ?? 'todo',
        priority: json['priority'] as String? ?? 'medium',
        dueDate: json['due_date'] == null
            ? null
            : DateTime.tryParse(json['due_date'] as String),
      );
}

class SubscriptionInfo {
  const SubscriptionInfo({required this.plan, required this.status});

  final String plan;
  final String status;

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) =>
      SubscriptionInfo(
        plan: json['plan'] as String? ?? 'free',
        status: json['status'] as String? ?? 'active',
      );
}

class DashboardData {
  const DashboardData({
    required this.projects,
    required this.tasks,
    required this.subscription,
  });

  final List<Project> projects;
  final List<DeadlineTask> tasks;
  final SubscriptionInfo subscription;
}