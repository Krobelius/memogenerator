import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/blocs/create_meme_bloc.dart';
import 'package:memogenerator/pages/meme_text.dart';
import 'package:memogenerator/pages/meme_text_with_selection.dart';
import 'package:memogenerator/blocs/main_bloc.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class CreateMemePage extends StatefulWidget {
  const CreateMemePage({Key? key}) : super(key: key);

  @override
  State<CreateMemePage> createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  late CreateMemeBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.lemon,
            centerTitle: true,
            foregroundColor: AppColors.darkGrey,
            title: const Text("Создаем мем"),
            bottom: EditTextBar(),
          ),
          body: const SafeArea(
            child: CreateMemePageContent(),
          )),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class EditTextBar extends StatefulWidget implements PreferredSizeWidget {
  const EditTextBar({Key? key}) : super(key: key);

  @override
  State<EditTextBar> createState() => _EditTextBarState();

  @override
  Size get preferredSize => const Size.fromHeight(68);
}

class _EditTextBarState extends State<EditTextBar> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: StreamBuilder<MemeText?>(
          stream: bloc.observeSelectedMemeText(),
          builder: (context, snapshot) {
            final MemeText? selectedMemeText =
                snapshot.hasData ? snapshot.data : null;
            if (selectedMemeText?.text != controller.text) {
              final newText = selectedMemeText?.text ?? "";
              controller.text = newText;
              controller.selection =
                  TextSelection.collapsed(offset: newText.length);
            }
            return TextField(
                enabled: selectedMemeText != null,
                controller: controller,
                onChanged: (text) {
                  if (selectedMemeText != null) {
                    bloc.changeMemeText(selectedMemeText.id, text);
                  }
                },
                cursorColor:
                    (selectedMemeText != null) ? AppColors.fuchsia : null,
                onEditingComplete: () => bloc.deselectMemeText(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: selectedMemeText != null
                      ? AppColors.fuchsia16
                      : AppColors.darkGray6,
                  disabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.darkGray38, width: 1)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.fuchsia38, width: 1)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.fuchsia, width: 2)),
                  hintText: (controller.text.isEmpty &&
                          selectedMemeText != null &&
                          selectedMemeText.text.isEmpty)
                      ? "Ввести текст"
                      : null,
                  hintStyle:
                      TextStyle(fontSize: 16, color: AppColors.darkGray38),
                ));
          }),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class CreateMemePageContent extends StatefulWidget {
  const CreateMemePageContent({Key? key}) : super(key: key);

  @override
  State<CreateMemePageContent> createState() => _CreateMemePageContentState();
}

class _CreateMemePageContentState extends State<CreateMemePageContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const MemeCanvasWidget(),
        Container(
          height: 1,
          color: AppColors.darkGrey,
        ),
        Expanded(
          child: BottomList(),
          flex: 1,
        )
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class BottomList extends StatelessWidget {
  const BottomList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      color: Colors.white,
      child: StreamBuilder<List<MemeTextWithSelection>>(
          stream: bloc.observeMemeTextWithSelection(),
          builder: (context, snapshot) {
            final memeTextList =
                snapshot.hasData ? snapshot.data! : <MemeTextWithSelection>[];
            return ListView.separated(
              itemCount: memeTextList.length + 1,
              separatorBuilder: (BuildContext context, int index) {
                return index == 0 ? SizedBox.shrink() : BottomSeparator();
              },
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 12,
                      ),
                      AddNewMemeTextButton()
                    ],
                  );
                } else {
                  final memeText = memeTextList[index - 1];
                  return ListTileText(memeText: memeText);
                }
              },
            );
          }),
    );
  }
}

class BottomSeparator extends StatelessWidget {
  const BottomSeparator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.darkGrey,
      margin: EdgeInsets.only(left: 16),
    );
  }
}

class ListTileText extends StatelessWidget {
  final MemeTextWithSelection memeText;

  const ListTileText({Key? key, required this.memeText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      color: (memeText.selected) ? AppColors.darkGray16 : null,
      alignment: Alignment.centerLeft,
      child: Text(
        memeText.memeText.text,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.darkGrey),
      ),
    );
  }
}

class MemeCanvasWidget extends StatelessWidget {
  const MemeCanvasWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Expanded(
      child: Container(
        color: AppColors.darkGray38,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.topCenter,
        child: AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: () => bloc.deselectMemeText(),
              child: Container(
                color: Colors.white,
                child: StreamBuilder<List<MemeText>>(
                    initialData: const <MemeText>[],
                    stream: bloc.observeMemeTexts(),
                    builder: (context, snapshot) {
                      final memeTexts = snapshot.hasData
                          ? snapshot.data!
                          : const <MemeText>[];
                      return LayoutBuilder(builder: (context, constraints) {
                        return Stack(
                          children: memeTexts.map((memeText) {
                            return DraggableMemeText(
                              memeText: memeText,
                              parentConstraints: constraints,
                            );
                          }).toList(),
                        );
                      });
                    }),
              ),
            )),
      ),
      flex: 2,
    );
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeText memeText;
  final BoxConstraints parentConstraints;

  const DraggableMemeText(
      {Key? key, required this.memeText, required this.parentConstraints})
      : super(key: key);

  @override
  State<DraggableMemeText> createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText> {
  late double top;
  late double left;
  final double padding = 8;

  @override
  void initState() {
    top = widget.parentConstraints.maxHeight / 2;
    left = widget.parentConstraints.maxWidth / 3;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    bool decor = false;
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => bloc.selectMemeText(widget.memeText.id),
        onPanUpdate: (details) {
          bloc.selectMemeText(widget.memeText.id);
          setState(() {
            left = calculateLeft(details);
            top = calculateRight(details);
          });
        },
        child: StreamBuilder<MemeText?>(
            stream: bloc.observeSelectedMemeText(),
            builder: (context, snapshot) {
              final selectedText = snapshot.hasData ? snapshot.data! : null;
              decor = selectedText?.id == widget.memeText.id;
              return MemeTextOnCanvas(
                padding: padding,
                decor: decor,
                parentConstraints: widget.parentConstraints,
                memeText: widget.memeText,
              );
            }),
      ),
    );
  }

  double calculateRight(DragUpdateDetails details) {
    final rawTop = top + details.delta.dy;
    if (rawTop < 0) return 0;
    if (rawTop > widget.parentConstraints.maxHeight - padding * 2 - 30)
      return widget.parentConstraints.maxHeight - padding * 2 - 30;
    return rawTop;
  }

  double calculateLeft(DragUpdateDetails details) {
    final rawLeft = left + details.delta.dx;
    if (rawLeft < 0) {
      return 0;
    }
    if (rawLeft > widget.parentConstraints.maxWidth - padding * 2 - 10)
      return widget.parentConstraints.maxWidth - padding * 2 - 10;
    return rawLeft;
  }
}

class MemeTextOnCanvas extends StatelessWidget {
  const MemeTextOnCanvas({
    Key? key,
    required this.decor,
    required this.padding,
    required this.parentConstraints,
    required this.memeText,
  }) : super(key: key);

  final bool decor;
  final double padding;
  final BoxConstraints parentConstraints;
  final MemeText memeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: decor ? AppColors.darkGray16 : null,
          border: Border.all(
              color: decor ? AppColors.fuchsia : Colors.transparent, width: 1)),
      constraints: BoxConstraints(
        maxWidth: parentConstraints.maxWidth,
        maxHeight: parentConstraints.maxHeight,
      ),
      padding: EdgeInsets.all(padding),
      child: Text(
        memeText.text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black, fontSize: 24),
      ),
    );
  }
}

class AddNewMemeTextButton extends StatelessWidget {
  const AddNewMemeTextButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return GestureDetector(
      onTap: () => bloc.addNewText(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.add,
                color: AppColors.fuchsia,
              ),
              SizedBox(
                width: 8,
              ),
              Text(
                "ДОБАВИТЬ ТЕКСТ",
                style: TextStyle(
                    color: AppColors.fuchsia,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      ),
    );
  }
}
