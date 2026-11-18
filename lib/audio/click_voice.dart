/// What the metronome clicks with. The names are the ones a drummer uses, and
/// each one has its own length and brightness, which changes how easy the
/// beat is to hear.
enum ClickVoice {
  stick('Stick', 'A short wood block tick, the classic metronome sound.'),
  snare('Snare', 'A noise burst with the wires rattling under it.'),
  cymbal('Cymbal', 'Bright and long, the one that disappears least.'),
  clap('Clap', 'Three hand claps, warm enough to keep time with.'),
  cowbell('Cowbell', 'Two pitches at once, the sharpest of the set.');

  const ClickVoice(this.label, this.blurb);

  final String label;
  final String blurb;
}
