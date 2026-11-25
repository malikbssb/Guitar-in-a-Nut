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
  'The French side is a machine pass nobody has proofread. Wordings can be '
          'off, so English stays the recommended language.':
      'Le français est une passe automatique que personne n\'a relue. Les '
      'formulations peuvent sonner bizarre, l\'anglais reste la langue '
      'recommandée.',

  // One line under the top bar, per section.
  'Enable your microphone, pluck a string and get to tuning!':
      'Active ton micro, pince une corde et accorde-toi !',
  '{n} shapes, sorted by the key they fit in.':
      '{n} formes, classées par la tonalité où elles tiennent.',
  'Every note of the neck, one tap away.':
      'Toutes les notes du manche, à un tap.',
  'Short pages that answer the questions beginners ask.':
      'Des pages courtes qui répondent aux questions des débutants.',
  'Questions drawn from a pool of {n}. Pick the level and the length.':
      'Des questions tirées d\'un bassin de {n}. Choisis le niveau et la '
      'longueur.',
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
  'Start here': 'Commencez ici',
  'The pages, in order': 'Les pages, dans l\'ordre',
  'Open the plan': 'Ouvrir le plan',

  // Written quiz.
  'A different quiz every time': 'Un quiz différent à chaque fois',
  'The app builds {n} questions at this level from the diagrams, the tunings '
          'and the key groups on these pages, then draws a fresh set. Nothing '
          'repeats in the same order.':
      'L\'app fabrique {n} questions à ce niveau à partir des diagrammes, des '
      'accordages et des tonalités de ces pages, puis tire un nouvel '
      'ensemble. Rien ne se répète dans le même ordre.',
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
  '{n} sounds from {m}, so they come back':
      '{n} sons pour un lot de {m}, donc ils reviennent',
  'Nothing at this level': 'Rien à ce niveau',
  'How many sounds?': 'Combien de sons ?',

  // Difficulty levels, shared by both quizzes.
  'How hard?': 'Niveau ?',
  'Easy': 'Facile',
  'Medium': 'Moyen',
  'Hard': 'Difficile',
  'Expert': 'Expert',
  'Open strings, the first chord shapes and the notes you already met.':
      'Cordes à vide, les premières formes d\'accord et les notes que tu as '
      'déjà croisées.',
  'Intervals, tunings, keys and the neck up to the 12th fret.':
      'Intervalles, accordages, tonalités et le manche jusqu\'à la 12e case.',
  'The whole site, including the borrowed and extended shapes.':
      'Tout le site, y compris les formes empruntées et enrichies.',
  'No options to fall back on. Type what you hear or read.':
      'Plus d\'options sur lesquelles s\'appuyer. Écris ce que tu entends ou '
      'ce que tu lis.',
  'Type your answer': 'Écris ta réponse',
  'a note, a chord, an interval': 'une note, un accord, un intervalle',
  'Check that answer': 'Vérifier',
  'You wrote {a}': 'Tu as écrit {a}',

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
  'Stress the first beat': 'Souligner le premier temps',
  'Beat one sounds louder and a touch higher, so the bar counts itself.':
      'Le premier temps sonne plus fort et un peu plus aigu : la mesure se '
      'compte toute seule.',
  'Every beat sounds the same.': 'Tous les temps sonnent pareil.',
  'How many bars?': 'Combien de mesures ?',
  'Forever': 'Sans fin',
  '{n} bars': '{n} mesures',
  '{n} bar': '{n} mesure',
  'Click sound': 'Son du clic',
  'Hear this sound': 'Écouter ce son',
  'Stick': 'Bois',
  'A short wood block tick, the classic metronome sound.':
      'Un tick de bois court, le clic de métronome classique.',
  'Kick': 'Grosse caisse',
  'A low thump you feel more than hear, soft on the ear.':
      'Un coup grave qu\'on sent plus qu\'on entend, doux à l\'oreille.',
  'Snare': 'Caisse claire',
  'A real snare hit, dry and short enough to sit on the beat.':
      'Une vraie caisse claire, assez sèche et courte pour poser le temps.',
  'Tom': 'Tom',
  'A round, deep drum note with a pitch you can hum back.':
      'Une note de tambour ronde et profonde, assez pitchée pour la chanter.',
  'Cymbal': 'Cymbale',
  'A ride cymbal: the ping rings on past the beat.':
      'Une cymbale ride : le ping continue bien après le temps.',
  'Bell': 'Cloche',
  'The bell of a cymbal: a thin, bright ping that cuts through.':
      'La cloche de la cymbale : un ping fin et clair qui perce.',
  'Clap': 'Clap',
  'One hand clap, warm enough to keep time with.':
      'Un seul clap de mains, assez chaud pour tenir la mesure.',
  'Cowbell': 'Cowbell',
  'Two pitches at once, the sharpest of the set.':
      'Deux hauteurs à la fois, le plus mordant du lot.',
  'Closed Hi-hat': 'Charley fermé',
  'The hats snapped together: a tight hiss that fills the gap between beats.': 'Les charleys claquent ensemble : un sifflement serré qui remplit le vide entre les temps.',
  'Semi-closed Hi-hat': 'Charley mi-fermé',
  'The tightest hat of the three, almost all attack and no ring at all.': 'Le plus serré des trois : presque uniquement l\'attaque, sans tintement.',
  'Open Hi-hat': 'Charley ouvert',
  'The hats left apart: a long, hissy wash that rings past the beat.': 'Les charleys restent écartés : une longue trainée sifflante qui résonne après le temps.',

  // Drum machine.
  'DRUM MACHINE': 'BOÎTE À RYTHMES',
  'Drum machine': 'Boîte à rythmes',
  'Build a bar of drums, one step at a time.':
      'Construis une mesure de batterie, pas à pas.',
  'Tap a cell to put a drum on that step.':
      'Touche une case pour poser une batterie sur ce pas.',
  'Start from': 'Partir de',
  'Clear': 'Vider',
  'Play': 'Lancer',
  'Four cells to a beat, sixteen to a bar.':
      'Quatre cases par temps, seize par mesure.',
  'Rock beat': 'Battement rock',
  'Four on the floor': 'Quatre temps au sol',
  'Funk': 'Funk',

  // The from-scratch lesson inside LEARN.
  'Four things, and they come in this order. You do not need all of them at '
          'once: each one has a page in this app, and the link under every '
          'step takes you there.':
      'Quatre choses, dans cet ordre. Pas besoin de tout en même temps : '
      'chacune a sa page dans l\'appli, et le lien sous chaque étape y '
      'conduit.',
  'Four or five chord shapes': 'Quatre ou cinq formes d\'accord',
  'C, G, D, A, E, Am and Em cover thousands of songs. Learn the shapes, then '
          'learn to move between two of them without stopping. A chord is '
          'only useful once your hand finds it without looking.':
      'C, G, D, A, E, Am et Em couvrent des milliers de chansons. Apprends '
      'les formes, puis apprends à passer de l\'une à l\'autre sans t\'arrêter. '
      'Un accord ne sert à rien tant que ta main ne le trouve sans regarder.',
  'Open the chord shapes': 'Ouvrir les formes d\'accord',
  'What is a chord?': 'C\'est quoi un accord ?',
  'Finger independence and dexterity': 'Indépendance et agilité des doigts',
  'The fingers do not obey yet, and that is normal. Slow, clean repetition is '
          'the only training: one note per string, each note heard clearly, '
          'hands relaxed. Speed is a side effect of accuracy, never the other '
          'way round.':
      'Les doigts n\'obéissent pas encore, c\'est normal. La répétition lente '
      'et propre est le seul entraînement : une note par corde, chaque note '
      'bien entendue, mains détendues. La vitesse est un effet de la '
      'précision, jamais l\'inverse.',
  'Walk the notes on the neck': 'Parcourir les notes du manche',
  'How to read tabs': 'Comment lire une tablature',
  'A few basic scales': 'Quelques gammes de base',
  'Minor pentatonic first, then the major scale. A scale is one shape you can '
          'slide anywhere on the neck, and it is what solos, riffs and '
          'single-note lines are cut from.':
      'La pentatonique mineure d\'abord, puis la gamme majeure. Une gamme '
      'est une forme qu\'on peut glisser partout sur le manche, et c\'est là '
      'qu\'on découpe les solos, les riffs et les lignes de notes seules.',
  'Hear every scale': 'Écouter toutes les gammes',
  'What is a scale?': 'C\'est quoi une gamme ?',
  'Light up a scale on the neck': 'Éclairer une gamme sur le manche',
  'Rhythm, with a metronome': 'Le rythme, avec un métronome',
  'Strumming patterns, down-strokes on the beats and a count out loud. Then '
          'play against a click: it is the only honest way to hear whether '
          'you are actually together with the beat.':
      'Des motifs de grattage, des coups vers le bas sur les temps et un '
      'comptage à voix haute. Puis jouer avec un clic : c\'est le seul moyen '
      'honnête d\'entendre si tu es vraiment collé au tempo.',
  'Strumming and arpeggios': 'Grattage et arpèges',
  'What are time signatures?': 'C\'est quoi une mesure ?',
  'How to use a metronome': 'Comment utiliser un métronome',
  'Open the metronome': 'Ouvrir le métronome',
  'Then check what stuck': 'Puis vérifier ce qui est resté',
  'The written quiz asks about shapes, notes and tunings. The ear training '
          'asks about sounds. Start on Easy, and move up when the answers '
          'stop surprising you.':
      'Le quiz écrit interroge sur les formes, les notes et les accordages. '
      'L\'entraînement de l\'oreille interroge sur les sons. Commence en '
      'Facile, et monte quand les réponses ne te surprennent plus.',
  'Take the quiz': 'Faire le quiz',
  'Train your ears': 'Entraîner tes oreilles',
};
