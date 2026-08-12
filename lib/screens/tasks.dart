import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/card.dart';
import '../widgets/text.dart';
import '../widgets/fog.dart';
import 'package:edge/l10n/app_localizations.dart';

/// Tasks screen - main content (center tab)
/// Shows welcome card and task list with status badges
class TasksScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final bool isEmbedded;

  const TasksScreen({
    super.key,
    required this.userName,
    required this.userRole,
    this.isEmbedded = false,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Mock task data - will be replaced with Firestore
  List<_Task> _getTasks(BuildContext context) {
    return [
      _Task(
        title: AppLocalizations.of(context)!.mockTask1Title,
        description: AppLocalizations.of(context)!.mockTask1Desc,
        status: TaskStatus.inProgress,
        dueDate: AppLocalizations.of(context)!.august12,
        priority: AppLocalizations.of(context)!.priorityHigh,
      ),
      _Task(
        title: AppLocalizations.of(context)!.mockTask2Title,
        description: AppLocalizations.of(context)!.mockTask2Desc,
        status: TaskStatus.todo,
        dueDate: AppLocalizations.of(context)!.august15,
        priority: AppLocalizations.of(context)!.priorityMedium,
      ),
      _Task(
        title: AppLocalizations.of(context)!.mockTask3Title,
        description: AppLocalizations.of(context)!.mockTask3Desc,
        status: TaskStatus.done,
        dueDate: AppLocalizations.of(context)!.august5,
        priority: AppLocalizations.of(context)!.priorityMedium,
      ),
      _Task(
        title: AppLocalizations.of(context)!.mockTask4Title,
        description: AppLocalizations.of(context)!.mockTask4Desc,
        status: TaskStatus.todo,
        dueDate: AppLocalizations.of(context)!.august9,
        priority: AppLocalizations.of(context)!.priorityLow,
      ),
      _Task(
        title: AppLocalizations.of(context)!.mockTask5Title,
        description: AppLocalizations.of(context)!.mockTask5Desc,
        status: TaskStatus.inProgress,
        dueDate: AppLocalizations.of(context)!.august20,
        priority: AppLocalizations.of(context)!.priorityHigh,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final tasks = _getTasks(context);

    final content = ScrollFog(
      scrollController: _scrollController,
      color: AppColors.background,
      child: CustomScrollView(
        controller: _scrollController,
        shrinkWrap: widget.isEmbedded,
        physics: widget.isEmbedded ? const NeverScrollableScrollPhysics() : null,
        slivers: [
          // ─── Header ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome card
                  _buildWelcomeCard(brightness, isDark, tasks),
                  const SizedBox(height: 28),

                  // Stats row
                  _buildStatsRow(brightness, tasks),
                  const SizedBox(height: 28),

                  // Section title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.activeTasks,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.primaryColor.inverted
                              : AppColors.primaryColor.inverted,
                        ),
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
                          AppLocalizations.of(context)!.taskCount(tasks.length),
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

          // ─── Task List ───
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTaskCard(tasks[index], brightness, isDark),
                  );
                },
                childCount: tasks.length,
              ),
            ),
          ),
        ],
      ),
    );

    return widget.isEmbedded ? content : SafeArea(child: content);
  }

  Widget _buildWelcomeCard(Brightness brightness, bool isDark, List<_Task> tasks) {
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
                      color: isDark
                          ? AppColors.primaryColor.inverted
                          : AppColors.primaryColor.inverted,
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
            AppLocalizations.of(context)!.uncompletedTasksToday(tasks.where((t) => t.status != TaskStatus.done).length),
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

  Widget _buildStatsRow(Brightness brightness, List<_Task> tasks) {
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
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: AppLocalizations.of(context)!.inProgress,
            value: '$inProgress',
            color: Colors.blue,
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: AppLocalizations.of(context)!.completed,
            value: '$done',
            color: Colors.green,
            brightness: brightness,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
    required Brightness brightness,
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

  Widget _buildTaskCard(_Task task, Brightness brightness, bool isDark) {
    return VertexCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: task.statusColor.withValues(alpha: 0.4),
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
                    color: isDark
                        ? AppColors.primaryColor.inverted
                        : AppColors.primaryColor.inverted,
                    decoration: task.status == TaskStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppColors.tertiaryColor,
                  ),
                ),
              ),
              // Priority badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priority,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(task.priority),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.tertiaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: task.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: task.statusColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.getStatusLabel(context),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: task.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Due date
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.tertiaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.dueDate,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Yüksek':
        return AppColors.septenaryColor;
      case 'Orta':
        return Colors.orange;
      case 'Düşük':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// ─── Data Models ───

enum TaskStatus { todo, inProgress, done }

class _Task {
  final String title;
  final String description;
  final TaskStatus status;
  final String dueDate;
  final String priority;

  const _Task({
    required this.title,
    required this.description,
    required this.status,
    required this.dueDate,
    required this.priority,
  });

  Color get statusColor {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  String getStatusLabel(BuildContext context) {
    switch (status) {
      case TaskStatus.todo:
        return AppLocalizations.of(context)!.todo;
      case TaskStatus.inProgress:
        return AppLocalizations.of(context)!.statusInProgress;
      case TaskStatus.done:
        return AppLocalizations.of(context)!.statusDone;
    }
  }
}
