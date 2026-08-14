import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/card.dart';
import '../widgets/text.dart';
import '../widgets/fog.dart';
import '../services/tasks.dart';
import 'package:edge/l10n/app_localizations.dart';

/// Tasks screen — Görevler tab with Firestore-backed task list.
class TasksScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final bool canManageTasks;
  final bool isEmbedded;

  const TasksScreen({
    super.key,
    required this.userName,
    required this.userRole,
    this.canManageTasks = false,
    this.isEmbedded = false,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TaskService _taskService = TaskService();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return StreamBuilder<List<VertexTask>>(
      stream: _taskService.watchTasks(isAdmin: widget.canManageTasks),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        final content = ScrollFog(
          scrollController: _scrollController,
          color: AppColors.background,
          child: CustomScrollView(
            controller: _scrollController,
            shrinkWrap: widget.isEmbedded,
            physics: widget.isEmbedded
                ? const AlwaysScrollableScrollPhysics()
                : null,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(isDark, tasks),
                      const SizedBox(height: 28),
                      _buildStatsRow(tasks),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.activeTasks,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor.inverted,
                            ),
                          ),
                          if (widget.canManageTasks)
                            IconButton(
                              onPressed: () => _showCreateTaskSheet(context),
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: AppColors.senaryColor,
                              ),
                              tooltip: 'Görev Ata',
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .taskCount(tasks.length),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.tertiaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  tasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (tasks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Henüz görev yok',
                      style: GoogleFonts.inter(
                        color: AppColors.tertiaryColor,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTaskCard(tasks[index], isDark),
                      ),
                      childCount: tasks.length,
                    ),
                  ),
                ),
            ],
          ),
        );

        return widget.isEmbedded ? content : SafeArea(child: content);
      },
    );
  }

  Widget _buildWelcomeCard(bool isDark, List<VertexTask> tasks) {
    final open = tasks.where((t) => t.status != TaskStatus.done).length;
    return VertexCard(
      animatedBorder: true,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                child: Center(
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : 'V',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor.inverted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText(
                      'Merhaba, ${widget.userName}! 👋',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.userRole,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.tertiaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.uncompletedTasksToday(open),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.tertiaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<VertexTask> tasks) {
    final todo = tasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgress =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final done = tasks.where((t) => t.status == TaskStatus.done).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: AppLocalizations.of(context)!.todo,
            value: '$todo',
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: AppLocalizations.of(context)!.inProgress,
            value: '$inProgress',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: AppLocalizations.of(context)!.completed,
            value: '$done',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(VertexTask task, bool isDark) {
    return GestureDetector(
      onTap: () => _showTaskDetailPanel(context, task),
      child: VertexCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor(task.status),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor(task.status).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor.inverted,
                      decoration: task.status == TaskStatus.done
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.tertiaryColor,
                    ),
                  ),
                ),
                _priorityBadge(task.priority),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.tertiaryColor,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _statusBadge(task),
                const Spacer(),
                _dueLabel(task),
              ],
            ),
            if (widget.canManageTasks && task.assigneeName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Atanan: ${task.assigneeName}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.tertiaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _priorityBadge(TaskPriority priority) {
    final (label, color) = switch (priority) {
      TaskPriority.high => ('Yüksek', AppColors.septenaryColor),
      TaskPriority.medium => ('Orta', Colors.orange),
      TaskPriority.low => ('Düşük', Colors.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _statusBadge(VertexTask task) {
    final color = _statusColor(task.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel(task.status),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dueLabel(VertexTask task) {
    final days = task.daysRemaining;
    String label;
    Color color = AppColors.tertiaryColor;
    if (days == null) {
      label = 'Tarih yok';
    } else if (days < 0) {
      label = 'Süre doldu';
      color = AppColors.septenaryColor;
    } else if (days == 0) {
      label = 'Bugün';
      color = Colors.orange;
    } else {
      label = '$days gün kaldı';
      if (days <= 3) color = Colors.orange;
    }
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return AppLocalizations.of(context)!.todo;
      case TaskStatus.inProgress:
        return AppLocalizations.of(context)!.statusInProgress;
      case TaskStatus.done:
        return AppLocalizations.of(context)!.statusDone;
    }
  }

  void _showTaskDetailPanel(BuildContext context, VertexTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final days = task.daysRemaining;
        String timeLabel;
        if (days == null) {
          timeLabel = 'Bitiş tarihi belirtilmemiş';
        } else if (days < 0) {
          timeLabel = 'Süre ${days.abs()} gün önce doldu';
        } else if (days == 0) {
          timeLabel = 'Bugün bitiyor';
        } else {
          timeLabel = '$days gün süre kaldı';
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                task.title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor.inverted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16, color: AppColors.senaryColor),
                  const SizedBox(width: 6),
                  Text(
                    timeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.senaryColor,
                    ),
                  ),
                ],
              ),
              if (task.dueDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Bitiş: ${_formatDate(task.dueDate!)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.tertiaryColor,
                  ),
                ),
              ],
              if (task.assigneeName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Atanan: ${task.assigneeName}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.tertiaryColor,
                  ),
                ),
              ],
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  task.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.tertiaryColor,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Durum',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor.inverted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: TaskStatus.values.map((s) {
                  final selected = task.status == s;
                  return ChoiceChip(
                    label: Text(_statusLabel(s)),
                    selected: selected,
                    onSelected: (_) async {
                      await _taskService.updateStatus(task.id, s);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    selectedColor: _statusColor(s).withValues(alpha: 0.2),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: selected
                          ? _statusColor(s)
                          : AppColors.tertiaryColor,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateTaskSheet(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 15));
    TaskPriority priority = TaskPriority.medium;
    String? selectedUserId;
    String? selectedUserName;

    final assignees = await _taskService.listAssignees();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Görev Ata',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor.inverted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Başlık',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: 'Kişi',
                        border: OutlineInputBorder(),
                      ),
                      items: assignees
                          .map(
                            (u) => DropdownMenuItem(
                              value: u['userId'] as String,
                              child: Text(u['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        final user = assignees.firstWhere(
                          (u) => u['userId'] == v,
                        );
                        setSheetState(() {
                          selectedUserId = v;
                          selectedUserName = user['name'] as String;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Bitiş: ${_formatDate(dueDate)}',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setSheetState(() => dueDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskPriority>(
                      value: priority,
                      decoration: const InputDecoration(
                        labelText: 'Öncelik',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TaskPriority.low,
                          child: Text('Düşük'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.medium,
                          child: Text('Orta'),
                        ),
                        DropdownMenuItem(
                          value: TaskPriority.high,
                          child: Text('Yüksek'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setSheetState(() => priority = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty ||
                              selectedUserId == null) {
                            return;
                          }
                          await _taskService.createTask(
                            title: titleCtrl.text,
                            description: descCtrl.text,
                            assigneeId: selectedUserId!,
                            assigneeName: selectedUserName ?? '',
                            createdByName: widget.userName,
                            dueDate: dueDate,
                            priority: priority,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Görev Oluştur'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    descCtrl.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
