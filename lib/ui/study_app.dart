import 'package:flutter/material.dart';

import '../data/study_content.dart';
import '../state/app_store.dart';
import 'app_theme.dart';
import 'study_pages.dart';

class ArekaApp extends StatelessWidget {
  const ArekaApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      title: 'Areka Study',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeShell(store: store),
    ),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final AppStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(
        store: widget.store,
        onOpenLibrary: () => setState(() => _selectedIndex = 1),
      ),
      LibraryTab(store: widget.store),
      FlashcardsTab(store: widget.store),
      ProfileTab(store: widget.store),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style_rounded),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.store, required this.onOpenLibrary});
  final AppStore store;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final subjects = store.content.subjects;
    final totalUnits = store.content.quizzes.length;
    final firstQuiz = store.content.quizzes.first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Areka Study'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _initials(store.profileName),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${store.profileName}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _HeroCard(
                    unitCount: totalUnits,
                    onStart: () => openQuiz(context, store, firstQuiz),
                    onBrowse: onOpenLibrary,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.quiz_outlined,
                          value: '${store.quizzesCompleted}',
                          label: 'Quizzes done',
                          color: const Color(0xFFECE7FB),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.auto_awesome_outlined,
                          value: '${store.accuracy}%',
                          label: 'Accuracy',
                          color: const Color(0xFFE2F4EB),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.style_outlined,
                          value: '${store.cardsReviewed}',
                          label: 'Cards reviewed',
                          color: const Color(0xFFFFEFDB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your subjects',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: onOpenLibrary,
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, box) {
                      final columns = box.maxWidth > 620 ? 3 : 2;
                      final width =
                          (box.maxWidth - 12 * (columns - 1)) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: subjects
                            .take(6)
                            .map(
                              (subject) => SizedBox(
                                width: width,
                                child: _SubjectMiniCard(
                                  subject: subject,
                                  unitCount: store.content
                                      .quizzesFor(subject)
                                      .length,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SubjectScreen(
                                        store: store,
                                        subject: subject,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  if (subjects.length > 6) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: onOpenLibrary,
                      icon: const Icon(Icons.grid_view_rounded),
                      label: Text('Explore all ${subjects.length} subjects'),
                    ),
                  ],
                  const SizedBox(height: 26),
                  _OfflineNote(
                    questionCount: store.content.questionCount,
                    cardCount: store.content.flashcards.length,
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

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key, required this.store});
  final AppStore store;

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.content.subjects
        .where((s) => s.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            'Pick a subject and continue at your own pace.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search subjects',
              labelText: 'Find a subject',
            ),
          ),
          const SizedBox(height: 16),
          ...subjects.map(
            (subject) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseCard(
                subject: subject,
                quizzes: widget.store.content.quizzesFor(subject),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SubjectScreen(store: widget.store, subject: subject),
                  ),
                ),
              ),
            ),
          ),
          if (subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No subjects match that search.')),
            ),
          const SizedBox(height: 8),
          _OfflineNote(
            questionCount: widget.store.content.questionCount,
            cardCount: widget.store.content.flashcards.length,
          ),
        ],
      ),
    );
  }
}

class FlashcardsTab extends StatefulWidget {
  const FlashcardsTab({super.key, required this.store});
  final AppStore store;

  @override
  State<FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> {
  String _subjectId = 'all';
  int _index = 0;
  int _sessionReviewed = 0;
  bool _revealed = false;
  List<StudyFlashcard>? _shuffledCards;
  String? _shuffledSubjectId;

  List<StudyFlashcard> get _cards {
    if (_shuffledSubjectId == _subjectId && _shuffledCards != null) {
      return _shuffledCards!;
    }
    final cards = widget.store.content.flashcards;
    if (_subjectId == 'all') return cards;
    return cards.where((card) => card.subjectId == _subjectId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    final subjects = widget.store.content.subjects;
    final idToName = <String, String>{};
    for (final quiz in widget.store.content.quizzes) {
      idToName[quiz.subjectId] = quiz.subject;
    }
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: const Center(child: Text('No cards in this subject yet.')),
      );
    }
    _index = _index.clamp(0, cards.length - 1);
    final card = cards[_index];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            tooltip: 'Shuffle cards',
            onPressed: () => setState(() {
              _shuffledCards = List<StudyFlashcard>.of(cards)..shuffle();
              _shuffledSubjectId = _subjectId;
              _index = 0;
              _revealed = false;
            }),
            icon: const Icon(Icons.shuffle_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Make recall your superpower.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_subjectId),
                    initialValue: _subjectId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Card deck',
                      prefixIcon: Icon(Icons.filter_list_rounded),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text(
                          'All subjects',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...subjects.map((subject) {
                        final id = widget.store.content.quizzes
                            .firstWhere((quiz) => quiz.subject == subject)
                            .subjectId;
                        return DropdownMenuItem(
                          value: id,
                          child: Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) => setState(() {
                      _subjectId = value ?? 'all';
                      _shuffledCards = null;
                      _shuffledSubjectId = null;
                      _index = 0;
                      _revealed = false;
                    }),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${_index + 1} of ${cards.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$_sessionReviewed reviewed this session',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_index + 1) / cards.length,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    button: true,
                    label: _revealed
                        ? 'Flashcard answer. Tap to show question.'
                        : 'Flashcard question. Tap to reveal the answer.',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => setState(() => _revealed = !_revealed),
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: box.maxHeight * 0.39,
                        ),
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _revealed
                                ? [
                                    const Color(0xFF176A51),
                                    const Color(0xFF0E4F42),
                                  ]
                                : [
                                    const Color(0xFF6045C6),
                                    const Color(0xFF37246F),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.18,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Column(
                            key: ValueKey('${card.id}-$_revealed'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _revealed
                                        ? Icons.lightbulb_outline
                                        : Icons.style_outlined,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _revealed ? 'ANSWER' : 'QUESTION',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _revealed ? card.back : card.front,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _revealed ? 19 : 23,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_revealed && card.explanation.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  card.explanation,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (_revealed && card.citation.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  card.citation,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              Text(
                                _revealed
                                    ? 'Tap to see the question again'
                                    : 'Tap to reveal · ${idToName[card.subjectId] ?? 'Study'}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                  else if (box.maxWidth < 380)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _rate(card, false, cards.length),
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Practice again'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _rate(card, true, cards.length),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Got it'),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rate(card, false, cards.length),
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('Practice again'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _rate(card, true, cards.length),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Got it'),
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
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Reviewed ${widget.store.cardsReviewed} cards total',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Next card',
                        onPressed: _index + 1 < cards.length
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
            ),
          ),
        ),
      ),
    );
  }

  void _rate(StudyFlashcard card, bool knewIt, int length) {
    widget.store.rateFlashcard(card.id, knewIt: knewIt);
    setState(() {
      _sessionReviewed++;
      _revealed = false;
      if (_index + 1 < length) _index++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          knewIt
              ? 'Added to your mastered cards.'
              : 'We’ll bring this card back for practice.',
        ),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achievements =
        <({String title, String description, IconData icon, bool earned})>[
          (
            title: 'First steps',
            description: 'Complete your first quiz',
            icon: Icons.flag_outlined,
            earned: store.quizzesCompleted > 0,
          ),
          (
            title: 'Recall builder',
            description: 'Review 20 flashcards',
            icon: Icons.style_outlined,
            earned: store.cardsReviewed >= 20,
          ),
          (
            title: 'Perfect focus',
            description: 'Earn 100% on a quiz',
            icon: Icons.stars_outlined,
            earned: store.attempts.any(
              (a) => a.total > 0 && a.correct == a.total,
            ),
          ),
        ];
    return Scaffold(
      appBar: AppBar(title: const Text('Your progress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      _initials(store.profileName),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.profileName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Your learning stays on this device',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit learner name',
                    onPressed: () => _editName(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.emoji_events_outlined,
                  value: '${store.points}',
                  label: 'Points',
                  color: const Color(0xFFFFEFDB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.quiz_outlined,
                  value: '${store.quizzesCompleted}',
                  label: 'Quizzes',
                  color: const Color(0xFFECE7FB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.check_circle_outline,
                  value: '${store.accuracy}%',
                  label: 'Accuracy',
                  color: const Color(0xFFE2F4EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Achievements',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...achievements.map(
            (achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: achievement.earned
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      achievement.icon,
                      color: achievement.earned
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    achievement.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(achievement.description),
                  trailing: Icon(
                    achievement.earned
                        ? Icons.check_circle
                        : Icons.lock_outline,
                    color: achievement.earned
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: store.darkMode,
                  onChanged: store.setDarkMode,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark theme'),
                  subtitle: const Text('Choose a comfortable display'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.rule_folder_outlined),
                  title: const Text('Review missed questions'),
                  subtitle: Text(
                    '${store.mistakes.length} saved for another look',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MistakesScreen(store: store),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OfflineNote(
            questionCount: store.content.questionCount,
            cardCount: store.content.flashcards.length,
          ),
          const SizedBox(height: 12),
          Text(
            'Profile, quiz results, and card ratings are stored locally. Cloud sign-in and cross-device sync are not connected in this build.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: store.profileName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Learner name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) await store.updateName(result);
    controller.dispose();
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.unitCount,
    required this.onStart,
    required this.onBrowse,
  });
  final int unitCount;
  final VoidCallback onStart;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6045C6), Color(0xFF382474)],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$unitCount study units · works offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Small steps.\nStronger learning.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Practice a little, remember a lot.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.87),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start a quick quiz'),
            ),
            OutlinedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Browse subjects'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.75)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).brightness == Brightness.light
        ? color
        : Theme.of(context).colorScheme.surfaceContainerHigh,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 9),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _SubjectMiniCard extends StatelessWidget {
  const _SubjectMiniCard({
    required this.subject,
    required this.unitCount,
    required this.onTap,
  });
  final String subject;
  final int unitCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                _subjectIcon(subject),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '$unitCount units',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.subject,
    required this.quizzes,
    required this.onTap,
  });
  final String subject;
  final List<StudyQuiz> quizzes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final questionCount = quizzes.fold<int>(
      0,
      (sum, quiz) => sum + quiz.questions.length,
    );
    final cards = quizzes.where((quiz) => quiz.verifiedPacket).length;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  _subjectIcon(subject),
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${quizzes.length} units · $questionCount questions',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (cards > 0) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Includes source-cited Grade 10 textbook packet',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote({required this.questionCount, required this.cardCount});
  final int questionCount;
  final int cardCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer
          .withValues(alpha: 0.58),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.offline_bolt_outlined,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$questionCount questions and $cardCount flashcards are bundled on this device. Your study data stays available offline.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    ),
  );
}

IconData _subjectIcon(String subject) {
  final lower = subject.toLowerCase();
  if (lower.contains('math')) return Icons.calculate_outlined;
  if (lower.contains('physics')) return Icons.bolt_outlined;
  if (lower.contains('chem')) return Icons.science_outlined;
  if (lower.contains('biology')) return Icons.eco_outlined;
  if (lower.contains('geography')) return Icons.public_outlined;
  if (lower.contains('civics')) return Icons.account_balance_outlined;
  if (lower.contains('econom')) return Icons.trending_up_rounded;
  if (lower.contains('health')) return Icons.favorite_border_rounded;
  if (lower.contains('history')) return Icons.history_edu_outlined;
  return Icons.menu_book_outlined;
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'L';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}
