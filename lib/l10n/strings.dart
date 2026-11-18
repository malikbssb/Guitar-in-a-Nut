import 'package:flutter/material.dart';

/// The two languages the interface ships in.
enum AppLang { en, fr }

/// Interface strings, English on one side and French on the other.
///
/// The English text is its own key, so a screen reads naturally in the source
/// language and a missing translation falls back to English instead of
/// showing a blank. Only the chrome is listed: chord stories, tuning hints,
/// scale blurbs, lesson bodies and quiz questions stay in English.
class L extends InheritedWidget {
  final AppLang lang;

  const L({super.key, required this.lang, required super.child});

  static AppLang of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<L>()?.lang ?? AppLang.en;

  static String t(BuildContext context, String key) =>
      of(context) == AppLang.fr ? (_fr[key] ?? key) : key;

  /// [t] with `{placeholders}` filled in, for sentences built around numbers
  /// and note names.
  static String f(BuildContext context, String key, Map<String, String> args) {
    var out = t(context, key);
    for (final entry in args.entries) {
      out = out.replaceAll('{${entry.key}}', entry.value);
    }
    return out;
  }

  @override
  bool updateShouldNotify(L oldWidget) => oldWidget.lang != lang;
}

const _fr = <String, String>{
  // Left rail.
  'CHORDS / SCALES': 'ACCORDS / GAMMES',
  'NECK': 'MANCHE',
  'LEARN': 'APPRENDRE',
  'EAR TRAINING': 'OREILLE',
  'Open menu': 'Ouvrir le menu',
  'Collapse menu': 'Replier le menu',

  // Bottom-right and bottom-left buttons, plus the sheet they open.
  'Back to the dark theme': 'Retour au thème sombre',
  'Switch to light mode': 'Passer en mode clair',
  'Settings': 'Réglages',
  'Language': 'Langue',
  'Theme': 'Thème',
  'English': 'Anglais',
  'Dark': 'Sombre',
  'Light': 'Clair',
  'Only the interface is translated. Lessons, chord stories and quiz '
          'questions stay in English.':
      'Seule l\'interface est traduite. Les leçons, les histoires d\'accords '
      'et les questions du quiz restent en anglais.',

  // One line under the top bar, per section.
  'Enable your microphone, pluck a string and get to tuning!':
      'Active ton micro, pince une corde et accorde-toi !',
  '{n} shapes, sorted by the key they fit in.':
      '{n} formes, classées par la tonalité où elles tiennent.',
  'Every note of the neck, one tap away.':
      'Toutes les notes du manche, à un tap.',
  'Short pages that answer the questions beginners ask.':
      'Des pages courtes qui répondent aux questions des débutants.',
  'Ten questions drawn from a pool of {n}. New draw every round.': 'Dix questions tirées d\'un bassin de {n}. Nouveau tirage à chaque série.',
  'No names on screen. Listen, guess, then read why.':
      'Aucun nom à l\'écran. Écoute, devine, puis lis pourquoi.',

  // Start screen.
  'A tuner, the chords you actually need, and a quiz to check what stuck.':
      'Un accordeur, les accords dont tu as vraiment besoin, et un quiz pour '
      'vérifier ce qui est resté.',
  'Are you a complete beginner?': 'Tu débutes complètement ?',
  'Yes, teach me the basics first': 'Oui, apprends-moi les bases d\'abord',
  'No, take me to the tools': 'Non, emmène-moi aux outils',
  'You can open the same page later from the menu.':
      'Tu peux rouvrir cette page plus tard depuis le menu.',

  // Beginner page.
  'The basics': 'Les bases',
  'Four questions, in order. Answer them once and the rest of the app is '
          'only practice.':
      'Quatre questions, dans l\'ordre. Une fois répondues, le reste de \'app '
      'n\'est que de la pratique.',
  'How do I tune?': 'Comment j\'accorde ?',
  'Tap the wooden logo in the top left. That is the tuner, and it is always '
          'one tap away.':
      'Tape le logo en bois en haut à gauche : c\'est l\'accordeur, et il est '
      'toujours à un tap.',
  'Press Start and let the browser use your microphone.':
      'Appuie sur Démarrer et laisse le navigateur utiliser ton micro.',
  'Pluck one string, let it ring, and wait for a note name to appear.':
      'Pince une corde, laisse-la sonner et attends qu\'un nom de note '
      'apparaisse.',
  'Turn the peg until the needle sits dead centre. Always arrive from below: '
          'slip it past the note, then tune back up, so the string settles '
          'instead of sliding flat again.':
      'Tourne la mécanique jusqu\'à ce que l\'aiguille soit pile au centre. '
      'Arrive toujours par le bas : dépasse la note puis remonte, comme ça '
      'la corde se stabilise au lieu de retomber.',
  'Work through the six strings, then check them a second time. Tuning one '
          'string pulls on the others.':
      'Passe les six cordes, puis revérifie-les. Accorder une corde tire sur '
      'les autres.',
  'Which tuning should I use?': 'Quel accordage choisir ?',
  'Standard, from the thick string down to the thin one:':
      'Standard, de la corde épaisse vers la fine :',
  'The menu in the top right holds the other tunings. Leave it on standard '
          'while you learn.':
      'Le menu en haut à droite contient les autres accordages. Laisse '
      'standard tant que tu apprends.',
  'Why that one?': 'Pourquoi celui-là ?',
  'Almost every chord shape, tutorial and chord chart in the world is '
          'written in it, so anything you learn carries over.':
      'Presque toutes les formes d\'accord, les tutoriels et les grilles dans '
      'le monde sont écrits comme ça : tout ce que tu apprends est '
      'réutilisable.',
  'It spaces the open strings so the low E gives you a fat bass note for '
          'riffs and the thin E gives you a singing top note.':
      'Il espace les cordes à vide : le E grave donne une basse épaisse pour '
      'les riffs et le E aigu une note chantante.',
  'The other tunings exist for one specific sound each. They are worth '
          'trying once your hands know the fretboard.':
      'Les autres accordages visent chacun un son précis. À essayer quand tes '
      'mains connaissent le manche.',
  'How many notes are there?': 'Combien y a-t-il de notes ?',
  'Twelve, and only twelve. After the last one the list starts again at the '
          'same name, one octave higher.':
      'Douze, et seulement douze. Après la dernière, la liste recommence au '
      'même nom, une octave plus haut.',
  'A # means one fret up, so the shape of the list never changes wherever '
          'you start.':
      'Un # veut dire une case plus haut : la forme de la liste ne change '
      'jamais, quel que soit le point de départ.',
  'Pick one. From {a}: one fret up is {b}, two frets up is {c}, and twelve '
          'frets up is {d} again - exactly double the frequency, from {e} Hz to '
          '{f} Hz. That is why the 12th fret matters so much.':
      'Choisis-en une. Depuis {a} : une case plus haut c\'est {b}, deux cases '
      'plus haut {c}, et douze cases plus haut retrouve {d} - exactement le '
      'double de fréquence, de {e} Hz à {f} Hz. C\'est pour ça que la 12e '
      'case compte autant.',
  'Now show me the tools': 'Maintenant montre-moi les outils',

  // Tuner.
  'Microphone blocked. Open the padlock in Chrome\'s address bar, allow the '
          'microphone, then press Start again.':
      'Micro bloqué. Ouvre le cadenas dans la barre d\'adresse de Chrome, '
      'autorise le micro, puis rappuie sur Démarrer.',
  'Listening - pluck one string and let it ring.':
      'À l\'écoute - pince une corde et laisse-la sonner.',
  'The microphone did not start: {error}':
      'Le micro ne s\'est pas lancé : {error}',
  'Nothing loud enough: pluck a string.':
      'Rien d\'assez fort : pince une corde.',
  'Too noisy to be sure - play louder, one string at a time.':
      'Trop de bruit pour être sûr - joue plus fort, une corde à la fois.',
  '{chord} rings true. Next string?': '{chord} sonne juste. Corde suivante ?',
  'In tune. Move on to the next string.': 'Juste. Passe à la corde suivante.',
  'a little': 'un peu',
  'a lot': 'beaucoup',
  'Flat by {how}: tighten the string.': 'Bas de {how} : tends la corde.',
  'Sharp by {how}: loosen the string.': 'Haut de {how} : détends la corde.',
  'Confused? Click here to get a quick guide to get you started':
      'Perdu ? Clique ici pour un petit guide de démarrage',
  'no pitch detected': 'aucune hauteur détectée',
  '{hz} Hz - confidence {pct}%': '{hz} Hz - fiabilité {pct} %',
  'Start': 'Démarrer',
  'Stop': 'Stop',
  'Back to single strings': 'Retour aux cordes seules',

  // Chords and scales page.
  'Chords, sorted by key': 'Accords, classés par tonalité',
  'A key is a family of notes, and only a handful of chords sit inside it. '
          'The word above each shape is its degree: I is the home chord, V is '
          'the one pulling back to it. Numbers are fingers, o means play the '
          'open string, x means keep it silent.':
      'Une tonalité est une famille de notes, et seuls quelques accords y '
      'tiennent. Le mot au-dessus de chaque forme est son degré : I est '
      'l\'accord maison, V est celui qui y ramène. Les chiffres sont les '
      'doigts, o veut dire jouer la corde à vide, x la laisser muette.',
  'Key of C major / A minor': 'Tonalité de C majeur / A mineur',
  'Key of G major / E minor': 'Tonalité de G majeur / E mineur',
  'Key of D major / B minor': 'Tonalité de D majeur / B mineur',
  'Key of A major / F# minor': 'Tonalité de A majeur / F# mineur',
  'Key of E major / C# minor': 'Tonalité de E majeur / C# mineur',
  'Dominant 7ths: the blues set': 'Septièmes de dominante : le set blues',
  'Sus and add: colours, not resolutions':
      'Sus et add : des couleurs, pas des résolutions',
  'Power chords: root and 5th': 'Power chords : fondamentale et quinte',
  'Scales': 'Gammes',
  'A scale is a set of notes you can play over a chord or a whole song. What '
          'matters on the neck is the gap in frets between two degrees. Tap a '
          'pattern to hear it.':
      'Une gamme est un jeu de notes à poser sur un accord ou un morceau '
      'entier. Sur le manche, ce qui compte est l\'écart en cases entre deux '
      'degrés. Tape un motif pour l\'entendre.',
  'Minor pentatonic': 'Pentatonique mineure',
  'Major': 'Majeure',
  'Natural minor': 'Mineure naturelle',
  'Dorian': 'Dorien',
  'Mixolydian': 'Mixolydien',
  'Harmonic minor': 'Mineure harmonique',
  'Frets between the degrees: {p}': 'Cases entre les degrés : {p}',
  '{name} on {root}: {notes}': '{name} sur {root} : {notes}',
  'Hear the scale': 'Écouter la gamme',
  'One octave higher': 'Une octave plus haut',
  'Light it up on the neck': 'L\'allumer sur le manche',
  'Frets, string 6 to 1: {line}': 'Cases, cordes 6 à 1 : {line}',
  'On {tuning}, those strings play {notes}.':
      'En {tuning}, ces cordes jouent {notes}.',
  'In {group} it is the {degree}.': 'Dans {group}, c\'est le degré {degree}.',
  'Hear the chord': 'Écouter l\'accord',
  'One note at a time': 'Note par note',
  'Check it on the tuner': 'Vérifier à l\'accordeur',

  // Neck map.
  '{short} up to fret {n}': '{short} jusqu\'à la case {n}',
  'note names': 'noms des notes',
  'scale': 'gamme',
  '24 frets': '24 cases',
  'inlay dots': 'repères',
  'root note': 'note fondamentale',
  'str {n}': '{n}e',
  'Tap any position to hear it and read its name. The left column sits '
          'behind the nut, so it is the string played open.':
      'Tape n\'importe quelle position pour l\'entendre et lire son nom. La '
      'colonne de gauche est derrière le sillet : c\'est la corde jouée à '
      'vide.',
  'Every dot of that colour is one of those notes, on every string. The '
          'brighter dots are the root.':
      'Chaque point de cette couleur est une de ces notes, sur toutes les '
      'cordes. Les plus brillants sont la fondamentale.',
  'String {n} - {pos}': 'Corde {n} - {pos}',
  'open': 'à vide',
  'fret {n}': 'case {n}',
  'Play again': 'Réécouter',
  'Its 5th is {a} and its octave is {b}.':
      'Sa quinte est {a} et son octave {b}.',

  // Learn list.
  '{n} short pages, each one an answer to a question beginners actually '
          'ask. Every page has something to listen to.':
      '{n} pages courtes, chacune une réponse à une question que les '
      'débutants posent vraiment. Chaque page a quelque chose à écouter.',
  'All lessons': 'Toutes les leçons',

  // Written quiz.
  'A different quiz every time': 'Un quiz différent à chaque fois',
  'The app builds {n} questions from the diagrams, the tunings and the key '
          'groups on these pages, then draws a fresh set. Nothing repeats in '
          'the same order, and the four options get shuffled too.':
      'L\'app fabrique {n} questions à partir des diagrammes, des accordages '
      'et des tonalités de ces pages, puis tire un nouvel ensemble. Rien ne '
      'se répète dans le même ordre, et les quatre options sont mélangées '
      'aussi.',
  'How many questions?': 'Combien de questions ?',
  'Draw {n} questions': 'Tirer {n} questions',
  'Strong. You could tune someone else now.':
      'Solide. Tu peux accorder quelqu\'un d\'autre maintenant.',
  'Solid start. Another pass through LEARN and it clicks.':
      'Bon début. Un passage de plus par APPRENDRE et ça clique.',
  'Go back to Chords, then try again.': 'Retourne aux accords, puis réessaie.',
  'New round': 'Nouvelle série',
  'Question {i} of {n}': 'Question {i} sur {n}',
  'Score: {n}': 'Score : {n}',
  'Chord shapes': 'Formes d\'accord',
  'Note spelling': 'Orthographe des notes',
  'Intervals': 'Intervalles',
  'The neck': 'Le manche',
  'Rhythm': 'Rythme',
  'Tunings': 'Accordages',
  'Keys': 'Tonalités',
  'Theory': 'Théorie',
  'strings 6 → 1': 'cordes 6 → 1',
  'Correct': 'Correct',
  'Answer: {a}': 'Réponse : {a}',
  'See my score': 'Voir mon score',
  'Next question': 'Question suivante',

  // Ear training.
  'Ear training': 'Entraînement de l\'oreille',
  'No diagrams and no names on screen. Listen, guess, and the explanation '
          'tells you what to listen for next time.':
      'Pas de diagramme ni de nom à l\'écran. Écoute, devine, et '
      'l\'explication te dit quoi écouter la prochaine fois.',
  'Open strings only': 'Cordes à vide seulement',
  'All six strings, played open, in a random order. Name the note.':
      'Les six cordes jouées à vide, dans un ordre aléatoire. Donne la note.',
  'Chords only': 'Accords seulement',
  'Shapes straight off the CHORDS page, strummed one at a time.':
      'Des formes prises à la page ACCORDS, grattées une par une.',
  'Notes across the neck': 'Notes sur le manche',
  'A fretted note anywhere in the first twelve frets, on any string.':
      'Une note frettée n\'importe où sur les douze premières cases, sur '
      'n\'importe quelle corde.',
  'All in one': 'Tout mélangé',
  'Chords, notes, intervals, scales and meters, drawn from every pool.':
      'Accords, notes, intervalles, gammes et mesures, tirés de tous les '
      'bassins.',
  '{n} sounds, drawn fresh from {m}': '{n} sons, tirés d\'un lot de {m}',
  '{n} sounds, in a random order': '{n} sons, dans un ordre aléatoire',

  // Small tags under the ear-training header.
  'chord': 'accord',
  'quality': 'couleur',
  'interval': 'intervalle',
  'direction': 'sens',
  'texture': 'texture',
  'rhythm': 'rythme',
  'note': 'note',
  'Your ears are ahead of your hands. Try the written quiz too.':
      'Tes oreilles ont de l\'avance sur tes mains. Essaie aussi le quiz '
      'écrit.',
  'Good. Replay the ones you missed and listen for the 3rd.':
      'Bien. Réécoute ceux que tu as manqués et cherche la tierce.',
  'Play the sounds again slowly - comparison is what trains an ear.':
      'Réécoute les sons lentement - c\'est la comparaison qui entraîne une '
      'oreille.',
  'Run {mode} again': 'Rejouer {mode}',
  'Pick another round': 'Choisir une autre série',
  'Sound {i} of {n}': 'Son {i} sur {n}',
  'Hear the sound': 'Écouter le son',
  'Hear it again': 'Réécouter',
  'Next sound': 'Son suivant',

  // Tuning names in the top-right menu.
  'D standard': 'Standard en D',
  'Half step down': 'Un demi-ton plus bas',
  'DADGAD (modal)': 'DADGAD (modal)',
  'Open G (slide)': 'Ouvert en G (slide)',
  'Open D': 'Ouvert en D',
  'Open E': 'Ouvert en E',
  'Open C': 'Ouvert en C',
  'E standard': 'standard en E',
  'Eb standard': 'standard en Eb',

  // Metronome.
  'METRONOME': 'MÉTRONOME',
  'Metronome': 'Métronome',
  'Set the speed, count the bar, pick the click.':
      'Règle la vitesse, compte la mesure, choisis le clic.',
  'Slower': 'Plus lent',
  'Faster': 'Plus rapide',
  'Beats per bar': 'Temps par mesure',
  'The first beat of the bar sounds louder.':
      'Le premier temps de la mesure sonne plus fort.',
  'How many bars?': 'Combien de mesures ?',
  'Forever': 'Sans fin',
  '{n} bars': '{n} mesures',
  '{n} bar': '{n} mesure',
  'Click sound': 'Son du clic',
  'Hear this sound': 'Écouter ce son',
  'Stick': 'Bois',
  'A short wood block tick, the classic metronome sound.':
      'Un tick de bois court, le clic de métronome classique.',
  'Snare': 'Caisse claire',
  'A noise burst with the wires rattling under it.':
      'Une bouffée de bruit avec les câbles qui vibrent dessous.',
  'Cymbal': 'Cymbale',
  'Bright and long, the one that disappears least.':
      'Clair et long, celui qui disparaît le moins.',
  'Clap': 'Clap',
  'Three hand claps, warm enough to keep time with.':
      'Trois claps de mains, assez chauds pour tenir la mesure.',
  'Cowbell': 'Cowbell',
  'Two pitches at once, the sharpest of the set.':
      'Deux hauteurs à la fois, le plus mordant du lot.',
};
