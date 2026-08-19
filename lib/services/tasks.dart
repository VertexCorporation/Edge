import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/role.dart';
import 'cortex_profile.dart';

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, medium, high }

class VertexTask {
  final String id;
  final String title;
  final String description;
  final String assigneeId;
  final String assigneeName;
  final String createdBy;
  final String createdByName;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? createdAt;

  const VertexTask({
    required this.id,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.assigneeName,
    required this.createdBy,
    required this.createdByName,
    required this.status,
    required this.priority,
    this.dueDate,
    this.createdAt,
  });

  factory VertexTask.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VertexTask(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      assigneeId: data['assigneeId'] as String? ?? '',
      assigneeName: data['assigneeName'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      status: _statusFromString(data['status'] as String?),
      priority: _priorityFromString(data['priority'] as String?),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  int? get daysRemaining {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final end = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final start = DateTime(now.year, now.month, now.day);
    return end.difference(start).inDays;
  }

  static TaskStatus _statusFromString(String? value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  static TaskPriority _priorityFromString(String? value) {
    switch (value) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  static String statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.todo:
        return 'todo';
    }
  }

  static String priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'high';
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
    }
  }
}

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Tasks assigned to the current user, or all tasks if admin.
  Stream<List<VertexTask>> watchTasks({required bool isAdmin}) {
    Query<Map<String, dynamic>> query = _firestore.collection('tasks');
    if (!isAdmin) {
      query = query.where('assigneeId', isEqualTo: _uid);
    }
    return query.snapshots().map((snap) {
      final tasks = snap.docs.map(VertexTask.fromDoc).toList();
      tasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      return tasks;
    });
  }

  Future<void> createTask({
    required String title,
    required String description,
    required String assigneeId,
    required String assigneeName,
    required String createdByName,
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    await _firestore.collection('tasks').add({
      'title': title.trim(),
      'description': description.trim(),
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'createdBy': _uid,
      'createdByName': createdByName,
      'status': VertexTask.statusToString(TaskStatus.todo),
      'priority': VertexTask.priorityToString(priority),
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': VertexTask.statusToString(status),
    });
  }

  List<Map<String, dynamic>>? _assigneesCache;
  DateTime? _assigneesCachedAt;
  static const _assigneesCacheTtl = Duration(minutes: 5);

  Future<List<Map<String, dynamic>>> listAssignees({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _assigneesCache != null &&
        _assigneesCachedAt != null &&
        _assigneesCache!.isNotEmpty &&
        DateTime.now().difference(_assigneesCachedAt!) < _assigneesCacheTtl) {
      return _assigneesCache!;
    }

    final currentUid = _auth.currentUser?.uid;
    final byUid = <String, Map<String, dynamic>>{};

    try {
      final snap = await _firestore.collection('users').get();
      for (final doc in snap.docs) {
        if (doc.id == currentUid) continue;
        final data = doc.data();
        if (!CortexProfile.isTaskAssignable(data)) continue;
        byUid[doc.id] = {
          'userId': doc.id,
          'name': CortexProfile.displayName(
            data,
            fallback: data['email'] as String? ?? doc.id,
          ),
          'role': UserRole.normalize(data['role'] as String?),
        };
      }
    } catch (e) {
      debugPrint('TaskService: users list failed: $e');
    }

    try {
      final snap = await _firestore.collection('usernames').get();
      for (final mapped in _mapAssigneeDocs(snap.docs, currentUid)) {
        byUid.putIfAbsent(
          mapped['userId'] as String,
          () => mapped,
        );
      }
    } catch (e) {
      debugPrint('TaskService: usernames list failed: $e');
    }

    final assignees = byUid.values.toList()
      ..sort(
        (a, b) => (a['name'] as String)
            .toLowerCase()
            .compareTo((b['name'] as String).toLowerCase()),
      );

    if (assignees.isNotEmpty) {
      _assigneesCache = assignees;
      _assigneesCachedAt = DateTime.now();
    }
    return assignees;
  }

  List<Map<String, dynamic>> _mapAssigneeDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String? currentUid,
  ) {
    return docs
        .map((doc) {
          final data = doc.data();
          final userId = data['userId'] as String? ?? '';
          if (userId.isEmpty || userId == currentUid) return null;
          if (!CortexProfile.isTaskAssignable(data)) return null;
          return {
            'userId': userId,
            'name': CortexProfile.displayName(data, fallback: doc.id),
            'role': UserRole.normalize(data['role'] as String?),
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
