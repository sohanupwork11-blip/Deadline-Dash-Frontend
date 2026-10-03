import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/deadline_models.dart';
import '../services/api_client.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.api, required this.onSignOut, super.key});

  final ApiClient api;
  final VoidCallback onSignOut;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _data = widget.api.loadDashboard();
  int _selectedIndex = 0;
  final Set<int> _updatingTaskIds = {};

  void _refresh() => setState(() => _data = widget.api.loadDashboard());

  Future<void> _toggleTaskStatus(DeadlineTask task) async {
    setState(() => _updatingTaskIds.add(task.id));
    try {
      await widget.api.updateTaskStatus(task.id, task.status == 'done' ? 'todo' : 'done');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _updatingTaskIds.remove(task.id));
    }
  }

  Future<void> _signOut() async {
    await widget.api.signOut();
    if (mounted) widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 900;
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  if (desktop) _sidebar(),
                  Expanded(
                    child: FutureBuilder<DashboardData>(
                      future: _data,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return _loadError(snapshot.error.toString());
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: forest));
                        }
                        return _content(snapshot.data!, desktop);
                      },
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: desktop ? null : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Overview'),
                NavigationDestination(icon: Icon(Icons.folder_open_rounded), label: 'Projects'),
                NavigationDestination(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
              ],
            ),
          );
        },
      );

  Widget _sidebar() => Container(
        width: 244,
        color: forest,
        padding: const EdgeInsets.fromLTRB(22, 26, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SidebarBrand(),
            const SizedBox(height: 48),
            const Text('WORKSPACE', style: TextStyle(color: Color(0xFFA8BCAF), letterSpacing: 1, fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _navItem(0, Icons.grid_view_rounded, 'Overview'),
            _navItem(1, Icons.folder_open_rounded, 'Projects'),
            _navItem(2, Icons.checklist_rounded, 'Tasks'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: leaf, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Keep your next milestone in view.', style: TextStyle(color: Colors.white, height: 1.35, fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
              label: const Text('Sign out', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      );

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.white.withValues(alpha: .12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        leading: Icon(icon, color: selected ? leaf : Colors.white70, size: 20),
        title: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFFD3DDD5), fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
        onTap: () => setState(() => _selectedIndex = index),
        dense: true,
        minLeadingWidth: 20,
      ),
    );
  }

  Widget _content(DashboardData data, bool desktop) {
    final pageTitle = switch (_selectedIndex) {
      1 => 'Projects',
      2 => 'Tasks',
      _ => 'Overview',
    };
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(desktop ? 38 : 20, 24, desktop ? 38 : 20, 38),
        children: [
          Row(
            children: [
              if (!desktop) const _SmallBrand(),
              if (!desktop) const Spacer(),
              if (desktop) const Spacer(),
              _profileButton(data.subscription),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, MMMM d').format(DateTime.now()), style: const TextStyle(color: Color(0xFF718077), fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 7),
                    Text(_selectedIndex == 0 ? 'Make today count.' : pageTitle, style: const TextStyle(color: ink, fontSize: 30, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              if (desktop || MediaQuery.sizeOf(context).width > 500)
                FilledButton.icon(
                  onPressed: () => _showCreateDialog(data.projects),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(_selectedIndex == 2 ? 'New task' : 'New project'),
                  style: FilledButton.styleFrom(backgroundColor: forest, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15)),
                ),
            ],
          ),
          const SizedBox(height: 25),
          if (_selectedIndex == 0) ..._overview(data, desktop),
          if (_selectedIndex == 1) _projectList(data.projects),
          if (_selectedIndex == 2) _taskList(data.tasks, data.projects),
        ],
      ),
    );
  }

  List<Widget> _overview(DashboardData data, bool desktop) {
    final dueSoon = data.tasks.where((task) => task.dueDate != null && task.status != 'done' && task.dueDate!.difference(DateTime.now()).inDays <= 7).length;
    final average = data.projects.isEmpty ? 0 : (data.projects.map((project) => project.progress).reduce((a, b) => a + b) / data.projects.length).round();
    return [
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760 ? 3 : 1;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.4 : 2.35,
            children: [
              _MetricTile(label: 'Active projects', value: '${data.projects.where((project) => project.status == 'active').length}', icon: Icons.folder_copy_outlined, accent: const Color(0xFFE4F1D1)),
              _MetricTile(label: 'Tasks due this week', value: '$dueSoon', icon: Icons.alarm_rounded, accent: const Color(0xFFF8E9D8)),
              _MetricTile(label: 'Average progress', value: '$average%', icon: Icons.trending_up_rounded, accent: const Color(0xFFDCECE7)),
            ],
          );
        },
      ),
      const SizedBox(height: 30),
      _sectionHeading('Your projects', '${data.projects.length} total', onTap: () => setState(() => _selectedIndex = 1)),
      const SizedBox(height: 14),
      if (data.projects.isEmpty)
        _EmptyState(title: 'Your next big thing starts here', action: 'Create your first project', onTap: () => _showCreateDialog(data.projects))
      else
        _projectList(data.projects.take(3).toList()),
      const SizedBox(height: 30),
      _sectionHeading('Up next', '${data.tasks.length} tasks', onTap: () => setState(() => _selectedIndex = 2)),
      const SizedBox(height: 14),
      if (data.tasks.isEmpty)
        _EmptyState(title: 'No tasks on the board yet', action: 'Add a task', onTap: () => _showCreateDialog(data.projects))
      else
        _taskList(data.tasks.take(5).toList(), data.projects),
      const SizedBox(height: 24),
      if (!desktop)
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
    ];
  }

  Widget _projectList(List<Project> projects) {
    if (projects.isEmpty) {
      return _EmptyState(title: 'No projects yet', action: 'Create a project', onTap: () => _showCreateDialog(const []));
    }
    return Column(
      children: projects.map((project) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ProjectTile(project: project),
      )).toList(),
    );
  }

  Widget _taskList(List<DeadlineTask> tasks, List<Project> projects) {
    if (tasks.isEmpty) {
      return _EmptyState(title: 'Nothing due right now', action: 'Add a task', onTap: () => _showCreateDialog(projects));
    }
    return Column(
      children: tasks.map((task) {
        final project = projects.where((item) => item.id == task.projectId).firstOrNull;
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _TaskTile(
            task: task,
            projectName: project?.name ?? 'Project',
            isUpdating: _updatingTaskIds.contains(task.id),
            onToggle: () => _toggleTaskStatus(task),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionHeading(String title, String trailing, {required VoidCallback onTap}) => Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 18))),
          TextButton(onPressed: onTap, child: Text('$trailing  ·  View all')),
        ],
      );

  Widget _profileButton(SubscriptionInfo subscription) => PopupMenuButton<String>(
        tooltip: 'Account',
        onSelected: (value) {
          if (value == 'signout') _signOut();
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'plan', enabled: false, child: Text('${subscription.plan.toUpperCase()} plan')),
          const PopupMenuItem(value: 'signout', child: Text('Sign out')),
        ],
        child: Row(
          children: [
            Container(width: 34, height: 34, decoration: const BoxDecoration(color: leaf, shape: BoxShape.circle), child: const Icon(Icons.person_outline_rounded, color: forest, size: 20)),
            const SizedBox(width: 9),
            Text(subscription.plan.toUpperCase(), style: const TextStyle(color: forest, fontSize: 11, fontWeight: FontWeight.w800)),
            const Icon(Icons.expand_more_rounded, color: ink),
          ],
        ),
      );

  Widget _loadError(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: Color(0xFFB44839), size: 38),
              const SizedBox(height: 14),
              const Text('Could not load your workspace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF718077))),
              const SizedBox(height: 18),
              FilledButton(onPressed: _refresh, child: const Text('Try again')),
            ],
          ),
        ),
      );

  Future<void> _showCreateDialog(List<Project> projects) async {
    final createTask = _selectedIndex == 2;
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _CreateDialog(api: widget.api, projects: projects, createTask: createTask),
    );
    if (created == true) _refresh();
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          _BoltMark(),
          SizedBox(width: 10),
          Text('Deadline Dash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      );
}

class _SmallBrand extends StatelessWidget {
  const _SmallBrand();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          _BoltMark(),
          SizedBox(width: 8),
          Text('Deadline Dash', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      );
}

class _BoltMark extends StatelessWidget {
  const _BoltMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 31,
        height: 31,
        decoration: BoxDecoration(color: leaf, borderRadius: BorderRadius.circular(9)),
        child: const Icon(Icons.bolt_rounded, color: forest, size: 20),
      );
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, required this.icon, required this.accent});

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: forest, size: 21)),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF718077), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w800))),
                _StatusPill(text: project.status.replaceAll('_', ' ')),
              ],
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(project.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF718077), fontSize: 12)),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: project.progress / 100, minHeight: 7, backgroundColor: const Color(0xFFE9EEE7), color: const Color(0xFF74A83A)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('${project.progress}% complete', style: const TextStyle(color: Color(0xFF526157), fontSize: 12, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${project.completedTaskCount}/${project.taskCount} tasks', style: const TextStyle(color: Color(0xFF718077), fontSize: 12)),
                const SizedBox(width: 14),
                Text(project.dueDate == null ? 'No deadline' : 'Due ${DateFormat('MMM d').format(project.dueDate!)}', style: const TextStyle(color: Color(0xFF718077), fontSize: 12)),
              ],
            ),
          ],
        ),
      );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.projectName,
    required this.isUpdating,
    required this.onToggle,
  });

  final DeadlineTask task;
  final String projectName;
  final bool isUpdating;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final completed = task.status == 'done';
    final urgent = task.priority == 'urgent' || task.priority == 'high';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: [
          IconButton(
            tooltip: completed ? 'Reopen task' : 'Mark task complete',
            onPressed: isUpdating ? null : onToggle,
            icon: isUpdating
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: completed
                        ? const Color(0xFF73A73B)
                        : const Color(0xFFABB5AC),
                    size: 21,
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ink, fontWeight: FontWeight.w700, decoration: completed ? TextDecoration.lineThrough : null)),
                const SizedBox(height: 3),
                Text(projectName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF718077), fontSize: 11)),
              ],
            ),
          ),
          if (urgent) const Padding(padding: EdgeInsets.only(right: 12), child: _PriorityPill()),
          Text(task.dueDate == null ? 'No date' : DateFormat('MMM d').format(task.dueDate!), style: TextStyle(color: task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && !completed ? const Color(0xFFB44839) : const Color(0xFF66736A), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFEAF2E4), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: forest, fontWeight: FontWeight.w700, fontSize: 10)),
      );
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFFFE9E2), borderRadius: BorderRadius.circular(18)),
        child: const Text('PRIORITY', style: TextStyle(color: Color(0xFF9E4C38), fontSize: 9, fontWeight: FontWeight.w800)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.action, required this.onTap});

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            const Icon(Icons.flag_outlined, color: forest, size: 28),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
            TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      );
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog({required this.api, required this.projects, required this.createTask});

  final ApiClient api;
  final List<Project> projects;
  final bool createTask;

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime? _dueDate;
  Project? _project;
  String _priority = 'medium';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (widget.createTask) {
        await widget.api.createTask(projectId: _project!.id, title: _title.text.trim(), priority: _priority, dueDate: _dueDate);
      } else {
        await widget.api.createProject(name: _title.text.trim(), description: _description.text.trim(), dueDate: _dueDate);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.createTask;
    return AlertDialog(
      title: Text(task ? 'Add a task' : 'Create a project'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(controller: _title, autofocus: true, validator: (value) => value == null || value.trim().isEmpty ? 'This field is required.' : null, decoration: InputDecoration(labelText: task ? 'Task name' : 'Project name')),
                if (task) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Project>(
                    initialValue: _project,
                    items: widget.projects.map((item) => DropdownMenuItem(value: item, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (value) => setState(() => _project = value),
                    validator: (value) => value == null ? 'Choose a project.' : null,
                    decoration: const InputDecoration(labelText: 'Project'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low priority')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium priority')),
                      DropdownMenuItem(value: 'high', child: Text('High priority')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (value) => setState(() => _priority = value ?? 'medium'),
                    decoration: const InputDecoration(labelText: 'Priority'),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  TextFormField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)')),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
                    if (selected != null) setState(() => _dueDate = selected);
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(_dueDate == null ? 'Set a due date' : DateFormat('MMM d, yyyy').format(_dueDate!)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFB44839))),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create')),
      ],
    );
  }
}