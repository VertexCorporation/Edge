import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/card.dart';
import '../widgets/text.dart';

/// Tasks screen - main content (center tab)
/// Shows welcome card and task list with status badges
class TasksScreen extends StatefulWidget {
  final String userName;
  final String userRole;

  const TasksScreen({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Mock task data - will be replaced with Firestore
  final List<_Task> _tasks = [
    _Task(
      title: 'Cortex v2.0 Arayüz Güncellemesi',
      description: 'Yeni AI model entegrasyonu için arayüz güncellemelerini tamamla.',
      status: TaskStatus.inProgress,
      dueDate: '12 Ağustos 2026',
      priority: 'Yüksek',
    ),
    _Task(
      title: 'Solar Browser Performans Testi',
      description: 'WebAssembly modüllerinin render performansını test et ve raporla.',
      status: TaskStatus.todo,
      dueDate: '15 Ağustos 2026',
      priority: 'Orta',
    ),
    _Task(
      title: 'Mergen API Dokümantasyonu',
      description: 'RESTful API endpoint\'lerinin Swagger dokümantasyonunu hazırla.',
      status: TaskStatus.done,
      dueDate: '5 Ağustos 2026',
      priority: 'Orta',
    ),
    _Task(
      title: 'Haftalık Sprint Raporu',
      description: 'Bu haftaki geliştirme ilerlemesini ve blocker\'ları raporla.',
      status: TaskStatus.todo,
      dueDate: '9 Ağustos 2026',
      priority: 'Düşük',
    ),
    _Task(
      title: 'All Star Multiplayer Modülü',
      description: 'Gerçek zamanlı çok oyunculu mod için WebSocket altyapısını kur.',
      status: TaskStatus.inProgress,
      dueDate: '20 Ağustos 2026',
      priority: 'Yüksek',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ─── Header ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome card
                  _buildWelcomeCard(brightness, isDark),
                  const SizedBox(height: 28),

                  // Stats row
                  _buildStatsRow(brightness),
                  const SizedBox(height: 28),

                  // Section title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aktif Görevler',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? VertexColors.textMainDark
                              : VertexColors.textMainLight,
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
                          '${_tasks.length} görev',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: VertexColors.textMuted(brightness),
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
                    child: _buildTaskCard(_tasks[index], brightness, isDark),
                  );
                },
                childCount: _tasks.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(Brightness brightness, bool isDark) {
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
                          ? VertexColors.textMainDark
                          : VertexColors.textMainLight,
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
                        color: VertexColors.textMuted(brightness),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bugün ${_tasks.where((t) => t.status != TaskStatus.done).length} tamamlanmamış görevin var.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: VertexColors.textMuted(brightness),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Brightness brightness) {
    final todo = _tasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgress =
        _tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final done = _tasks.where((t) => t.status == TaskStatus.done).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Yapılacak',
            value: '$todo',
            color: VertexColors.statusTodo,
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Devam Eden',
            value: '$inProgress',
            color: VertexColors.statusInProgress,
            brightness: brightness,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            label: 'Tamamlanan',
            value: '$done',
            color: VertexColors.statusDone,
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
        color: VertexColors.glassBg(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VertexColors.glassBorder(brightness)),
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
              color: VertexColors.textMuted(brightness),
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
                        ? VertexColors.textMainDark
                        : VertexColors.textMainLight,
                    decoration: task.status == TaskStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: VertexColors.textMuted(brightness),
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
              color: VertexColors.textMuted(brightness),
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
                      task.statusLabel,
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
                    color: VertexColors.textMuted(brightness),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.dueDate,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: VertexColors.textMuted(brightness),
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
        return VertexColors.error;
      case 'Orta':
        return VertexColors.warning;
      case 'Düşük':
        return VertexColors.info;
      default:
        return VertexColors.statusTodo;
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
        return VertexColors.statusTodo;
      case TaskStatus.inProgress:
        return VertexColors.statusInProgress;
      case TaskStatus.done:
        return VertexColors.statusDone;
    }
  }

  String get statusLabel {
    switch (status) {
      case TaskStatus.todo:
        return 'Yapılacak';
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.done:
        return 'Tamamlandı';
    }
  }
}
