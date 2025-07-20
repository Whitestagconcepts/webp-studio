import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:process_run/process_run.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../widgets/spiral_spinner.dart';

class WebPDecoderScreen extends StatefulWidget {
  const WebPDecoderScreen({super.key});

  @override
  State<WebPDecoderScreen> createState() => _WebPDecoderScreenState();
}

class _WebPDecoderScreenState extends State<WebPDecoderScreen> {
  final List<File> _selectedFiles = [];
  bool _isConverting = false;
  double _progress = 0.0;
  String _statusMessage = 'Ready to decode WebP files';
  bool _isDragging = false;

  String _outputFormat = 'png';
  final List<String> _formats = ['png', 'jpg', 'bmp', 'tiff', 'ppm'];

  void _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['webp'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.clear();
        _selectedFiles.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  Future<void> _decodeFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isConverting = true;
      _progress = 0.0;
      _statusMessage = 'Starting decoding...';
    });

    try {
      final outputDir = await getApplicationDocumentsDirectory();
      final decodedDir = Directory(path.join(outputDir.path, 'WebP_Decoded'));
      if (!await decodedDir.exists()) {
        await decodedDir.create(recursive: true);
      }

      final dwebpPath =
          'C:\\Users\\th31n\\webpmaker\\webp_maker\\libwebp-1.5.0-windows-x64\\libwebp-1.5.0-windows-x64\\bin\\dwebp.exe';

      for (int i = 0; i < _selectedFiles.length; i++) {
        setState(() {
          _statusMessage =
              'Decoding ${path.basename(_selectedFiles[i].path)}...';
          _progress = (i + 1) / _selectedFiles.length;
        });

        final inputFile = _selectedFiles[i];
        final outputFile = path.join(
          decodedDir.path,
          '${path.basenameWithoutExtension(inputFile.path)}.$_outputFormat',
        );

        List<String> args = [inputFile.path, '-o', outputFile];

        switch (_outputFormat) {
          case 'jpg':
            args.add('-jpeg');
            break;
          case 'bmp':
            args.add('-bmp');
            break;
          case 'tiff':
            args.add('-tiff');
            break;
          case 'ppm':
            args.add('-ppm');
            break;
          default: // png
            break;
        }

        final result = await run(dwebpPath, args);

        if (result.exitCode != 0) {
          setState(() {
            _statusMessage =
                'Failed to decode ${path.basename(inputFile.path)}';
            _isConverting = false;
          });
          return;
        }
      }

      setState(() {
        _statusMessage = 'Successfully decoded ${_selectedFiles.length} files!';
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
      body: Padding(
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
                        Icons.transform,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WebP Decoder',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Convert WebP files to PNG, JPEG, BMP, TIFF, PPM',
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

              Expanded(
                child: Row(
                  children: [
                    // File list
                    Expanded(
                      flex: 2,
                      child: ClayContainer(
                        color: Theme.of(context).cardColor,
                        borderRadius: 16,
                        depth: _isDragging ? -8 : 8,
                        spread: 2,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: _selectedFiles.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.file_upload_outlined,
                                      size: 64,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Drop WebP Files Here',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Supports: WebP files only',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: _pickFiles,
                                      icon: const Icon(Icons.file_open),
                                      label: const Text('Browse WebP Files'),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_selectedFiles.length} WebP files selected',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _selectedFiles.length,
                                        itemBuilder: (context, index) {
                                          final file = _selectedFiles[index];
                                          return Card(
                                            child: ListTile(
                                              leading: const Icon(Icons.image),
                                              title: Text(
                                                path.basename(file.path),
                                              ),
                                              subtitle: const Text('WebP'),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedFiles.removeAt(
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
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Settings and conversion
                    Expanded(
                      child: Column(
                        children: [
                          // Settings
                          ClayContainer(
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
                                    'Output Format',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 16),

                                  DropdownButton<String>(
                                    value: _outputFormat,
                                    isExpanded: true,
                                    items: _formats.map((format) {
                                      return DropdownMenuItem(
                                        value: format,
                                        child: Text(format.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _outputFormat = value!;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 24),

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
                                              'Format Info',
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
                                          '• PNG: Lossless with transparency',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        const Text(
                                          '• JPEG: Lossy, smaller files',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        const Text(
                                          '• BMP: Uncompressed bitmap',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        const Text(
                                          '• TIFF: High quality archive',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Progress and button
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
                                              _selectedFiles.isEmpty
                                          ? null
                                          : _decodeFiles,
                                      icon: _isConverting
                                          ? const WebPSpinner(size: 24)
                                          : const Icon(Icons.transform),
                                      label: Text(
                                        _isConverting
                                            ? 'Decoding...'
                                            : 'Decode WebP Files',
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
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
