/// What the metronome clicks with. The names are the ones a drummer uses, and
/// each one has its own length and brightness, which changes how easy the
/// beat is to hear.
///
/// All of these but the stick are recordings, cut by `tool/trim_clicks.dart`
/// to the shortest tail that still sounds like the instrument.
enum ClickVoice {
  stick('Stick', 'A short wood block tick, the classic metronome sound.'),
  kick('Kick', 'A low thump you feel more than hear, soft on the ear.'),
  snare('Snare', 'A real snare hit, dry and short enough to sit on the beat.'),
  tom('Tom', 'A round, deep drum note with a pitch you can hum back.'),
  cymbal('Cymbal', 'A ride cymbal: the ping rings on past the beat.'),
  bell('Bell', 'The bell of a cymbal: a thin, bright ping that cuts through.'),
  clap('Clap', 'One hand clap, warm enough to keep time with.'),
  cowbell('Cowbell', 'Two pitches at once, the sharpest of the set.'),
  hatClosed(
    'Closed Hi-hat',
    'The hats snapped together: a tight hiss that fills the gap between beats.',
  ),
  hatSemi(
    'Semi-closed Hi-hat',
    'The tightest hat of the three, almost all attack and no ring at all.',
  ),
  hatOpen(
    'Open Hi-hat',
    'The hats left apart: a long, hissy wash that rings past the beat.',
  );

  const ClickVoice(this.label, this.blurb);

  final String label;
  final String blurb;
}
