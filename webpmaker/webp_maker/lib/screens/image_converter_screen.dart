import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:process_run/process_run.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../widgets/spiral_spinner.dart';

class ImageConverterScreen extends StatefulWidget {
  const ImageConverterScreen({super.key});

  @override
  State<ImageConverterScreen> createState() => _ImageConverterScreenState();
}

class _ImageConverterScreenState extends State<ImageConverterScreen> {
  final List<File> _selectedImages = [];
  bool _isConverting = false;
  double _progress = 0.0;
  String _statusMessage = 'Ready to convert images';
  bool _isDragging = false;

  // Settings
  int _quality = 80;
  bool _lossless = false;
  String _preset = 'default';

  final List<String> _presets = [
    'default',
    'photo',
    'picture',
    'drawing',
    'icon',
    'text',
  ];

  void _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'tiff', 'bmp'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(
          result.paths.map((path) => File(path!)).toList(),
        );
      });
    }
  }

  Future<void> _convertImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isConverting = true;
      _progress = 0.0;
      _statusMessage = 'Starting conversion...';
    });

    try {
      final outputDir = await getApplicationDocumentsDirectory();
      final webpDir = Directory(path.join(outputDir.path, 'WebP_Converted'));
      if (!await webpDir.exists()) {
        await webpDir.create(recursive: true);
      }

      final cwebpPath =
          'C:\\Users\\th31n\\webpmaker\\webp_maker\\libwebp-1.5.0-windows-x64\\libwebp-1.5.0-windows-x64\\bin\\cwebp.exe';

      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _statusMessage =
              'Converting ${path.basename(_selectedImages[i].path)}...';
          _progress = (i + 1) / _selectedImages.length;
        });

        final inputFile = _selectedImages[i];
        final outputFile = path.join(
          webpDir.path,
          '${path.basenameWithoutExtension(inputFile.path)}.webp',
        );

        final args = <String>[
          inputFile.path,
          '-o',
          outputFile,
          '-preset',
          _preset,
        ];

        if (_lossless) {
          args.add('-lossless');
        } else {
          args.addAll(['-q', _quality.toString()]);
        }

        final result = await run(cwebpPath, args);

        if (result.exitCode != 0) {
          setState(() {
            _statusMessage =
                'Failed to convert ${path.basename(inputFile.path)}';
            _isConverting = false;
          });
          return;
        }
      }

      setState(() {
        _statusMessage =
            'Successfully converted ${_selectedImages.length} images!';
        _isConverting = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isConverting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: BoxDecoration(
            gradient: _isDragging
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                ClayContainer(
                  color: Theme.of(context).cardColor,
                  borderRadius: 16,
                  depth: 8,
                  spread: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image to WebP Converter',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Convert PNG, JPEG, TIFF, BMP to static WebP format',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Main Content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side - File selection and conversion
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            // Drop area
                            Expanded(
                              child: ClayContainer(
                                color: Theme.of(context).cardColor,
                                borderRadius: 16,
                                depth: _isDragging ? -8 : 8,
                                spread: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  child: _selectedImages.isEmpty
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.cloud_upload_outlined,
                                              size: 64,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Drag & Drop Images Here',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.headlineSmall,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Supports: PNG, JPEG, TIFF, BMP',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                            const SizedBox(height: 24),
                                            ElevatedButton.icon(
                                              onPressed: _pickImages,
                                              icon: const Icon(Icons.file_open),
                                              label: const Text('Browse Files'),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_selectedImages.length} images selected',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge,
                                            ),
                                            const SizedBox(height: 16),
                                            Expanded(
                                              child: ListView.builder(
                                                itemCount:
                                                    _selectedImages.length,
                                                itemBuilder: (context, index) {
                                                  final file =
                                                      _selectedImages[index];
                                                  return Card(
                                                    child: ListTile(
                                                      leading: const Icon(
                                                        Icons.image,
                                                      ),
                                                      title: Text(
                                                        path.basename(
                                                          file.path,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        path
                                                            .extension(
                                                              file.path,
                                                            )
                                                            .toUpperCase(),
                                                      ),
                                                      trailing: IconButton(
                                                        icon: const Icon(
                                                          Icons.remove_circle,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _selectedImages
                                                                .removeAt(
                                                                  index,
                                                                );
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                ElevatedButton.icon(
                                                  onPressed: _pickImages,
                                                  icon: const Icon(Icons.add),
                                                  label: const Text('Add More'),
                                                ),
                                                const SizedBox(width: 16),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedImages.clear();
                                                    });
                                                  },
                                                  icon: const Icon(Icons.clear),
                                                  label: const Text(
                                                    'Clear All',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Progress and Convert button
                            ClayContainer(
                              color: Theme.of(context).cardColor,
                              borderRadius: 12,
                              depth: 5,
                              spread: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    if (_isConverting) ...[
                                      LinearPercentIndicator(
                                        lineHeight: 8,
                                        percent: _progress,
                                        backgroundColor: Colors.grey[300],
                                        progressColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        barRadius: const Radius.circular(4),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    Text(
                                      _statusMessage,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isConverting ||
                                                _selectedImages.isEmpty
                                            ? null
                                            : _convertImages,
                                        icon: _isConverting
                                            ? const WebPSpinner(size: 24)
                                            : const Icon(Icons.transform),
                                        label: Text(
                                          _isConverting
                                              ? 'Converting...'
                                              : 'Convert to WebP',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Right side - Settings
                      Expanded(
                        flex: 1,
                        child: ClayContainer(
                          color: Theme.of(context).cardColor,
                          borderRadius: 16,
                          depth: 8,
                          spread: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conversion Settings',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 24),

                                // Quality slider
                                Text('Quality: ${_quality}%'),
                                Slider(
                                  value: _quality.toDouble(),
                                  min: 0,
                                  max: 100,
                                  divisions: 100,
                                  onChanged: _lossless
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _quality = value.round();
                                          });
                                        },
                                ),

                                const SizedBox(height: 16),

                                // Lossless toggle
                                SwitchListTile(
                                  title: const Text('Lossless'),
                                  subtitle: const Text(
                                    'Perfect quality, larger files',
                                  ),
                                  value: _lossless,
                                  onChanged: (value) {
                                    setState(() {
                                      _lossless = value;
                                    });
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Preset dropdown
                                Text('Preset:'),
                                const SizedBox(height: 8),
                                DropdownButton<String>(
                                  value: _preset,
                                  isExpanded: true,
                                  items: _presets.map((preset) {
                                    return DropdownMenuItem(
                                      value: preset,
                                      child: Text(
                                        preset.substring(0, 1).toUpperCase() +
                                            preset.substring(1),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _preset = value!;
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Info
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Tips',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '• Quality 80-90% provides good balance',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const Text(
                                        '• Use lossless for graphics/text',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const Text(
                                        '• Photo preset works best for photos',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const Text(
                                        '• Drawing preset for illustrations',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
