import 'package:flutter/material.dart';

import '../data/study_content.dart';
import '../state/app_store.dart';

Future<void> openQuiz(BuildContext context, AppStore store, StudyQuiz quiz) =>
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(store: store, quiz: quiz),
      ),
    );

class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key, required this.store, required this.subject});
  final AppStore store;
  final String subject;

  @override
  Widget build(BuildContext context) {
    final units = store.content.quizzesFor(subject);
    final verified = units.where((quiz) => quiz.verifiedPacket).toList();
    final regular = units.where((quiz) => !quiz.verifiedPacket).toList();
    final count = units.fold<int>(
      0,
      (sum, quiz) => sum + quiz.questions.length,
    );
    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            '${units.length} study units · $count practice questions',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (verified.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _VerifiedBanner(),
          ],
          if (regular.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Curriculum units',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...regular.map((quiz) => _UnitTile(store: store, quiz: quiz)),
          ],
          if (verified.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Verified textbook packet',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Eight source-reviewed units with printed-page and PDF-page citations.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            ...verified.map((quiz) => _UnitTile(store: store, quiz: quiz)),
          ],
        ],
      ),
    );
  }
}

class UnitScreen extends StatelessWidget {
  const UnitScreen({super.key, required this.store, required this.quiz});
  final AppStore store;
  final StudyQuiz quiz;

  @override
  Widget build(BuildContext context) {
    final cards = store.content.cardsForUnit(quiz.unitId);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(quiz.subject)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.78),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quiz.verifiedPacket) ...[
                  const _VerifiedTag(),
                  const SizedBox(height: 12),
                ],
                Text(
                  quiz.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${quiz.questions.length} practice questions · ${cards.length} flashcards · works offline',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (quiz.verifiedPacket && quiz.unitId == 'geo_verified_u5') ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1D8),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF754500)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Source note: the Unit 5 RDI category definition on printed p. 141 differs from country labels on p. 142. The discrepancy is preserved in the relevant answer explanation.',
                      style: TextStyle(color: Color(0xFF4E3300), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            'Choose how to study',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.menu_book_outlined,
            title: 'Read the study guide',
            subtitle: 'Key ideas, model answers, and explanations',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudyGuideScreen(store: store, quiz: quiz),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.quiz_outlined,
            title: 'Practice all ${quiz.questions.length} questions',
            subtitle: 'Instant feedback and saved review items',
            primary: true,
            onTap: () => openQuiz(context, store, quiz),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.style_outlined,
            title: 'Review ${cards.length} flashcards',
            subtitle: 'Reveal answers and rate your recall',
            onTap: cards.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlashcardDeckScreen(
                        store: store,
                        cards: cards,
                        title: quiz.subject,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          if (quiz.verifiedPacket)
            const Text(
              'Citations show printed textbook pages and the matching physical PDF pages. The textbook remains the authority for source-specific wording.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
        ],
      ),
    );
  }
}

class StudyGuideScreen extends StatelessWidget {
  const StudyGuideScreen({super.key, required this.store, required this.quiz});
  final AppStore store;
  final StudyQuiz quiz;

  @override
  Widget build(BuildContext context) {
    final cards = store.content.cardsForUnit(quiz.unitId);
    return Scaffold(
      appBar: AppBar(title: const Text('Study guide')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        children: [
          Text(
            quiz.title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Study offline: ${cards.length} flashcards and ${quiz.questions.length} question explanations.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Key ideas',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...cards.map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.front,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.back,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(height: 1.48),
                        ),
                        if (card.explanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            card.explanation,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(height: 1.45),
                          ),
                        ],
                        if (card.citation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _SourceCitation(text: card.citation),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Check your understanding',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...quiz.questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.text,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Answer: ${question.correctAnswer}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      if (question.explanation.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          question.explanation,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(height: 1.45),
                        ),
                      ],
                      if (question.citation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SourceCitation(text: question.citation),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => openQuiz(context, store, quiz),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start the full quiz'),
          ),
        ],
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.store, required this.quiz});
  final AppStore store;
  final StudyQuiz quiz;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _correct = 0;
  String? _selectedKey;
  bool _answered = false;
  bool _fillRevealed = false;
  bool _finished = false;
  bool _saving = false;
  final Set<String> _missedIds = {};
  final TextEditingController _responseController = TextEditingController();

  StudyQuestion get _question => widget.quiz.questions[_index];

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _checkChoice() {
    if (_selectedKey == null || _answered) return;
    _record(_selectedKey!.toLowerCase() == _question.answerKey.toLowerCase());
  }

  void _record(bool correct) {
    if (_answered) return;
    setState(() {
      _answered = true;
      if (correct) {
        _correct++;
      } else {
        _missedIds.add(_question.id);
      }
    });
  }

  Future<void> _next() async {
    if (_index + 1 < widget.quiz.questions.length) {
      setState(() {
        _index++;
        _selectedKey = null;
        _answered = false;
        _fillRevealed = false;
        _responseController.clear();
      });
      return;
    }
    setState(() => _saving = true);
    await widget.store.recordQuiz(widget.quiz, _correct, _missedIds);
    if (mounted) {
      setState(() {
        _saving = false;
        _finished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_finished ? 'Quiz complete' : widget.quiz.subject),
    ),
    body: _finished ? _result(context) : _questionBody(context),
  );

  Widget _questionBody(BuildContext context) {
    final question = _question;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_index + 1} of ${widget.quiz.questions.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (question.isFillIn)
              const Chip(
                avatar: Icon(Icons.edit_note_rounded, size: 18),
                label: Text('Written response'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Question progress',
          child: LinearProgressIndicator(
            value: (_index + 1) / widget.quiz.questions.length,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Text(
              question.text,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 21,
                height: 1.38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!question.isFillIn) ...[
          ...question.options.map(
            (option) => _OptionTile(
              option: option,
              selected: option.key == _selectedKey,
              enabled: !_answered,
              result: _answered
                  ? option.key.toLowerCase() == question.answerKey.toLowerCase()
                        ? _OptionResult.correct
                        : option.key == _selectedKey
                        ? _OptionResult.incorrect
                        : _OptionResult.neutral
                  : _OptionResult.neutral,
              onTap: () => setState(() => _selectedKey = option.key),
            ),
          ),
          const SizedBox(height: 8),
          if (!_answered)
            FilledButton.icon(
              onPressed: _selectedKey == null ? null : _checkChoice,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Check answer'),
            )
          else ...[
            _FeedbackCard(
              correct:
                  _selectedKey?.toLowerCase() ==
                  question.answerKey.toLowerCase(),
              question: question,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving ? null : _next,
              child: Text(
                _index + 1 == widget.quiz.questions.length
                    ? 'Finish quiz'
                    : 'Next question',
              ),
            ),
          ],
        ] else ...[
          TextField(
            controller: _responseController,
            minLines: 2,
            maxLines: 5,
            enabled: !_fillRevealed,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Your response (optional)',
              alignLabelWithHint: true,
              hintText:
                  'Write what you remember before revealing the guide answer.',
            ),
          ),
          const SizedBox(height: 12),
          if (!_fillRevealed)
            FilledButton.icon(
              onPressed: () => setState(() => _fillRevealed = true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Show model answer'),
            )
          else ...[
            _FeedbackCard(correct: null, question: question),
            const SizedBox(height: 10),
            Text(
              'Compare your response with the model answer, then mark your recall honestly.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _answered ? null : () => _record(false),
                    child: const Text('Needs review'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _answered ? null : () => _record(true),
                    child: const Text('I got it'),
                  ),
                ),
              ],
            ),
            if (_answered) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _next,
                child: Text(
                  _index + 1 == widget.quiz.questions.length
                      ? 'Finish quiz'
                      : 'Next question',
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _result(BuildContext context) {
    final total = widget.quiz.questions.length;
    final percent = total == 0 ? 0 : (100 * _correct / total).round();
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      percent >= 70
                          ? Icons.emoji_events_outlined
                          : Icons.local_library_outlined,
                      size: 34,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Practice complete',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$percent%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_correct correct of $total · ${_missedIds.length} saved for review',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : _correct / total,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to study'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FlashcardDeckScreen extends StatefulWidget {
  const FlashcardDeckScreen({
    super.key,
    required this.store,
    required this.cards,
    required this.title,
  });
  final AppStore store;
  final List<StudyFlashcard> cards;
  final String title;

  @override
  State<FlashcardDeckScreen> createState() => _FlashcardDeckScreenState();
}

class _FlashcardDeckScreenState extends State<FlashcardDeckScreen> {
  int _index = 0;
  int _reviewed = 0;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('No flashcards in this unit yet.')),
      );
    }
    final card = widget.cards[_index.clamp(0, widget.cards.length - 1)];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Flashcards · ${widget.title}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_index + 1} of ${widget.cards.length}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text('$_reviewed reviewed'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_index + 1) / widget.cards.length,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () => setState(() => _revealed = !_revealed),
            child: Container(
              constraints: const BoxConstraints(minHeight: 290),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _revealed
                    ? const Color(0xFF155B47)
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _revealed ? 'ANSWER' : 'QUESTION',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _revealed ? card.back : card.front,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_revealed && card.explanation.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    Text(
                      card.explanation,
                      style: const TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ],
                  if (_revealed && card.citation.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    Text(
                      card.citation,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    _revealed
                        ? 'Tap to return to the question'
                        : 'Tap to reveal the answer',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_revealed)
            FilledButton.icon(
              onPressed: () => setState(() => _revealed = true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Reveal answer'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rate(false),
                    child: const Text('Practice again'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _rate(true),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filledTonal(
                tooltip: 'Previous card',
                onPressed: _index > 0
                    ? () => setState(() {
                        _index--;
                        _revealed = false;
                      })
                    : null,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Text(
                'Progress saved on this device',
                style: theme.textTheme.bodySmall,
              ),
              IconButton.filledTonal(
                tooltip: 'Next card',
                onPressed: _index + 1 < widget.cards.length
                    ? () => setState(() {
                        _index++;
                        _revealed = false;
                      })
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _rate(bool knewIt) {
    widget.store.rateFlashcard(widget.cards[_index].id, knewIt: knewIt);
    setState(() {
      _reviewed++;
      _revealed = false;
      if (_index + 1 < widget.cards.length) _index++;
    });
  }
}

class MistakesScreen extends StatelessWidget {
  const MistakesScreen({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final questions = store.mistakes
          .map((id) => store.questionById(id))
          .whereType<StudyQuestion>()
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Review questions')),
        body: questions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You’re all caught up',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Missed answers from your quizzes will appear here for review.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                children: [
                  Text(
                    '${questions.length} saved for review',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  ...questions.map(
                    (question) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.text,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Answer: ${question.correctAnswer}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                              if (question.explanation.isNotEmpty) ...[
                                const SizedBox(height: 7),
                                Text(
                                  question.explanation,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(height: 1.45),
                                ),
                              ],
                              if (question.citation.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _SourceCitation(text: question.citation),
                              ],
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      store.clearMistake(question.id),
                                  icon: const Icon(Icons.done_rounded),
                                  label: const Text('Mark reviewed'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({required this.store, required this.quiz});
  final AppStore store;
  final StudyQuiz quiz;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnitScreen(store: store, quiz: quiz),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: quiz.verifiedPacket
                    ? const Color(0xFFE0F2E8)
                    : Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  quiz.verifiedPacket
                      ? Icons.verified_outlined
                      : Icons.menu_book_outlined,
                  color: quiz.verifiedPacket
                      ? const Color(0xFF155B47)
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quiz.questions.length} questions · ${store.content.cardsForUnit(quiz.unitId).length} cards${quiz.verifiedPacket ? ' · cited' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}

class _VerifiedBanner extends StatelessWidget {
  const _VerifiedBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer
          .withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_outlined,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Source-verified Geography packet',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '48 textbook-cited questions · 64 flashcards · 8 units',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _VerifiedTag extends StatelessWidget {
  const _VerifiedTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_outlined, color: Colors.white, size: 17),
        SizedBox(width: 6),
        Text(
          'SOURCE-VERIFIED',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Card(
    color: primary ? Theme.of(context).colorScheme.primaryContainer : null,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primary
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                icon,
                color: primary
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

enum _OptionResult { neutral, correct, incorrect }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.result,
    required this.onTap,
  });
  final StudyOption option;
  final bool selected;
  final bool enabled;
  final _OptionResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final correctBackground = isDark
        ? const Color(0xFF183E30)
        : const Color(0xFFE3F5EB);
    final incorrectBackground = isDark
        ? const Color(0xFF482526)
        : const Color(0xFFFFE9E7);
    final Color? background = result == _OptionResult.correct
        ? correctBackground
        : result == _OptionResult.incorrect
        ? incorrectBackground
        : selected
        ? theme.colorScheme.primaryContainer
        : null;
    final Color border = result == _OptionResult.correct
        ? isDark
              ? const Color(0xFF73C897)
              : const Color(0xFF25754D)
        : result == _OptionResult.incorrect
        ? isDark
              ? const Color(0xFFFF8A80)
              : const Color(0xFFB3261E)
        : selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final Color foreground = result == _OptionResult.correct
        ? isDark
              ? const Color(0xFFE4F4EB)
              : const Color(0xFF183329)
        : result == _OptionResult.incorrect
        ? isDark
              ? const Color(0xFFFFE8E6)
              : const Color(0xFF3D1715)
        : selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    option.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      option.text,
                      style: TextStyle(
                        height: 1.35,
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (result == _OptionResult.correct)
                  Icon(Icons.check_circle, color: foreground),
                if (result == _OptionResult.incorrect)
                  Icon(Icons.cancel, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.correct, required this.question});
  final bool? correct;
  final StudyQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRight = correct == true;
    final isDark = theme.brightness == Brightness.dark;
    final color = correct == null
        ? theme.colorScheme.secondaryContainer
        : isRight
        ? isDark
              ? const Color(0xFF183E30)
              : const Color(0xFFE3F5EB)
        : isDark
        ? const Color(0xFF482526)
        : const Color(0xFFFFE9E7);
    final foreground = correct == null
        ? theme.colorScheme.onSecondaryContainer
        : isRight
        ? isDark
              ? const Color(0xFFE4F4EB)
              : const Color(0xFF183329)
        : isDark
        ? const Color(0xFFFFE8E6)
        : const Color(0xFF3D1715);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (correct != null)
                Icon(
                  isRight ? Icons.check_circle_outline : Icons.info_outline,
                  color: foreground,
                ),
              if (correct != null) const SizedBox(width: 8),
              Text(
                correct == null
                    ? 'Model answer'
                    : isRight
                    ? 'Correct'
                    : 'Let’s review it',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.correctAnswer,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              question.explanation,
              style: TextStyle(color: foreground, height: 1.45),
            ),
          ],
          if (question.citation.isNotEmpty) ...[
            const SizedBox(height: 9),
            _SourceCitation(text: question.citation, color: foreground),
          ],
        ],
      ),
    );
  }
}

class _SourceCitation extends StatelessWidget {
  const _SourceCitation({required this.text, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.menu_book_outlined,
        size: 16,
        color: color ?? Theme.of(context).colorScheme.secondary,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: color, fontSize: 12, height: 1.4),
        ),
      ),
    ],
  );
}
