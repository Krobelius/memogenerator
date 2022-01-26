import 'dart:convert';

import 'package:http/http.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/shared_preferences_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

class MemesRepository {
  final updater = PublishSubject<Null>();
  final SharedPreferencesData spData;

  static MemesRepository? _instance;

  factory MemesRepository.getInstance() => _instance ??=
      MemesRepository._internal(SharedPreferencesData.getInstance());

  MemesRepository._internal(this.spData);

  Future<bool> addMeme(final Meme meme) async {
    final rawMemes = await getMemes();
    final existMemes = rawMemes.firstWhereOrNull((exMeme) => meme.id == exMeme.id);
    if(existMemes != null) {
      final rawIndex = rawMemes.indexWhere((element) => element.id == existMemes.id);
      rawMemes[rawIndex] = meme;
    } else {
      rawMemes.add(meme);
    }
    return _setMemes(rawMemes);
  }


  Future<List<Meme>> getMemes() async {
    final rawMemes = await spData.getMemes();
    return rawMemes.map((meme) => Meme.fromJson(json.decode(meme))).toList();
  }



  Future<bool> removeFromMemes(final String id) async {
    final memes = await getMemes();
    memes.removeWhere((meme) => meme.id == id);
    return _setMemes(memes);
  }


  Future<Meme?> getMeme(final String id) async {
    final memes = await getMemes();
    return memes.firstWhereOrNull((meme) => meme.id == id);
  }

  Stream<List<Meme>> observeMemes() async* {
    yield await getMemes();
    await for (final _ in updater) {
      yield await getMemes();
    }
  }

  Future<bool> _setMemes(final List<Meme> memes) async {
    final rawMemes = memes.map((meme) => json.encode(meme.toJson())).toList();
    return _setRawMemes(rawMemes);
  }

  Future<bool> _setRawMemes(final List<String> memes) {
    updater.add(null);
    return spData.setMemes(memes);
  }




}
