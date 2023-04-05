import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:tflite/tflite.dart';

class ImagePickerApp extends StatefulWidget {
  const   ImagePickerApp({super.key});

  @override
  _ImagePickerAppState createState() => _ImagePickerAppState();
}

class _ImagePickerAppState extends State<ImagePickerApp> {
  File? _image;
  double confidence = 0.0;
  String output = '';

  @override
  void initState() {
    super.initState();
    loadmodel();
  }

  Future getImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;

      // final imageTemporary = File(image.path);
      final imagePermanent = await saveFilePermanently(image.path);

      setState(() {
        this._image = imagePermanent;
        runModel();
      });
    } on PlatformException catch (e) {
      print('Failed tp pick image: $e');
    }
  }

  Future<File> saveFilePermanently(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = basename(imagePath);
    final image = File('${directory.path}/$name');

    return File(imagePath).copy(image.path);
  }

  runModel() async {
    if (_image != null) {
      var predictions = await Tflite.runModelOnImage(
        path: _image!.path,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 2,
        threshold: 0.1,
      );
      // var predictions = await Tflite.runModelOnFrame(
      //     bytesList: imagepred.planes.map((Plane) {
      //       return Plane.bytes;
      //     }).toList(),
      //     // imageHeight: _image!.height,
      //     // imageWidth: _image!.width,
      //     imageMean: 127.5,
      //     imageStd: 127.5,
      //     rotation: 90,
      //     numResults: 2,
      //     threshold: 0.1,
      //     asynch: true);
      print("yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy");
      print(predictions);
      print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
      predictions!.forEach((element) {
        setState(() {
          output = element['label'];
          confidence = element['confidence'] * 100;
        });
      });
    }
  }

  loadmodel() async {
    String res;
    res = (await Tflite.loadModel(
        model: "assets/model_unquant.tflite", labels: "assets/labels.txt"))!;
    print("Models loading status: $res");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pick img"),
      ),
      body: Center(
          child: Column(
        children: [
          SizedBox(
            height: 40,
          ),
          _image != null
              ? Image.file(
                  _image!,
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                )
              : Image.network('src'),
          SizedBox(
            height: 40,
          ),
          Text(
            output,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text(
            confidence.toStringAsFixed(2)+"%",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          CustomButton(
            title: 'Pick from Gallery',
            icon: Icons.image_outlined,
            onClick: () => getImage(ImageSource.gallery),
          ),
          CustomButton(
            title: 'Pick from Camera',
            icon: Icons.camera,
            onClick: () => getImage(ImageSource.camera),
          ),
        ],
      )),
    );
  }
}

Widget CustomButton({
  required String title,
  required IconData icon,
  required VoidCallback onClick,
}) {
  return Container(
    width: 280,
    child: ElevatedButton(
        onPressed: onClick,
        child: Row(
          children: [Icon(icon), Text(title)],
        )),
  );
}
