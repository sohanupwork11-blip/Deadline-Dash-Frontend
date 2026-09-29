import 'package:flutter_test/flutter_test.dart';

import 'package:deadline_dash_frontend/models/deadline_models.dart';

void main() {
  test('project model reads progress and task totals from the API', () {
    final project = Project.fromJson({
      'id': 12,
      'name': 'Website launch',
      'description': 'Release the new site',
      'status': 'active',
      'progress_percentage': 60,
      'task_count': 5,
      'completed_task_count': 3,
      'due_date': '2026-10-15',
    });

    expect(project.name, 'Website launch');
    expect(project.progress, 60);
    expect(project.completedTaskCount, 3);
    expect(project.dueDate, DateTime(2026, 10, 15));
  });
}