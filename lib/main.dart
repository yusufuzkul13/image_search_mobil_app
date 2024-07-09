import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'api_service.dart';
import 'package:crop_lib_dart/crop_your_image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Crop and Search Image Demo'),
        ),
        body: CropSample(),
      ),
    );
  }
}

class CropSample extends StatefulWidget {
  @override
  _CropSampleState createState() => _CropSampleState();
}

class _CropSampleState extends State<CropSample> {
  static const _images = [
    'assets/images/city.png',
    'assets/images/lake.png',
    'assets/images/train.png',
    'assets/images/turtois.png',
  ];

  final _cropController = CropController();
  final _imageDataList = <Uint8List>[];
  final ApiService _apiService = ApiService();

  var _loadingImage = false;
  var _currentImage = 0;
  set currentImage(int value) {
    setState(() {
      _currentImage = value;
    });
    _cropController.image = _imageDataList[_currentImage];
  }

  var _isSumbnail = false;
  var _isCropping = false;
  var _isCircleUi = false;
  Uint8List? _croppedData;
  var _statusText = '';
  Map<String, dynamic>? _searchResults;

  @override
  void initState() {
    _loadAllImages();
    super.initState();
  }

  Future<void> _loadAllImages() async {
    setState(() {
      _loadingImage = true;
    });
    for (final assetName in _images) {
      _imageDataList.add(await _load(assetName));
    }
    setState(() {
      _loadingImage = false;
    });
  }

  Future<Uint8List> _load(String assetName) async {
    final assetData = await rootBundle.load(assetName);
    return assetData.buffer.asUint8List();
  }

  Future<Uint8List> _load_abs(String pathToFile) async {
    final data = await File(pathToFile);

    return await data.readAsBytes();
  }

  static const XTypeGroup allowTypeGroup = XTypeGroup(
    label: 'images',
    extensions: <String>['jpg', 'png'],
  );

  Future<void> _loadUserImage() async {
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[allowTypeGroup]);

    if (file == null) {
      return;
    }

    setState(() {
      _loadingImage = true;
    });

    final Uint8List data = await _load_abs(file.path);
    _imageDataList.insert(0, data);

    setState(() {
      _loadingImage = false;
    });
  }

  Future<void> _searchImage(Uint8List imageData) async {
    setState(() {
      _loadingImage = true;
    });

    try {
      final result = await _apiService.classifyImage(imageData);
      setState(() {
        _searchResults = result;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Failed to search image: $e';
      });
    } finally {
      setState(() {
        _loadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Visibility(
          visible: !_loadingImage && !_isCropping,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < _imageDataList.length; i++) ...[
                          _buildThumbnail(_imageDataList[i]),
                          const SizedBox(width: 16),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                child: Text("+ Load Image"),
                onPressed: _loadUserImage,
              ),
              Expanded(
                child: Visibility(
                  visible: _croppedData == null,
                  child: Stack(
                    children: [
                      if (_imageDataList.isNotEmpty) ...[
                        Crop(
                          willUpdateScale: (newScale) => newScale < 5,
                          controller: _cropController,
                          image: _imageDataList[_currentImage],
                          onCropped: (croppedData) {
                            setState(() {
                              _croppedData = croppedData;
                              _isCropping = false;
                            });
                            _searchImage(croppedData);
                          },
                          withCircleUi: _isCircleUi,
                          onStatusChanged: (status) => setState(() {
                            _statusText = <CropStatus, String>{
                                  CropStatus.nothing: 'Crop has no image data',
                                  CropStatus.loading:
                                      'Crop is now loading given image',
                                  CropStatus.ready: 'Crop is now ready!',
                                  CropStatus.cropping:
                                      'Crop is now cropping image',
                                }[status] ??
                                '';
                          }),
                          initialSize: 0.5,
                          maskColor: _isSumbnail ? Colors.white : null,
                          cornerDotBuilder: (size, edgeAlignment) =>
                              const SizedBox.shrink(),
                          interactive: true,
                          fixCropRect: true,
                          radius: 20,
                          initialRectBuilder: (viewportRect, imageRect) {
                            return Rect.fromLTRB(
                              viewportRect.left + 24,
                              viewportRect.top + 24,
                              viewportRect.right - 24,
                              viewportRect.bottom - 24,
                            );
                          },
                        ),
                        IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(width: 4, color: Colors.white),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _isSumbnail = true),
                          onTapUp: (_) => setState(() => _isSumbnail = false),
                          child: CircleAvatar(
                            backgroundColor:
                                _isSumbnail ? Colors.blue.shade50 : Colors.blue,
                            child: Center(
                              child: Icon(Icons.crop_free_rounded),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  replacement: Center(
                    child: _croppedData == null
                        ? SizedBox.shrink()
                        : Image.memory(_croppedData!),
                  ),
                ),
              ),
              if (_croppedData == null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.crop_7_5),
                            onPressed: () {
                              _isCircleUi = false;
                              _cropController.aspectRatio = 16 / 4;
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.crop_16_9),
                            onPressed: () {
                              _isCircleUi = false;
                              _cropController.aspectRatio = 16 / 9;
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.crop_5_4),
                            onPressed: () {
                              _isCircleUi = false;
                              _cropController.aspectRatio = 5 / 4;
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.crop_square),
                            onPressed: () {
                              _isCircleUi = false;
                              _cropController
                                ..withCircleUi = false
                                ..aspectRatio = 1;
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.circle),
                            onPressed: () {
                              _isCircleUi = true;
                              _cropController.withCircleUi = true;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isCropping = true;
                            });
                            _isCircleUi
                                ? _cropController.cropCircle()
                                : _cropController.crop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text('CROP IT!'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(_statusText),
              const SizedBox(height: 16),
              _buildResults(),
            ],
          ),
          replacement: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  Expanded _buildThumbnail(Uint8List data) {
    final index = _imageDataList.indexOf(data);
    return Expanded(
      child: InkWell(
        onTap: () {
          _croppedData = null;
          currentImage = index;
        },
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: index == _currentImage
                ? Border.all(
                    width: 8,
                    color: Colors.blue,
                  )
                : null,
          ),
          child: Image.memory(
            data,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_searchResults == null) {
      return SizedBox.shrink();
    }

    final results = _searchResults!['results'] ?? [];

    return Expanded(
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return Card(
            child: ListTile(
              title: Text(result['description'] ?? 'No description'),
              subtitle: Text('Score: ${result['score']}'),
            ),
          );
        },
      ),
    );
  }
}
