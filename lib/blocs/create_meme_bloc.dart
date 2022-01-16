import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class CreateMemeBloc {
  final memeTextSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);


  void addNewText() {
    final newMemeText = MemeText.create();
    memeTextSubject.add([...memeTextSubject.value,newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
  }

  void selectMemeText(final String id) {
    final foundMemeText = memeTextSubject.value.firstWhereOrNull((memeText) => memeText.id == id);
    selectedMemeTextSubject.add(foundMemeText);
  }

  void changeMemeText(final String id, final String text) {
    final copiedList = [...memeTextSubject.value];
    final index = copiedList.indexWhere((memeText) => memeText.id == id);
    if(index == -1) return;
    copiedList.removeAt(index);
    copiedList.insert(index,MemeText(id: id, text: text));
    memeTextSubject.add(copiedList);
  }

  void deselectMemeText(){
    selectedMemeTextSubject.add(null);
  }

  Stream<List<MemeText>> observeMemeTexts() => memeTextSubject.distinct((prev,next) => ListEquality().equals(prev, next));
  Stream<MemeText?> observeSelectedMemeText() => selectedMemeTextSubject.distinct();

  void dispose() {
    memeTextSubject.close();
    selectedMemeTextSubject.close();

  }
}

class MemeText {
  final String id;
  final String text;

  MemeText({required this.id, required this.text});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemeText &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text;

  @override
  int get hashCode => id.hashCode ^ text.hashCode;

  factory MemeText.create() {
    return MemeText(id: Uuid().v4(), text: "");
  }

  @override
  String toString() {
    return 'MemeText{id: $id, text: $text}';
  }
}
