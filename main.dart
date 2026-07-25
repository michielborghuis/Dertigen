import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const DertigenApp());
}

class DertigenApp extends StatelessWidget {
  const DertigenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dertigen Teller',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB300),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111318),
        cardTheme: const CardThemeData(
          color: Color(0xFF1B1E25),
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
        useMaterial3: true,
      ),
      home: const ScoreScreen(),
    );
  }
}

class Player {
  Player({
    required this.name,
    this.score = 0,
    this.drinks = 0,
  });

  String name;
  int score;
  int drinks;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'drinks': drinks,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        name: json['name'] as String? ?? 'Speler',
        score: json['score'] as int? ?? 0,
        drinks: json['drinks'] as int? ?? 0,
      );
}

class GameSnapshot {
  GameSnapshot(this.players);

  final List<Player> players;
}

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  static const _storageKey = 'dertigen_players';
  final List<Player> _players = [];
  final List<GameSnapshot> _history = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _players
          ..clear()
          ..addAll(
            decoded.map(
              (item) => Player.fromJson(item as Map<String, dynamic>),
            ),
          );
      } catch (_) {
        // Een beschadigde opslag mag de app niet blokkeren.
      }
    }

    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_players.map((player) => player.toJson()).toList()),
    );
  }

  void _rememberState() {
    _history.add(
      GameSnapshot(
        _players
            .map(
              (player) => Player(
                name: player.name,
                score: player.score,
                drinks: player.drinks,
              ),
            )
            .toList(),
      ),
    );

    if (_history.length > 30) {
      _history.removeAt(0);
    }
  }

  Future<void> _changeScore(int index, int amount, {bool drink = false}) async {
    _rememberState();
    setState(() {
      _players[index].score += amount;
      if (drink) {
        _players[index].drinks += 1;
      }
    });
    await _save();
  }

  Future<void> _undo() async {
    if (_history.isEmpty) return;

    final snapshot = _history.removeLast();
    setState(() {
      _players
        ..clear()
        ..addAll(snapshot.players);
    });
    await _save();
  }

  Future<String?> _askForName({
    String title = 'Speler toevoegen',
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 24,
          decoration: const InputDecoration(
            labelText: 'Naam',
            hintText: 'Bijvoorbeeld Michiel',
          ),
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isNotEmpty) Navigator.pop(context, name);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) Navigator.pop(context, name);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPlayer() async {
    final name = await _askForName();
    if (name == null) return;

    _rememberState();
    setState(() => _players.add(Player(name: name)));
    await _save();
  }

  Future<void> _editPlayer(int index) async {
    final name = await _askForName(
      title: 'Naam wijzigen',
      initialValue: _players[index].name,
    );
    if (name == null) return;

    _rememberState();
    setState(() => _players[index].name = name);
    await _save();
  }

  Future<void> _deletePlayer(int index) async {
    final player = _players[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${player.name} verwijderen?'),
        content: const Text(
          'De score en slokkenteller van deze speler worden verwijderd.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _rememberState();
    setState(() => _players.removeAt(index));
    await _save();
  }

  Future<void> _resetGame() async {
    if (_players.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuw spel starten?'),
        content: const Text(
          'Alle scores en slokkentellers worden op nul gezet. '
          'De spelers blijven staan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nieuw spel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _rememberState();
    setState(() {
      for (final player in _players) {
        player.score = 0;
        player.drinks = 0;
      }
    });
    await _save();
  }

  Future<void> _movePlayer(int oldIndex, int newIndex) async {
    _rememberState();
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final player = _players.removeAt(oldIndex);
      _players.insert(newIndex, player);
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final totalDrinks = _players.fold<int>(
      0,
      (total, player) => total + player.drinks,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dertigen',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Laatste actie terugdraaien',
            onPressed: _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') _resetGame();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.restart_alt_rounded),
                  title: Text('Nieuw spel'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlayer,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Speler'),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? _EmptyState(onAdd: _addPlayer)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_bar_rounded),
                            const SizedBox(width: 10),
                            Text(
                              'Totaal genomen: $totalDrinks',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_players.length} speler${_players.length == 1 ? '' : 's'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final count = _players.length;
                          final columns = count <= 2 ? 1 : (count <= 4 ? 2 : 3);
                          final rows = (count / columns).ceil();
                          final shouldScroll = count > 9;

                          const horizontalPadding = 12.0;
                          const bottomPadding = 88.0;
                          const spacing = 8.0;

                          final usableWidth =
                              constraints.maxWidth - (horizontalPadding * 2);
                          final cardWidth =
                              (usableWidth - spacing * (columns - 1)) / columns;

                          final availableHeight = shouldScroll
                              ? constraints.maxHeight
                              : constraints.maxHeight - bottomPadding;
                          final cardHeight = shouldScroll
                              ? (columns == 3 ? 230.0 : 250.0)
                              : (availableHeight -
                                      spacing * (rows - 1)) /
                                  rows;

                          final safeCardHeight =
                              cardHeight.clamp(150.0, 320.0).toDouble();
                          final aspectRatio = cardWidth / safeCardHeight;
                          final compact = columns >= 2 || safeCardHeight < 235;

                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              bottomPadding,
                            ),
                            physics: shouldScroll
                                ? const BouncingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: count,
                            itemBuilder: (context, index) {
                              final player = _players[index];
                              return _PlayerCard(
                                player: player,
                                compact: compact,
                                onPlusOne: () => _changeScore(index, 1),
                                onPlusTen: () => _changeScore(index, 10),
                                onMinusFifteen: () =>
                                    _changeScore(index, -15, drink: true),
                                onEdit: () => _editPlayer(index),
                                onDelete: () => _deletePlayer(index),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.compact,
    required this.onPlusOne,
    required this.onPlusTen,
    required this.onMinusFifteen,
    required this.onEdit,
    required this.onDelete,
  });

  final Player player;
  final bool compact;
  final VoidCallback onPlusOne;
  final VoidCallback onPlusTen;
  final VoidCallback onMinusFifteen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final nameSize = compact ? 15.0 : 21.0;
    final scoreSize = compact ? 36.0 : 54.0;
    final buttonHeight = compact ? 42.0 : 54.0;
    final buttonTextSize = compact ? 15.0 : 20.0;
    final cardPadding = compact
        ? const EdgeInsets.fromLTRB(10, 8, 10, 10)
        : const EdgeInsets.fromLTRB(16, 14, 16, 16);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: nameSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 6 : 9,
                    vertical: compact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_bar_rounded,
                        size: compact ? 13 : 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${player.drinks}',
                        style: TextStyle(
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: compact ? 20 : 24,
                  tooltip: 'Speleropties',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Naam wijzigen'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Verwijderen'),
                    ),
                  ],
                ),
              ],
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${player.score}',
                  style: TextStyle(
                    fontSize: scoreSize,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: player.score >= 30
                        ? colors.error
                        : colors.onSurface,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onPlusOne,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(buttonHeight),
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 4 : 10,
                      ),
                    ),
                    child: Text(
                      '+1',
                      style: TextStyle(
                        fontSize: buttonTextSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 4 : 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onPlusTen,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(buttonHeight),
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 4 : 10,
                      ),
                    ),
                    child: Text(
                      '+10',
                      style: TextStyle(
                        fontSize: buttonTextSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 4 : 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onMinusFifteen,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(buttonHeight),
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2 : 10,
                      ),
                    ),
                    child: Text(
                      '−15',
                      style: TextStyle(
                        fontSize: buttonTextSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded, size: 76),
            const SizedBox(height: 18),
            const Text(
              'Nog geen spelers',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Voeg de eerste speler toe om de scores bij te houden.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Speler toevoegen'),
            ),
          ],
        ),
      ),
    );
  }
}
