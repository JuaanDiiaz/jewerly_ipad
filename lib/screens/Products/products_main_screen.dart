import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:p_a_jewerly/components/bottom_bar_screen.dart';

class ProductsMainScreen extends StatefulWidget {
  const ProductsMainScreen({super.key});

  @override
  State<ProductsMainScreen> createState() => _ProductsMainScreenState();
}

class _ProductsMainScreenState extends State<ProductsMainScreen> {
  Flutter3DController controller = Flutter3DController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    controller.onModelLoaded.addListener(() {
      print('model is loaded : ${controller.onModelLoaded.value}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomBarScreen(
      body: Center(
        child: _ModelThreeD(controller: controller),
      ), 
      actionWidget: CreateProduct()
    );
  }
}

class _ModelThreeD extends StatelessWidget {
  const _ModelThreeD({
    super.key,
    required this.controller,
  });

  final Flutter3DController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
            color: Colors.white,
            height: 300,
            width: double.infinity,
            child: //The 3D viewer widget for glb and gltf format
             Flutter3DViewer(
                //If you pass 'true' the flutter_3d_controller will add gesture interceptor layer
                //to prevent gesture recognizers from malfunctioning on iOS and some Android devices.
                //the default value is true
                activeGestureInterceptor: true,
                //If you don't pass progressBarColor, the color of defaultLoadingProgressBar will be grey.
                //You can set your custom color or use [Colors.transparent] for hiding loadingProgressBar.
                progressBarColor: Colors.orange,
                //You can disable viewer touch response by setting 'enableTouch' to 'false'
                enableTouch: true,
                //This callBack will return the loading progress value between 0 and 1.0
                onProgress: (double progressValue) {
                  print('model loading progress : $progressValue');
                },
                //This callBack will call after model loaded successfully and will return model address
                onLoad: (String modelAddress) {
                  print('model loaded : $modelAddress');
                },
                //this callBack will call when model failed to load and will return failure error
                onError: (String error) {
                  print('model failed to load : $error');
                },
                //You can have full control of 3d model animations, textures and camera
                controller: controller,
                src: 'assets/ring.glb', //3D model with different animations
                //src: 'assets/sheen_chair.glb', //3D model with different textures
                //src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb', // 3D model from URL
            ),
          );
  }
}

class CreateProduct extends StatefulWidget {
  CreateProduct({super.key});

  @override
  State<CreateProduct> createState() => _CreateProductState();
}

class _CreateProductState extends State<CreateProduct> {
  final _scrollcontroller = ScrollController();
  List<String> categories = [
    'Technology', 'Health', 'Education', 'Business', 'Sports', 'Music', 'Fashion',
    'Travel', 'Food', 'Entertainment', 'Science', 'Politics', 'Lifestyle'
  ];

  Set<String> selectedCategories = {};

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      controller: _scrollcontroller,
      child: Container(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text('Create a new Product'),
            SizedBox(height: 10),
            Container(
              width: size.width * .5,
              child: _ProductInput(label: 'Name'),
            ),
            SizedBox(height: 10),
            Text(
              'Select Categories:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: Wrap(
                spacing: 8, // Espacio entre chips horizontalmente
                runSpacing: 8, // Espacio entre chips verticalmente
                children: categories.map((category) {
                  return ChoiceChip(
                    label: Text(category),
                    selected: selectedCategories.contains(category),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedCategories.add(category);
                          // Después de agregar un chip, desplazamos hacia abajo
                          Future.delayed(Duration(milliseconds: 100), () {
                            _scrollcontroller.animateTo(
                              _scrollcontroller.position.maxScrollExtent, 
                              duration: Duration(seconds: 1), 
                              curve: Curves.easeOut,
                            );
                          });
                        } else {
                          selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Selected Categories:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: selectedCategories.map((category) {
                return Chip(
                  label: Text(category),
                  backgroundColor: Colors.blueAccent,
                  labelStyle: TextStyle(color: Colors.white),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductInput extends StatelessWidget {
  const _ProductInput({
    super.key, required this.label,
  });
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autocorrect: false,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}
