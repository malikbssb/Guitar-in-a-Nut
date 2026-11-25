import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// Expert rounds have no options to fall back on: the player writes the note,
/// the chord or the interval instead of picking one. The parent owns the
/// controller so it can clear it between questions.
class TypedAnswerField extends StatelessWidget {
  final TextEditingController controller;
  final bool canType;
  final VoidCallback onSubmit;

  const TypedAnswerField({
    super.key,
    required this.controller,
    required this.canType,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('typed-answer'),
          controller: controller,
          enabled: canType,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: L.t(context, 'Type your answer'),
            hintText: L.t(context, 'a note, a chord, an interval'),
            border: const OutlineInputBorder(),
          ),
        ),
        if (canType) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.check),
            label: Text(L.t(context, 'Check that answer')),
          ),
        ],
      ],
    );
  }
}
