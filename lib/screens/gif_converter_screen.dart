import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:process_run/process_run.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../widgets/spiral_spinner.dart';

class GifConverterScreen extends StatefulWidget {
  const GifConverterScreen({super.key});

  @override
  State<GifConverterScreen> createState() => _GifConverterScreenState();
}

class _GifConverterScreenState extends State<GifConverterScreen> {
  File? _selectedGif;
  bool _isConverting = false;
  double _progress = 0.0;
  String _statusMessage = 'Select a GIF file to convert';
  String? _outputPath;

  // Conversion settings
  int _quality = 95;
  bool _lossless = false;
  int _method = 6; // Compression method (0-6)
  bool _mixedMode = false;
  bool _multiThread = true;
  bool _metadata = false;
  double _filterStrength = 60.0;

  bool get canConvert => _selectedGif != null && !_isConverting;
  bool get hasOutput => _outputPath != null && File(_outputPath!).existsSync();

  Future<void> _selectGifFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gif'],
        dialogTitle: 'Select GIF file to convert',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedGif = File(result.files.single.path!);
          _statusMessage =
              'GIF file selected: ${path.basename(_selectedGif!.path)}';
          _outputPath = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _convertGifToWebP() async {
    if (_selectedGif == null || _isConverting) return;

    setState(() {
      _isConverting = true;
      _progress = 0.0;
      _statusMessage = 'Starting GIF to WebP conversion...';
    });

    try {
      // Prepare output path
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final baseName = path.basenameWithoutExtension(_selectedGif!.path);
      _outputPath = path.join(outputDir.path, '${baseName}_$timestamp.webp');

      setState(() {
        _progress = 0.2;
        _statusMessage = 'Converting GIF to WebP...';
      });

      // gif2webp command
      final gif2webpPath = path.join(
        Directory.current.path,
        'libwebp-1.5.0-windows-x64',
        'libwebp-1.5.0-windows-x64',
        'bin',
        'gif2webp.exe',
      );

      final args = <String>[_selectedGif!.path];

      // Quality settings
      if (_lossless) {
        args.add('-lossy');
        args.addAll(['-q', _quality.toString()]);
      } else {
        args.addAll(['-q', _quality.toString()]);
      }

      // Compression method
      args.addAll(['-m', _method.toString()]);

      // Filter strength
      args.addAll(['-f', _filterStrength.round().toString()]);

      // Additional options
      if (_mixedMode) args.add('-mixed');
      if (_multiThread) args.add('-mt');
      if (!_metadata) args.addAll(['-metadata', 'none']);

      // Output file
      args.addAll(['-o', _outputPath!]);

      debugPrint('🔧 gif2webp Command: $gif2webpPath ${args.join(' ')}');

      setState(() {
        _progress = 0.5;
        _statusMessage = 'Running gif2webp conversion...';
      });

      final result = await runExecutableArguments(
        gif2webpPath,
        args,
        verbose: true,
      );

      setState(() {
        _progress = 0.9;
      });

      if (result.exitCode == 0) {
        setState(() {
          _progress = 1.0;
          _statusMessage = 'GIF converted to WebP successfully!';
        });
      } else {
        setState(() {
          _progress = 0.0;
          _statusMessage = 'Conversion failed: ${result.stderr}';
          _outputPath = null;
        });
      }
    } catch (e) {
      setState(() {
        _progress = 0.0;
        _statusMessage = 'Error during conversion: $e';
        _outputPath = null;
      });
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  Future<void> _saveAs() async {
    if (_outputPath == null) return;

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save WebP file as...',
        fileName: path.basename(_outputPath!),
        type: FileType.custom,
        allowedExtensions: ['webp'],
      );

      if (outputFile != null) {
        await File(_outputPath!).copy(outputFile);
        setState(() {
          _statusMessage = 'File saved to: $outputFile';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving file: $e';
      });
    }
  }

  Future<void> _openOutput() async {
    if (_outputPath == null || !File(_outputPath!).existsSync()) return;

    try {
      await runExecutableArguments('explorer', ['/select,', _outputPath!]);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error opening file location: $e';
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
                      Icons.gif,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GIF to WebP Converter',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Convert animated GIF files to WebP format using gif2webp',
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
                  // Left panel - File selection and conversion
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // File selection
                        ClayContainer(
                          color: Theme.of(context).cardColor,
                          borderRadius: 12,
                          depth: 4,
                          spread: 1,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                if (_selectedGif == null) ...[
                                  Icon(
                                    Icons.gif,
                                    size: 64,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No GIF file selected',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click to select a GIF file to convert',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.gif,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    path.basename(_selectedGif!.path),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  FutureBuilder<FileStat>(
                                    future: _selectedGif!.stat(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final sizeKB =
                                            (snapshot.data!.size / 1024)
                                                .round();
                                        return Text(
                                          'Size: ${sizeKB}KB',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _selectGifFile,
                                    icon: const Icon(Icons.folder_open),
                                    label: Text(
                                      _selectedGif == null
                                          ? 'Select GIF File'
                                          : 'Change File',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Conversion progress and controls
                        ClayContainer(
                          color: Theme.of(context).cardColor,
                          borderRadius: 12,
                          depth: 4,
                          spread: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conversion',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),

                                if (_isConverting) ...[
                                  LinearProgressIndicator(value: _progress),
                                  const SizedBox(height: 8),
                                ],

                                Text(
                                  _statusMessage,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: canConvert
                                        ? _convertGifToWebP
                                        : null,
                                    icon: _isConverting
                                        ? const WebPSpinner(size: 24)
                                        : const Icon(Icons.play_arrow),
                                    label: Text(
                                      _isConverting
                                          ? 'Converting...'
                                          : 'Convert to WebP',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  ),
                                ),

                                if (hasOutput) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _saveAs,
                                          icon: const Icon(Icons.save_as),
                                          label: const Text('Save As...'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _openOutput,
                                          icon: const Icon(Icons.folder_open),
                                          label: const Text('Open Folder'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right panel - Settings
                  Expanded(
                    flex: 1,
                    child: ClayContainer(
                      color: Theme.of(context).cardColor,
                      borderRadius: 12,
                      depth: 4,
                      spread: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conversion Settings',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 24),

                            // Quality slider
                            Text(
                              'Quality: $_quality',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Slider(
                              value: _quality.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 100,
                              onChanged: _isConverting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _quality = value.round();
                                      });
                                    },
                            ),
                            const SizedBox(height: 16),

                            // Compression method
                            Text(
                              'Compression Method: $_method',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Slider(
                              value: _method.toDouble(),
                              min: 0,
                              max: 6,
                              divisions: 6,
                              onChanged: _isConverting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _method = value.round();
                                      });
                                    },
                            ),
                            const SizedBox(height: 16),

                            // Filter strength
                            Text(
                              'Filter Strength: ${_filterStrength.round()}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Slider(
                              value: _filterStrength,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              onChanged: _isConverting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _filterStrength = value;
                                      });
                                    },
                            ),
                            const SizedBox(height: 24),

                            // Boolean options
                            CheckboxListTile(
                              title: const Text('Lossless'),
                              subtitle: const Text('Use lossless compression'),
                              value: _lossless,
                              onChanged: _isConverting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _lossless = value ?? false;
                                      });
                                    },
                            ),

                            CheckboxListTile(
                              title: const Text('Mixed Mode'),
                              subtitle: const Text('Use mixed compression'),
                              value: _mixedMode,
                              onChanged: _isConverting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _mixedMode = value ?? false;
                                      });
                                    },
                            ),

                            CheckboxListTile(
                              title: const Text('Multi-threading'),
                              subtitle: const Text('Use multiple threads'),
                              value: _multiThread,
                              onChanged: _isConverting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _multiThread = value ?? false;
                                      });
                                    },
                            ),

                            CheckboxListTile(
                              title: const Text('Preserve Metadata'),
                              subtitle: const Text('Keep GIF metadata'),
                              value: _metadata,
                              onChanged: _isConverting
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _metadata = value ?? false;
                                      });
                                    },
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
    );
  }
}
