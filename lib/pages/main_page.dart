import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/blocs/main_bloc.dart';
import 'package:memogenerator/pages/create_meme_page.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateMemePage()))
            },
            backgroundColor: AppColors.fuchsia,
            label: const Text("Добавить"),
            icon: const Icon(Icons.add),
          ),
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.lemon,
            centerTitle: true,
            foregroundColor: AppColors.darkGrey,
            title: Text("Мемогенератор",
                style: GoogleFonts.seymourOne(fontSize: 24)),
          ),
          body: const SafeArea(
            child: MainPageContent(),
          )),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContent extends StatefulWidget {
  const MainPageContent({Key? key}) : super(key: key);

  @override
  State<MainPageContent> createState() => _MainPageContentState();
}

class _MainPageContentState extends State<MainPageContent> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
