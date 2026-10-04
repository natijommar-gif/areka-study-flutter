import 'dart:convert';

import 'package:flutter/services.dart';

class StudyContent {
  StudyContent({
    required this.metadata,
    required this.quizzes,
    required this.flashcards,
  });

  final Map<String, dynamic> metadata;
  final List<StudyQuiz> quizzes;
  final List<StudyFlashcard> flashcards;

  static Future<StudyContent> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(
      'assets/data/curriculum.json',
    );
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return StudyContent(
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      quizzes: (json['quizzes'] as List)
          .map(
            (item) =>
                StudyQuiz.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      flashcards: (json['flashcards'] as List)
          .map(
            (item) =>
                StudyFlashcard.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
    );
  }

  List<String> get subjects =>
      quizzes.map((quiz) => quiz.subject).toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  List<StudyQuiz> quizzesFor(String subject) =>
      quizzes.where((quiz) => quiz.subject == subject).toList(growable: false);

  List<StudyFlashcard> cardsForUnit(String unitId) =>
      flashcards.where((card) => card.unitId == unitId).toList(growable: false);

  List<StudyFlashcard> cardsForSubject(String subjectId) => flashcards
      .where((card) => card.subjectId == subjectId)
      .toList(growable: false);

  int get questionCount =>
      quizzes.fold(0, (sum, quiz) => sum + quiz.questions.length);
}

class StudyQuiz {
  StudyQuiz({
    required this.id,
    required this.title,
    required this.subject,
    required this.subjectId,
    required this.unitId,
    required this.durationMinutes,
    required this.questions,
    this.verifiedPacket = false,
  });

  final String id;
  final String title;
  final String subject;
  final String subjectId;
  final String unitId;
  final int durationMinutes;
  final List<StudyQuestion> questions;
  final bool verifiedPacket;

  factory StudyQuiz.fromJson(Map<String, dynamic> json) => StudyQuiz(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Study set',
    subject: json['subject'] as String? ?? 'General',
    subjectId: json['subjectId'] as String? ?? 'general',
    unitId: json['unitId'] as String? ?? '',
    durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 10,
    verifiedPacket: json['verifiedPacket'] as bool? ?? false,
    questions: (json['questions'] as List? ?? const [])
        .map(
          (item) =>
              StudyQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );
}

class StudyQuestion {
  StudyQuestion({
    required this.id,
    required this.number,
    required this.text,
    required this.options,
    required this.answerKey,
    required this.explanation,
    required this.type,
    this.answerText = '',
    this.section,
    this.sectionTitle,
    this.printedPages = const [],
    this.pdfPages = const [],
    this.sourceTitle,
    this.sourcePublisher,
    this.sourceYear,
    this.sourceSha256,
    this.printedToPdfOffset,
  });

  final String id;
  final int number;
  final String text;
  final List<StudyOption> options;
  final String answerKey;
  final String answerText;
  final String explanation;
  final String type;
  final String? section;
  final String? sectionTitle;
  final List<int> printedPages;
  final List<int> pdfPages;
  final String? sourceTitle;
  final String? sourcePublisher;
  final int? sourceYear;
  final String? sourceSha256;
  final int? printedToPdfOffset;

  bool get isFillIn => type == 'fill_in';

  String get correctAnswer {
    if (answerText.isNotEmpty) return answerText;
    for (final option in options) {
      if (option.key.toLowerCase() == answerKey.toLowerCase()) {
        return option.text;
      }
    }
    return answerKey;
  }

  String get citation {
    if (printedPages.isEmpty) return '';
    final sectionLabel = [
      if (section != null) section,
      if (sectionTitle != null) sectionTitle,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    final pageLabels = <String>[];
    for (var i = 0; i < printedPages.length; i++) {
      final pdfPage = i < pdfPages.length ? pdfPages[i] : null;
      pageLabels.add(
        pdfPage == null
            ? 'p. ${printedPages[i]}'
            : 'p. ${printedPages[i]} (PDF p. $pdfPage)',
      );
    }
    final source = sourceTitle == null
        ? ''
        : ' · $sourceTitle${sourceYear == null ? '' : ' ($sourceYear)'}';
    return '${sectionLabel.isEmpty ? '' : '$sectionLabel · '}${pageLabels.join(', ')}$source';
  }

  factory StudyQuestion.fromJson(Map<String, dynamic> json) => StudyQuestion(
    id: json['id'].toString(),
    number: (json['number'] as num?)?.toInt() ?? 1,
    text: json['text'] as String? ?? '',
    options: (json['options'] as List? ?? const [])
        .map(
          (item) =>
              StudyOption.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
    answerKey: json['answerKey'] as String? ?? '',
    answerText: json['answerText'] as String? ?? '',
    explanation: json['explanation'] as String? ?? '',
    type: json['type'] as String? ?? 'multiple_choice',
    section: json['section'] as String?,
    sectionTitle: json['sectionTitle'] as String?,
    printedPages: _intList(json['printedPages']),
    pdfPages: _intList(json['pdfPages']),
    sourceTitle: json['sourceTitle'] as String?,
    sourcePublisher: json['sourcePublisher'] as String?,
    sourceYear: (json['sourceYear'] as num?)?.toInt(),
    sourceSha256: json['sourceSha256'] as String?,
    printedToPdfOffset: (json['printedToPdfOffset'] as num?)?.toInt(),
  );
}

class StudyOption {
  const StudyOption({required this.key, required this.text});
  final String key;
  final String text;

  factory StudyOption.fromJson(Map<String, dynamic> json) => StudyOption(
    key: json['key'] as String? ?? '',
    text: json['text'] as String? ?? '',
  );
}

class StudyFlashcard {
  StudyFlashcard({
    required this.id,
    required this.subjectId,
    required this.unitId,
    required this.front,
    required this.back,
    this.explanation = '',
    this.unitTitle = '',
    this.section,
    this.sectionTitle,
    this.printedPages = const [],
    this.pdfPages = const [],
    this.sourceTitle,
    this.sourceYear,
  });

  final String id;
  final String subjectId;
  final String unitId;
  final String front;
  final String back;
  final String explanation;
  final String unitTitle;
  final String? section;
  final String? sectionTitle;
  final List<int> printedPages;
  final List<int> pdfPages;
  final String? sourceTitle;
  final int? sourceYear;

  String get citation {
    if (printedPages.isEmpty) return '';
    final sectionLabel = [
      if (section != null) section,
      if (sectionTitle != null) sectionTitle,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    final pages = <String>[];
    for (var i = 0; i < printedPages.length; i++) {
      pages.add(
        i < pdfPages.length
            ? 'p. ${printedPages[i]} (PDF p. ${pdfPages[i]})'
            : 'p. ${printedPages[i]}',
      );
    }
    final source = sourceTitle == null
        ? ''
        : ' · $sourceTitle${sourceYear == null ? '' : ' ($sourceYear)'}';
    return '${sectionLabel.isEmpty ? '' : '$sectionLabel · '}${pages.join(', ')}$source';
  }

  factory StudyFlashcard.fromJson(Map<String, dynamic> json) => StudyFlashcard(
    id: json['id'].toString(),
    subjectId: json['subjectId'] as String? ?? 'general',
    unitId: json['unitId'] as String? ?? '',
    front: json['front'] as String? ?? '',
    back: json['back'] as String? ?? '',
    explanation: json['explanation'] as String? ?? '',
    unitTitle: json['unitTitle'] as String? ?? '',
    section: json['section'] as String?,
    sectionTitle: json['sectionTitle'] as String?,
    printedPages: _intList(json['printedPages']),
    pdfPages: _intList(json['pdfPages']),
    sourceTitle: json['sourceTitle'] as String?,
    sourceYear: (json['sourceYear'] as num?)?.toInt(),
  );
}

List<int> _intList(dynamic value) => (value as List? ?? const [])
    .map((item) => (item as num).toInt())
    .toList(growable: false);
