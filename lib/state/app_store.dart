import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/study_content.dart';

class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.correct,
    required this.total,
    required this.completedAt,
  });

  final String quizId;
  final int correct;
  final int total;
  final DateTime completedAt;
  int get percent => total == 0 ? 0 : (100 * correct / total).round();

  Map<String, dynamic> toJson() => {
    'quizId': quizId,
    'correct': correct,
    'total': total,
    'completedAt': completedAt.toIso8601String(),
  };

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
    quizId: json['quizId'] as String? ?? '',
    correct: (json['correct'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    completedAt:
        DateTime.tryParse(json['completedAt'] as String? ?? '') ??
        DateTime(2000),
  );
}

class AppStore extends ChangeNotifier {
  AppStore._(this.content, this._preferences) {
    _profileName = _preferences.getString('profileName') ?? 'Learner';
    _darkMode = _preferences.getBool('darkMode') ?? false;
    final attemptsRaw = _preferences.getString('quizAttempts');
    if (attemptsRaw != null) {
      try {
        _attempts = (jsonDecode(attemptsRaw) as List)
            .map(
              (item) =>
                  QuizAttempt.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } catch (_) {
        _attempts = [];
      }
    }
    _mistakes = (_preferences.getStringList('mistakes') ?? []).toSet();
    _reviewedCards = (_preferences.getStringList('reviewedCards') ?? [])
        .toSet();
    _masteredCards = (_preferences.getStringList('masteredCards') ?? [])
        .toSet();
  }

  final StudyContent content;
  final SharedPreferences _preferences;
  late String _profileName;
  late bool _darkMode;
  List<QuizAttempt> _attempts = [];
  Set<String> _mistakes = {};
  Set<String> _reviewedCards = {};
  Set<String> _masteredCards = {};

  static Future<AppStore> create({StudyContent? content}) async {
    final studyContent = content ?? await StudyContent.load();
    final preferences = await SharedPreferences.getInstance();
    return AppStore._(studyContent, preferences);
  }

  String get profileName => _profileName;
  bool get darkMode => _darkMode;
  List<QuizAttempt> get attempts => List.unmodifiable(_attempts);
  Set<String> get mistakes => Set.unmodifiable(_mistakes);
  Set<String> get reviewedCards => Set.unmodifiable(_reviewedCards);
  Set<String> get masteredCards => Set.unmodifiable(_masteredCards);
  int get quizzesCompleted => _attempts.length;
  int get questionsAnswered => _attempts.fold(0, (sum, a) => sum + a.total);
  int get totalCorrect => _attempts.fold(0, (sum, a) => sum + a.correct);
  int get accuracy => questionsAnswered == 0
      ? 0
      : (100 * totalCorrect / questionsAnswered).round();
  int get cardsReviewed => _reviewedCards.length;
  int get points =>
      _attempts.fold(0, (sum, a) => sum + a.correct * 10) +
      _reviewedCards.length * 2;

  Future<void> updateName(String name) async {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return;
    _profileName = cleaned;
    await _preferences.setString('profileName', cleaned);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _preferences.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> recordQuiz(
    StudyQuiz quiz,
    int correct,
    Iterable<String> missedIds,
  ) async {
    _attempts.add(
      QuizAttempt(
        quizId: quiz.id,
        correct: correct,
        total: quiz.questions.length,
        completedAt: DateTime.now(),
      ),
    );
    _mistakes.addAll(missedIds);
    await _saveAttempts();
    await _preferences.setStringList('mistakes', _mistakes.toList());
    notifyListeners();
  }

  Future<void> rateFlashcard(String cardId, {required bool knewIt}) async {
    _reviewedCards.add(cardId);
    if (knewIt) {
      _masteredCards.add(cardId);
    } else {
      _masteredCards.remove(cardId);
    }
    await _preferences.setStringList('reviewedCards', _reviewedCards.toList());
    await _preferences.setStringList('masteredCards', _masteredCards.toList());
    notifyListeners();
  }

  Future<void> clearMistake(String questionId) async {
    _mistakes.remove(questionId);
    await _preferences.setStringList('mistakes', _mistakes.toList());
    notifyListeners();
  }

  StudyQuestion? questionById(String id) {
    for (final quiz in content.quizzes) {
      for (final question in quiz.questions) {
        if (question.id == id) return question;
      }
    }
    return null;
  }

  StudyQuiz? quizById(String id) {
    for (final quiz in content.quizzes) {
      if (quiz.id == id) return quiz;
    }
    return null;
  }

  Future<void> _saveAttempts() async => _preferences.setString(
    'quizAttempts',
    jsonEncode(_attempts.map((attempt) => attempt.toJson()).toList()),
  );
}
