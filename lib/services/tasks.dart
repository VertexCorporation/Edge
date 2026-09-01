import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
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

  factory VertexTask.fromJson(Map<String, dynamic> json) {
    return VertexTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      assigneeId: json['assigneeId'] as String? ?? '',
      assigneeName: json['assigneeName'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      createdByName: json['createdByName'] as String? ?? '',
      status: _statusFromString(json['status'] as String?),
      priority: _priorityFromString(json['priority'] as String?),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'status': statusToString(status),
      'priority': priorityToString(priority),
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
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

  String get _uid => _auth.currentUser?.uid ?? 'dummy_user';

  static final _taskController = StreamController<List<VertexTask>>.broadcast();
  static const _localTasksKey = 'local_tasks_cache';
  
  Future<void> _loadLocalTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_localTasksKey);
    List<VertexTask> tasks = [];
    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        tasks = list.map((e) => VertexTask.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Failed to load local tasks: $e');
      }
    }
    _taskController.add(tasks);
  }

  Future<void> _saveLocalTasks(List<VertexTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final list = tasks.map((e) => e.toJson()).toList();
    await prefs.setString(_localTasksKey, jsonEncode(list));
    _taskController.add(tasks);
  }
  
  Future<List<VertexTask>> _getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_localTasksKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        return list.map((e) => VertexTask.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    return [];
  }

  Stream<List<VertexTask>> watchTasks({required bool isAdmin}) {
    _loadLocalTasks();
    return _taskController.stream.map((tasks) {
      var filtered = isAdmin ? tasks : tasks.where((t) => t.assigneeId == _uid).toList();
      filtered.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      return filtered;
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
    final tasks = await _getTasks();
    final newTask = VertexTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description.trim(),
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      createdBy: _uid,
      createdByName: createdByName,
      status: TaskStatus.todo,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    tasks.add(newTask);
    await _saveLocalTasks(tasks);
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await _getTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await _saveLocalTasks(tasks);
  }

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    final tasks = await _getTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final old = tasks[index];
      tasks[index] = VertexTask(
        id: old.id,
        title: old.title,
        description: old.description,
        assigneeId: old.assigneeId,
        assigneeName: old.assigneeName,
        createdBy: old.createdBy,
        createdByName: old.createdByName,
        status: status,
        priority: old.priority,
        dueDate: old.dueDate,
        createdAt: old.createdAt,
      );
      await _saveLocalTasks(tasks);
    }
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
