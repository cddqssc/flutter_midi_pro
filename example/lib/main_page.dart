import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_piano_pro/flutter_piano_pro.dart';
import 'package:flutter_piano_pro/note_model.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final MidiPro midiPro = MidiPro();
  ValueNotifier<bool> isInstrumentLoaded = ValueNotifier<bool>(false);
  final Map<int, String> loadedSoundfonts = {};
  final instrumentIndex = ValueNotifier<int>(0);
  final bankIndex = ValueNotifier<int>(0);
  final channelIndex = ValueNotifier<int>(0);
  final volume = ValueNotifier<int>(127);
  Map<int, NoteModel> pointerAndNote = {};

  @override
  void initState() {
    midiPro.init().catchError((e) {
      debugPrint(e.toString());
    });
    super.initState();
  }

  /// Loads a soundfont file from the specified path.
  /// Returns the soundfont ID.
  Future<int> loadSoundfont(String path) async {
    if (loadedSoundfonts.containsValue(path)) {
      return loadedSoundfonts.entries.firstWhere((element) => element.value == path).key;
    }
    final int sfId = await midiPro.loadSoundfont(path);
    loadedSoundfonts[sfId] = path;
    isInstrumentLoaded.value = true;
    return sfId;
  }

  /// Selects an instrument on the specified soundfont.
  Future<void> selectInstrument({
    required int sfId,
    required int program,
    int channel = 0,
    int bank = 0,
  }) async {
    int? sfIdValue = sfId;
    if (!loadedSoundfonts.containsKey(sfId)) {
      sfIdValue = loadedSoundfonts.keys.first;
    }
    await midiPro.selectInstrument(sfId: sfIdValue, channel: channel, bank: bank, program: program);
  }

  /// Plays a note on the specified channel.
  Future<void> playNote({
    required int key,
    required int velocity,
    int channel = 0,
    int sfId = 1,
  }) async {
    int? sfIdValue = sfId;
    if (!loadedSoundfonts.containsKey(sfId)) {
      sfIdValue = loadedSoundfonts.keys.first;
    }
    await midiPro.playNote(channel: channel, key: key, velocity: velocity, sfId: sfIdValue);
  }

  /// Stops a note on the specified channel.
  Future<void> stopNote({
    required int key,
    int channel = 0,
    int sfId = 1,
  }) async {
    int? sfIdValue = sfId;
    if (!loadedSoundfonts.containsKey(sfId)) {
      sfIdValue = loadedSoundfonts.keys.first;
    }
    await midiPro.stopNote(channel: channel, key: key, sfId: sfIdValue);
  }

  /// Unloads a soundfont file.
  Future<void> unloadSoundfont(int sfId) async {
    await midiPro.unloadSoundfont(sfId);
    loadedSoundfonts.remove(sfId);
    isInstrumentLoaded.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Midi Pro Example'),
      ),
      body: SingleChildScrollView(
        child: Center(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
                onPressed: () => loadSoundfont('assets/TimGM6mb.sf2'),
                child: const Text(
                  'Load Soundfont file\nMust be called before other methods',
                  textAlign: TextAlign.center,
                )),
            const SizedBox(
              height: 10,
            ),
            ValueListenableBuilder(
                valueListenable: isInstrumentLoaded,
                builder: (context, isMidiInitializedValue, child) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ValueListenableBuilder(
                              valueListenable: bankIndex,
                              builder: (context, bankIndexValue, child) {
                                return DropdownButton<int>(
                                    value: bankIndexValue,
                                    items: [
                                      for (int i = 0; i < 128; i++)
                                        DropdownMenuItem<int>(
                                          value: i,
                                          child: Text(
                                            'Bank $i',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        )
                                    ],
                                    onChanged: (int? value) {
                                      if (value != null) {
                                        bankIndex.value = value;
                                      }
                                    });
                              }),
                          ValueListenableBuilder(
                              valueListenable: instrumentIndex,
                              builder: (context, channelValue, child) {
                                return DropdownButton<int>(
                                    value: channelValue,
                                    items: [
                                      for (int i = 0; i < 128; i++)
                                        DropdownMenuItem<int>(
                                          value: i,
                                          child: Text(
                                            'Instrument $i',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        )
                                    ],
                                    onChanged: (int? value) {
                                      if (value != null) {
                                        instrumentIndex.value = value;
                                      }
                                    });
                              }),
                          ValueListenableBuilder(
                              valueListenable: channelIndex,
                              builder: (context, channelIndexValue, child) {
                                return DropdownButton<int>(
                                    value: channelIndexValue,
                                    items: [
                                      for (int i = 0; i < 16; i++)
                                        DropdownMenuItem<int>(
                                          value: i,
                                          child: Text(
                                            'Channel $i',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        )
                                    ],
                                    onChanged: (int? value) {
                                      if (value != null) {
                                        channelIndex.value = value;
                                      }
                                    });
                              }),
                        ],
                      ),
                      ValueListenableBuilder(
                          valueListenable: bankIndex,
                          builder: (context, bankIndexValue, child) {
                            return ValueListenableBuilder(
                                valueListenable: channelIndex,
                                builder: (context, channelIndexValue, child) {
                                  return ValueListenableBuilder(
                                      valueListenable: instrumentIndex,
                                      builder: (context, instrumentIndexValue, child) {
                                        return ElevatedButton(
                                            onPressed: isMidiInitializedValue
                                                ? () => selectInstrument(
                                                      sfId: loadedSoundfonts.keys.first,
                                                      program: instrumentIndexValue,
                                                      bank: bankIndexValue,
                                                      channel: channelIndexValue,
                                                    )
                                                : null,
                                            child: Text(
                                                'Load Instrument $instrumentIndexValue on Bank $bankIndexValue to Channel $channelIndexValue'));
                                      });
                                });
                          }),
                      Padding(
                          padding: const EdgeInsets.all(18),
                          child: ValueListenableBuilder(
                              valueListenable: volume,
                              child: const Text('Volume: '),
                              builder: (context, value, child) {
                                return Row(
                                  children: [
                                    child!,
                                    Expanded(
                                        child: Slider(
                                      value: value.toDouble(),
                                      min: 0,
                                      max: 127,
                                      onChanged: isMidiInitializedValue
                                          ? (value) => volume.value = value.toInt()
                                          : null,
                                    )),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text('${volume.value}'),
                                  ],
                                );
                              })),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: !isMidiInitializedValue
                              ? null
                              : () => unloadSoundfont(loadedSoundfonts.keys.first),
                          child: const Text('Unload Soundfont file'),
                        ),
                      ),
                      Stack(
                        children: [
                          PianoPro(
                            noteCount: 15,
                            onTapDown: (NoteModel? note, int tapId) {
                              if (note == null) return;
                              pointerAndNote[tapId] = note;
                              playNote(
                                  key: note.midiNoteNumber,
                                  velocity: volume.value,
                                  channel: channelIndex.value);
                              debugPrint(
                                  'DOWN: note= ${note.name + note.octave.toString() + (note.isFlat ? "♭" : '')}, tapId= $tapId');
                            },
                            onTapUpdate: (NoteModel? note, int tapId) {
                              if (note == null) return;
                              if (pointerAndNote[tapId] == note) return;
                              stopNote(
                                  key: pointerAndNote[tapId]!.midiNoteNumber,
                                  channel: channelIndex.value);
                              pointerAndNote[tapId] = note;
                              playNote(
                                  channel: channelIndex.value,
                                  key: note.midiNoteNumber,
                                  velocity: volume.value);
                              debugPrint(
                                  'UPDATE: note= ${note.name + note.octave.toString() + (note.isFlat ? "♭" : '')}, tapId= $tapId');
                            },
                            onTapUp: (int tapId) {
                              stopNote(
                                  key: pointerAndNote[tapId]!.midiNoteNumber,
                                  channel: channelIndex.value);
                              pointerAndNote.remove(tapId);
                              debugPrint('UP: tapId= $tapId');
                            },
                          ),
                          if (!isMidiInitializedValue)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.5),
                                child: const Center(
                                  child: Text(
                                    'Load Soundfont file\nMust be called before other methods',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                        ],
                      )
                    ],
                  );
                }),
          ],
        )),
      ),
    );
  }
}
