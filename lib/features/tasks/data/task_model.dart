import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum Priority {
  low,
  medium,
  high,
  none;

  String get label {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.none:
        return 'None';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return const Color(0xFF4CAF50);
      case Priority.medium:
        return const Color(0xFFFFB74D);
      case Priority.high:
        return const Color(0xFFEF5350);
      case Priority.none:
        return const Color(0xFF90A4AE);
    }
  }

  static Priority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        return Priority.none;
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime? dueDate;
  final Priority priority;
  final bool isCompleted;
  final DateTime? completedAt; // ✅ เพิ่ม
  final int? focusTimeSpent; // ✅ เวลา Focus ที่ใช้ (นาที)

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.dueDate,
    this.priority = Priority.none,
    this.isCompleted = false,
    this.completedAt,
    this.focusTimeSpent,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? dueDate,
    Priority? priority,
    bool? isCompleted,
    DateTime? completedAt,
    int? focusTimeSpent,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      focusTimeSpent: focusTimeSpent ?? this.focusTimeSpent,
    );
  }

  // ✅ Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority.label,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'focusTimeSpent': focusTimeSpent,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ✅ Convert from Firestore
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Work',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      priority: Priority.fromString(data['priority']),
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      focusTimeSpent: data['focusTimeSpent'],
    );
  }
}