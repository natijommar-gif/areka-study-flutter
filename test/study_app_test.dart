import 'package:areka_learning/data/study_content.dart';
import 'package:areka_learning/state/app_store.dart';
import 'package:areka_learning/ui/app_theme.dart';
import 'package:areka_learning/ui/study_app.dart';
import 'package:areka_learning/ui/study_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudyContent content;

  setUpAll(() async {
    content = await StudyContent.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'offline curriculum bundle has the verified counts and 9 original subjects',
    () {
      expect(content.metadata['originalSubjectCount'], 9);
      expect(content.metadata['originalQuizCount'], 66);
      expect(content.metadata['originalQuestionCount'], 1776);
      expect(content.metadata['originalMultipleChoiceCount'], 1218);
      expect(content.metadata['originalFillInCount'], 558);
      expect(content.metadata['originalFlashcardCount'], 462);
      expect(content.metadata['additionalGeographyQuizCount'], 8);
      expect(content.metadata['additionalGeographyQuestionCount'], 48);
      expect(content.metadata['additionalGeographyFlashcardCount'], 64);
      expect(content.quizzes.length, 74);
      expect(content.questionCount, 1824);
      expect(content.flashcards.length, 526);
      expect(content.subjects.length, 9);
      expect(content.quizzes.map((quiz) => quiz.id).toSet().length, 74);
    },
  );

  test('cited Geography items preserve textbook section and printed-to-PDF page mapping', () {
    final geoQuestions = content.quizzes
        .where((quiz) => quiz.verifiedPacket)
        .expand((quiz) => quiz.questions)
        .toList();
    expect(geoQuestions.length, 48);
    expect(
      geoQuestions.every((question) => question.citation.isNotEmpty),
      isTrue,
    );
    for (final question in geoQuestions) {
      expect(question.pdfPages.length, question.printedPages.length);
      for (var i = 0; i < question.pdfPages.length; i++) {
        expect(question.pdfPages[i], question.printedPages[i] + 6);
      }
    }
    expect(content.metadata['geographyNote'].toString(), contains('RDI'));
  });

  testWidgets(
    'multiple-choice quiz checks the selected answer and records completion',
    (tester) async {
      final store = await AppStore.create(content: content);
      final quiz = content.quizzes.firstWhere(
        (item) =>
            !item.questions.first.isFillIn &&
            item.questions.first.options.isNotEmpty,
      );
      final question = quiz.questions.first;
      final correctOption = question.options.firstWhere(
        (item) => item.key.toLowerCase() == question.answerKey.toLowerCase(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(
            store: store,
            quiz: _singleQuestionQuiz(quiz, question),
          ),
        ),
      );
      expect(find.text(question.text), findsOneWidget);
      await tester.ensureVisible(find.text(correctOption.text));
      await tester.tap(find.text(correctOption.text));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Check answer'));
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();
      expect(find.text('Correct'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Finish quiz'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
      expect(store.quizzesCompleted, 1);
      expect(store.accuracy, 100);
    },
  );

  testWidgets(
    'fill-in quiz reveals its model answer and supports honest self-review',
    (tester) async {
      final store = await AppStore.create(content: content);
      StudyQuiz? sourceQuiz;
      StudyQuestion? question;
      for (final quiz in content.quizzes) {
        final found = quiz.questions.where((item) => item.isFillIn);
        if (found.isNotEmpty) {
          sourceQuiz = quiz;
          question = found.first;
          break;
        }
      }
      expect(sourceQuiz, isNotNull);
      expect(question, isNotNull);
      final quiz = _singleQuestionQuiz(sourceQuiz!, question!);

      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(store: store, quiz: quiz),
        ),
      );
      await tester.enterText(find.byType(TextField), 'My answer');
      await tester.ensureVisible(find.text('Show model answer'));
      await tester.tap(find.text('Show model answer'));
      await tester.pumpAndSettle();
      expect(find.text(question.correctAnswer), findsOneWidget);
      await tester.ensureVisible(find.text('I got it'));
      await tester.tap(find.text('I got it'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Finish quiz'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Finish quiz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish quiz'));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    },
  );

  testWidgets('flashcard reveals its back and saves the Got it rating', (
    tester,
  ) async {
    final store = await AppStore.create(content: content);
    final card = content.flashcards.first;
    await tester.pumpWidget(ArekaApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();

    expect(find.text(card.front), findsOneWidget);
    await tester.ensureVisible(find.text('Reveal answer'));
    await tester.tap(find.text('Reveal answer'));
    await tester.pumpAndSettle();
    expect(find.text(card.back), findsOneWidget);
    await tester.ensureVisible(find.text('Got it'));
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(store.cardsReviewed, 1);
    expect(store.masteredCards, contains(card.id));
  });

  testWidgets('marking a missed question reviewed updates the screen', (
    tester,
  ) async {
    final store = await AppStore.create(content: content);
    final quiz = content.quizzes.firstWhere(
      (item) =>
          !item.questions.first.isFillIn &&
          item.questions.first.options.isNotEmpty,
    );
    final question = quiz.questions.first;
    await store.recordQuiz(_singleQuestionQuiz(quiz, question), 0, [
      question.id,
    ]);

    await tester.pumpWidget(MaterialApp(home: MistakesScreen(store: store)));
    expect(find.text(question.text), findsOneWidget);
    await tester.tap(find.text('Mark reviewed'));
    await tester.pumpAndSettle();

    expect(find.text('You’re all caught up'), findsOneWidget);
    expect(find.text(question.text), findsNothing);
  });

  testWidgets('shuffling flashcards does not reorder bundled curriculum', (
    tester,
  ) async {
    final store = await AppStore.create(content: content);
    final originalOrder = content.flashcards.map((card) => card.id).toList();

    await tester.pumpWidget(ArekaApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Shuffle cards'));
    await tester.pumpAndSettle();

    expect(content.flashcards.map((card) => card.id).toList(), originalOrder);
  });

  testWidgets('dark-theme quiz feedback keeps normal text readable', (
    tester,
  ) async {
    final store = await AppStore.create(content: content);
    final quiz = content.quizzes.firstWhere(
      (item) =>
          !item.questions.first.isFillIn &&
          item.questions.first.options.isNotEmpty,
    );
    final question = quiz.questions.first;
    final correctOption = question.options.firstWhere(
      (item) => item.key.toLowerCase() == question.answerKey.toLowerCase(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: QuizScreen(
          store: store,
          quiz: _singleQuestionQuiz(quiz, question),
        ),
      ),
    );
    await tester.ensureVisible(find.text(correctOption.text));
    await tester.tap(find.text(correctOption.text));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Check answer'));
    await tester.tap(find.text('Check answer'));
    await tester.pumpAndSettle();

    final feedback = find.ancestor(
      of: find.text('Correct'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color != null,
      ),
    );
    expect(feedback, findsWidgets);
    final feedbackContainer = tester.widget<Container>(feedback.first);
    final background = (feedbackContainer.decoration! as BoxDecoration).color!;
    final answerFinder = find.descendant(
      of: feedback.first,
      matching: find.text(question.correctAnswer),
    );
    final answerStyle = tester.widget<Text>(answerFinder).style!;
    expect(
      _contrastRatio(answerStyle.color!, background),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets(
    'long flashcards remain usable on a narrow enlarged-text screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cards = [...content.flashcards]
        ..sort((a, b) {
          final aLength = a.front.length + a.back.length + a.explanation.length;
          final bLength = b.front.length + b.back.length + b.explanation.length;
          return bLength.compareTo(aLength);
        });
      final narrowContent = StudyContent(
        metadata: content.metadata,
        quizzes: content.quizzes,
        flashcards: cards,
      );
      final store = await AppStore.create(content: narrowContent);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              devicePixelRatio: 1,
              textScaler: TextScaler.linear(1.8),
            ),
            child: FlashcardsTab(store: store),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reveal answer'));
      await tester.tap(find.text('Reveal answer'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}

StudyQuiz _singleQuestionQuiz(StudyQuiz source, StudyQuestion question) =>
    StudyQuiz(
      id: '${source.id}_test',
      title: source.title,
      subject: source.subject,
      subjectId: source.subjectId,
      unitId: source.unitId,
      durationMinutes: 1,
      verifiedPacket: source.verifiedPacket,
      questions: [question],
    );

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
