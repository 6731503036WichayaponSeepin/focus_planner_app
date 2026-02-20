import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

abstract class TaskRepository {
  // Active Tasks (ยังไม่เสร็จ)
  Future<List<TaskModel>> getAllActiveTasks();
  Future<List<TaskModel>> getTasksByCategory(String category);
  Future<List<TaskModel>> getTasksByPriority(Priority priority);
  Future<List<TaskModel>> getPendingTasks();

  // CRUD
  Future<TaskModel?> getTaskById(String id);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);

  // Completed Tasks (เสร็จแล้ว)
  Future<List<TaskModel>> getCompletedTasks();
  Future<void> completeTask(TaskModel task, int focusTimeSpent);

  // Stats
  Future<int> getTotalTasksCount();
  Future<int> getCompletedTasksCount();
  Future<int> getPendingTasksCount();
  Future<Map<String, int>> getTasksCountByCategory();
  Future<int> getTotalFocusTimeSpent();

}

class TaskRepositoryImpl implements TaskRepository {
  static final TaskRepositoryImpl _instance = TaskRepositoryImpl._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;

  factory TaskRepositoryImpl({String? userId}) {
    if (userId != null) {
      _instance._userId = userId;
    }
    return _instance;
  }

  TaskRepositoryImpl._internal();

  void setUserId(String userId) {
    _userId = userId;
  }

  String get _activeTasks => 'users/$_userId/tasks';
  String get _completedTasks => 'users/$_userId/completedTasks';

  // ✅ Get All Active Tasks (ไม่รวม Completed)
  @override
  Future<List<TaskModel>> getAllActiveTasks() async {
    try {
      final snapshot = await _firestore
          .collection(_activeTasks)
          .where('isCompleted', isEqualTo: false)
          .get();
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting tasks: $e');
    }
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    try {
      final doc = await _firestore
          .collection(_activeTasks)
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return TaskModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error getting task: $e');
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    try {
      await _firestore
          .collection(_activeTasks)
          .doc(task.id)
          .set(task.toFirestore());
    } catch (e) {
      throw Exception('Error adding task: $e');
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore
          .collection(_activeTasks)
          .doc(task.id)
          .update(task.toFirestore());
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _firestore
          .collection(_activeTasks)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  @override
  Future<List<TaskModel>> getTasksByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_activeTasks)
          .where('category', isEqualTo: category)
          .where('isCompleted', isEqualTo: false)
          .get();
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting tasks: $e');
    }
  }

  @override
  Future<List<TaskModel>> getTasksByPriority(Priority priority) async {
    try {
      final snapshot = await _firestore
          .collection(_activeTasks)
          .where('priority', isEqualTo: priority.label)
          .where('isCompleted', isEqualTo: false)
          .get();
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting tasks: $e');
    }
  }

  @override
  Future<List<TaskModel>> getPendingTasks() async {
    try {
      final snapshot = await _firestore
          .collection(_activeTasks)
          .where('isCompleted', isEqualTo: false)
          .get();
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting tasks: $e');
    }
  }

  // ✅ Complete Task - Move to Completed Collection
  @override
  Future<void> completeTask(TaskModel task, int focusTimeSpent) async {
    try {
      final completedTask = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        focusTimeSpent: focusTimeSpent,
      );

      // Save to completedTasks collection
      await _firestore
          .collection(_completedTasks)
          .doc(task.id)
          .set(completedTask.toFirestore());

      // Delete from activeTasks
      await _firestore
          .collection(_activeTasks)
          .doc(task.id)
          .delete();
    } catch (e) {
      throw Exception('Error completing task: $e');
    }
  }

  // ✅ Get Completed Tasks
  @override
  Future<List<TaskModel>> getCompletedTasks() async {
    try {
      final snapshot = await _firestore
          .collection(_completedTasks)
          .orderBy('completedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting completed tasks: $e');
    }
  }

  @override
  Future<int> getTotalTasksCount() async {
    try {
      final snapshot = await _firestore
          .collection(_activeTasks)
          .where('isCompleted', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getCompletedTasksCount() async {
    try {
      final snapshot = await _firestore
          .collection(_completedTasks)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getPendingTasksCount() async {
    try {
      final snapshot = await _firestore
          .collection(_activeTasks)
          .where('isCompleted', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<Map<String, int>> getTasksCountByCategory() async {
    try {
      final snapshot = await _firestore
          .collection(_activeTasks)
          .where('isCompleted', isEqualTo: false)
          .get();
      final Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        final task = TaskModel.fromFirestore(doc);
        counts[task.category] = (counts[task.category] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      return {};
    }
  }

  // ✅ Get Total Focus Time Spent
  @override
  Future<int> getTotalFocusTimeSpent() async {
    try {
      final snapshot = await _firestore
          .collection(_completedTasks)
          .get();
      int totalMinutes = 0;
      for (var doc in snapshot.docs) {
        final task = TaskModel.fromFirestore(doc);
        totalMinutes += task.focusTimeSpent ?? 0;
      }
      return totalMinutes;
    } catch (e) {
      return 0;
    }
  }
}