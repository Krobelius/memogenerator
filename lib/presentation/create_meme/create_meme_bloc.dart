import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class CreateMemeBloc {
  final memeTextSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);
  final memeTextOffsetsSubject =
      BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);
  final newMemeTextOffsetSubject =
      BehaviorSubject<MemeTextOffset?>.seeded(null);
  final memePathSubject = BehaviorSubject<String?>.seeded(null);

  StreamSubscription<MemeTextOffset?>? newMemeTextOffsetSubjectSubscription;
  StreamSubscription<bool>? saveMemeSubscription;
  StreamSubscription<Meme?>? existentMemeSubscription;

  final String id;

  CreateMemeBloc({final String? id, final String? selectedMemePath})
      : this.id = id ?? Uuid().v4() {
    memePathSubject.add(selectedMemePath);
    _subscribeToNewMemeTextOffset();

    _subscribeToExistent();
  }

  void _subscribeToExistent() {
    existentMemeSubscription = MemesRepository.getInstance()
        .getMeme(this.id)
        .asStream()
        .listen((meme) {
      if (meme == null) {
        return;
      }
      final memeTexts = meme.texts.map((textWithPosition) {
        return MemeText(id: textWithPosition.id, text: textWithPosition.text);
      }).toList();
      final memeTextOffsets = meme.texts.map((textWithPosition) {
        return MemeTextOffset(
          id: textWithPosition.id,
          offset: Offset(
              textWithPosition.position.left, textWithPosition.position.top),
        );
      }).toList();
      memeTextSubject.add(memeTexts.toList());
      memeTextOffsetsSubject.add(memeTextOffsets);
      memePathSubject.add(meme.memePath);
    });
  }

  void saveMeme() {
    final memeTexts = memeTextSubject.value;
    final memeTextOffsets = memeTextOffsetsSubject.value;

    final textsWithPosition = memeTexts.map((memeText) {
      final memeTextPosition =
          memeTextOffsets.firstWhereOrNull((memeTextOffset) {
        return memeTextOffset.id == memeText.id;
      });
      final position = Position(
          top: memeTextPosition?.offset.dy ?? 0,
          left: memeTextPosition?.offset.dx ?? 0);
      return TextWithPosition(
          id: memeText.id, text: memeText.text, position: position);
    }).toList();

    saveMemeSubscription =
        _saveMemeInternal(textsWithPosition).asStream().listen((event) {
      print("SAVED MEME $event");
    }, onError: (error, stack) => print('ERROR IN SAVE MEME $error $stack'));
  }

  Future<bool> _saveMemeInternal(
      final List<TextWithPosition> textWithPositions) async {
    final imagePath = memePathSubject.value;
    if (imagePath == null) {
      final meme = Meme(id: id, texts: textWithPositions);
      return MemesRepository.getInstance().addMemes(meme);
    } else {
      final docsPath = await getApplicationDocumentsDirectory();
      final memePath =
          "${docsPath.absolute.path}${Platform.pathSeparator}memes";
      await Directory(memePath).create(recursive: true);
      final imageName = imagePath.split(Platform.pathSeparator).last;
      final newImagePath = "$memePath${Platform.pathSeparator}${imageName}";
      final tempFile = File(imagePath);
      await tempFile.copy(newImagePath);
      final meme = Meme(id: id, texts: textWithPositions,memePath: newImagePath);
      return MemesRepository.getInstance().addMemes(meme);
    }
  }

  void _subscribeToNewMemeTextOffset() {
    newMemeTextOffsetSubjectSubscription = newMemeTextOffsetSubject
        .debounceTime(Duration(milliseconds: 300))
        .listen((newMemeTextOffset) {
      if (newMemeTextOffset != null) {
        _changeMemeTextOffsetInternal(newMemeTextOffset);
      }
    },
            onError: (error, stack) =>
                print('ERROR IN SUBSCR MEMETEXT $error $stack'));
  }

  void changeMemeTextOffset(final String id, final Offset offset) {
    newMemeTextOffsetSubject.add(MemeTextOffset(id: id, offset: offset));
  }

  void _changeMemeTextOffsetInternal(final MemeTextOffset newMemeTextOffset) {
    final copiedMemeTextOffsets = [...memeTextOffsetsSubject.value];

    final currentMemeTextOffset = copiedMemeTextOffsets.firstWhereOrNull(
        (memeTextOffset) => memeTextOffset.id == newMemeTextOffset.id);

    if (currentMemeTextOffset != null) {
      copiedMemeTextOffsets.remove(currentMemeTextOffset);
    }
    copiedMemeTextOffsets.add(newMemeTextOffset);
    memeTextOffsetsSubject.add(copiedMemeTextOffsets);
    print("Got new offfset : $newMemeTextOffset");
  }

  void addNewText() {
    final newMemeText = MemeText.create();
    memeTextSubject.add([...memeTextSubject.value, newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
  }

  void selectMemeText(final String id) {
    final foundMemeText =
        memeTextSubject.value.firstWhereOrNull((memeText) => memeText.id == id);
    selectedMemeTextSubject.add(foundMemeText);
  }

  void changeMemeText(final String id, final String text) {
    final copiedList = [...memeTextSubject.value];
    final index = copiedList.indexWhere((memeText) => memeText.id == id);
    if (index == -1) return;
    copiedList.removeAt(index);
    copiedList.insert(index, MemeText(id: id, text: text));
    memeTextSubject.add(copiedList);
  }

  void deselectMemeText() {
    selectedMemeTextSubject.add(null);
  }

  Stream<String?> observeMemePath() => memePathSubject.distinct();

  Stream<List<MemeText>> observeMemeTexts() => memeTextSubject
      .distinct((prev, next) => ListEquality().equals(prev, next));

  Stream<List<MemeTextWithOffset>> observeMemeTextWithOffset() {
    return Rx.combineLatest2<List<MemeText>, List<MemeTextOffset>,
            List<MemeTextWithOffset>>(
        observeMemeTexts(), memeTextOffsetsSubject.distinct(),
        (memeTexts, memeTextOffsets) {
      return memeTexts.map((memeText) {
        final offset = memeTextOffsets.firstWhereOrNull(
            (memeTextOffset) => memeTextOffset.id == memeText.id);
        return MemeTextWithOffset(
            id: memeText.id, text: memeText.text, offset: offset?.offset);
      }).toList();
    }).distinct((prev, next) => ListEquality().equals(prev, next));
  }

  Stream<MemeText?> observeSelectedMemeText() =>
      selectedMemeTextSubject.distinct();

  Stream<List<MemeTextWithSelection>> observeMemeTextWithSelection() =>
      Rx.combineLatest2<List<MemeText>, MemeText?, List<MemeTextWithSelection>>(
          observeMemeTexts(), observeSelectedMemeText(),
          (memeTexts, selectedMemeText) {
        return memeTexts.map((memeText) {
          return MemeTextWithSelection(
              memeText: memeText,
              selected: memeText.id == selectedMemeText?.id);
        }).toList();
      });

  void dispose() {
    memeTextSubject.close();
    memeTextOffsetsSubject.close();
    newMemeTextOffsetSubject.close();
    selectedMemeTextSubject.close();
    memePathSubject.close();
    saveMemeSubscription?.cancel();
    existentMemeSubscription?.cancel();
    newMemeTextOffsetSubjectSubscription?.cancel();
  }
}
