import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'dart:typed_data';
import 'package:rive/rive.dart';
import 'package:rive/src/rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive/src/generated/shapes/paint/gradient_stop_base.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rive color',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Trocador de cores Rive'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class SelfAwareSolidColor extends SolidColor {
  SelfAwareSolidColor(this.colorMapper);
  final int Function(int) colorMapper;

  @override
  set colorValue(int value) {
    super.colorValue = colorMapper(value);
  }
}

class SelfAwareGradientStop extends GradientStop {
  SelfAwareGradientStop(this.colorMapper);
  final int Function(int) colorMapper;

  @override
  set colorValue(int value) {
    super.colorValue = colorMapper(value);
  }
}

class _MyHomePageState extends State<MyHomePage> {
  FilePickerResult? result;
  Map<int, int> colors = {};

  void selectFile() {
    FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['riv'])
        .then((value) {
          setState(() {
            result = value;
            colors.clear();
          });
        });
  }

  @override
  void initState() {
    super.initState();
    RiveFile.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Row(
        children: [
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (result != null)
                  SizedBox(
                    height: 300,
                    child: RiveAnimation.direct(
                      RiveFile.import(
                        ByteData.sublistView((result!.files.first.bytes!)),
                        objectGenerator: (coreTypeKey) {
                          if (coreTypeKey == SolidColorBase.typeKey ||
                              coreTypeKey == GradientStopBase.typeKey) {
                            return (coreTypeKey == SolidColorBase.typeKey
                                ? SelfAwareSolidColor.new
                                : SelfAwareGradientStop.new)((value) {
                              if (colors.containsKey(value)) {
                                return colors[value]!;
                              }
                              setState(() {
                                colors[value] = value;
                              });
                              return value;
                            });
                          }
                          return null;
                        },
                      ),

                      fit: BoxFit.contain,
                    ),
                  ),
                Text(
                  result != null
                      ? result!.files.first.name
                      : 'Selecione um arquivo Rive',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          Flexible(
            child: Column(
              children: [
                for (final e in colors.entries)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Cor: '),
                      Icon(Icons.square, color: Color(e.key)),
                      const Text(' -> '),
                      Icon(Icons.square, color: Color(e.value)),
                      const SizedBox(width: 10),
                      IconButton(
                        color: Color(e.value),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (ctx) => Dialog(
                                  child: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: Color(e.value),
                                      onColorChanged: (c) {
                                        setState(() {
                                          colors[e.key] = c.toARGB32();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      const SizedBox(width: 10),
                      if (e.key != e.value)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              colors[e.key] = e.key;
                            });
                          },
                          icon: Icon(Icons.undo, color: Color(e.key)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: selectFile,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
