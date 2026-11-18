import 'package:flutter/material.dart';

/// Answer row used by both quizzes: neutral before you pick, green or red
/// once the answer is revealed.
class OptionButton extends StatelessWidget {
  final String text;
  final bool isAnswer;
  final bool isPicked;
  final bool revealed;
  final VoidCallback onTap;

  const OptionButton({
    super.key,
    required this.text,
    required this.isAnswer,
    required this.isPicked,
    required this.revealed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color? background;
    final Color foreground;

    if (!revealed) {
      background = null;
      foreground = scheme.onSurface;
    } else if (isAnswer) {
      background = const Color(0xFF2E7D32);
      foreground = Colors.white;
    } else if (isPicked) {
      background = const Color(0xFFC62828);
      foreground = Colors.white;
    } else {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: revealed ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          alignment: Alignment.centerLeft,
        ),
        child: Text(text),
      ),
    );
  }
}
