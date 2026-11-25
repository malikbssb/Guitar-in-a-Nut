import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'section_glyph.dart';

/// Sections reachable from the left rail. The tuner itself lives behind the
/// wooden logo, exactly like the mock-up.
enum AppSection {
  chords,
  neck,
  learn,
  quiz,
  earTraining,
  metronome,
  drumMachine,
}

class _RailItem {
  final AppSection section;

  /// Either an [Icon] or one of the drawn glyphs in `section_glyph.dart`.
  final Widget icon;
  final String label;

  const _RailItem(this.section, this.icon, this.label);
}

const _items = <_RailItem>[
  _RailItem(AppSection.chords, Icon(Icons.grid_view), 'CHORDS / SCALES'),
  _RailItem(AppSection.neck, NeckGlyph(), 'NECK'),
  _RailItem(AppSection.learn, Icon(Icons.school_outlined), 'LEARN'),
  _RailItem(AppSection.quiz, Icon(Icons.quiz_outlined), 'QUIZ'),
  _RailItem(AppSection.earTraining, Icon(Icons.hearing), 'EAR TRAINING'),
  _RailItem(AppSection.metronome, MetronomeGlyph(), 'METRONOME'),
  _RailItem(AppSection.drumMachine, SnareGlyph(), 'DRUM MACHINE'),
];

/// Hamburger strip that widens into a labelled menu when tapped.
class NavRail extends StatelessWidget {
  final bool expanded;
  final AppSection? current;
  final ValueChanged<AppSection> onSelect;
  final VoidCallback onToggle;

  const NavRail({
    super.key,
    required this.expanded,
    required this.current,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: expanded ? 214 : 62,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(26)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(26)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 6,
                left: expanded ? 14 : 8,
              ),
              child: IconButton(
                tooltip: L.t(context, expanded ? 'Collapse menu' : 'Open menu'),
                onPressed: onToggle,
                icon: Icon(
                  expanded ? Icons.close : Icons.menu,
                  color: scheme.onSurface,
                ),
              ),
            ),
            for (final item in _items)
              _RailButton(
                item: item,
                expanded: expanded,
                selected: current == item.section,
                onSelect: onSelect,
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  final _RailItem item;
  final bool expanded;
  final bool selected;
  final ValueChanged<AppSection> onSelect;

  const _RailButton({
    required this.item,
    required this.expanded,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: () => onSelect(item.section),
      child: Container(
        height: 58,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 10),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.14) : null,
          border: selected
              ? Border(left: BorderSide(color: scheme.primary, width: 3))
              : null,
        ),
        child: Row(
          children: [
            // The drawn glyphs read their colour and size from here too, so
            // they sit on the same baseline as the Material icons.
            IconTheme(
              data: IconThemeData(color: color, size: 22),
              child: item.icon,
            ),
            if (expanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  L.t(context, item.label),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
