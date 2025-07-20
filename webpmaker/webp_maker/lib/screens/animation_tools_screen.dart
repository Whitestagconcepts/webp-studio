import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:process_run/process_run.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../widgets/spiral_spinner.dart';

class AnimationToolsScreen extends StatefulWidget {
  const AnimationToolsScreen({super.key});

  @override
  State<AnimationToolsScreen> createState() => _AnimationToolsScreenState();
}

class _AnimationToolsScreenState extends State<AnimationToolsScreen> {
  File? _selectedAnimation1;
  File? _selectedAnimation2;
  File? _selectedAnimationForDump;
  bool _isProcessing = false;
  String _statusMessage = 'Select animation files to compare or extract frames';
  String? _outputPath;
  int _selectedTool = 0; // 0 = anim_diff, 1 = anim_dump

  // anim_diff settings
  bool _rawComparison = false;
  bool _showAllFrames = false;

  // anim_dump settings
  String _outputFormat = 'png'; // png, pam, ppm, pgm, bmp, tiff

  bool get canCompare =>
      _selectedAnimation1 != null &&
      _selectedAnimation2 != null &&
      !_isProcessing &&
      _selectedTool == 0;
  bool get canDump =>
      _selectedAnimationForDump != null && !_isProcessing && _selectedTool == 1;
  bool get hasOutput =>
      _outputPath != null &&
      (File(_outputPath!).existsSync() || Directory(_outputPath!).existsSync());

  Future<void> _selectAnimationFile1() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webp', 'gif'],
        dialogTitle: 'Select first animation file',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAnimation1 = File(result.files.single.path!);
          _statusMessage =
              'First animation selected: ${path.basename(_selectedAnimation1!.path)}';
          _outputPath = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _selectAnimationFile2() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webp', 'gif'],
        dialogTitle: 'Select second animation file',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAnimation2 = File(result.files.single.path!);
          _statusMessage =
              'Second animation selected: ${path.basename(_selectedAnimation2!.path)}';
          _outputPath = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _selectAnimationForDump() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webp'],
        dialogTitle: 'Select WebP animation to extract frames',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAnimationForDump = File(result.files.single.path!);
          _statusMessage =
              'Animation selected: ${path.basename(_selectedAnimationForDump!.path)}';
          _outputPath = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _compareAnimations() async {
    if (_selectedAnimation1 == null ||
        _selectedAnimation2 == null ||
        _isProcessing)
      return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Comparing animations...';
    });

    try {
      // Prepare output path
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _outputPath = path.join(
        outputDir.path,
        'anim_diff_report_$timestamp.txt',
      );

      final animDiffPath =
          'C:\\Users\\th31n\\webpmaker\\webp_maker\\libwebp-1.5.0-windows-x64\\libwebp-1.5.0-windows-x64\\bin\\anim_diff.exe';

      final args = <String>[];

      // Add options
      if (_rawComparison) args.add('-raw_comparison');
      if (_showAllFrames) args.add('-show_all');

      // Add input files
      args.addAll([_selectedAnimation1!.path, _selectedAnimation2!.path]);

      debugPrint('🔧 anim_diff Command: $animDiffPath ${args.join(' ')}');

      final result = await runExecutableArguments(
        animDiffPath,
        args,
        verbose: true,
      );

      // Save output to file
      await File(_outputPath!).writeAsString(
        'Animation Comparison Report\n'
        '==========================\n\n'
        'File 1: ${_selectedAnimation1!.path}\n'
        'File 2: ${_selectedAnimation2!.path}\n\n'
        'Command: $animDiffPath ${args.join(' ')}\n\n'
        'Output:\n${result.stdout}\n\n'
        'Errors:\n${result.stderr}\n\n'
        'Exit Code: ${result.exitCode}\n',
      );

      if (result.exitCode == 0) {
        setState(() {
          _statusMessage = 'Animation comparison completed successfully!';
        });
      } else {
        setState(() {
          _statusMessage = 'Comparison completed with differences found';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during comparison: $e';
        _outputPath = null;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _extractFrames() async {
    if (_selectedAnimationForDump == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Extracting frames...';
    });

    try {
      // Prepare output directory
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final baseName = path.basenameWithoutExtension(
        _selectedAnimationForDump!.path,
      );
      final frameDir = path.join(
        outputDir.path,
        '${baseName}_frames_$timestamp',
      );
      await Directory(frameDir).create(recursive: true);
      _outputPath = frameDir;

      final animDumpPath =
          'C:\\Users\\th31n\\webpmaker\\webp_maker\\libwebp-1.5.0-windows-x64\\libwebp-1.5.0-windows-x64\\bin\\anim_dump.exe';

      final args = <String>[
        _selectedAnimationForDump!.path,
        path.join(frameDir, 'frame'),
      ];

      // Add output format
      args.addAll(['-${_outputFormat}']);

      debugPrint('🔧 anim_dump Command: $animDumpPath ${args.join(' ')}');

      final result = await runExecutableArguments(
        animDumpPath,
        args,
        verbose: true,
      );

      if (result.exitCode == 0) {
        // Count extracted frames
        final extractedFiles = Directory(frameDir)
            .listSync()
            .where(
              (file) =>
                  file is File &&
                  path.extension(file.path) == '.$_outputFormat',
            )
            .length;

        setState(() {
          _statusMessage = 'Extracted $extractedFiles frames successfully!';
        });
      } else {
        setState(() {
          _statusMessage = 'Frame extraction failed: ${result.stderr}';
          _outputPath = null;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during frame extraction: $e';
        _outputPath = null;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _openOutput() async {
    if (_outputPath == null) return;

    try {
      if (File(_outputPath!).existsSync()) {
        // Open file
        await runExecutableArguments('notepad', [_outputPath!]);
      } else if (Directory(_outputPath!).existsSync()) {
        // Open directory
        await runExecutableArguments('explorer', [_outputPath!]);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error opening output: $e';
      });
    }
  }

  Widget _buildFileSelectionCard(
    String title,
    File? selectedFile,
    VoidCallback onSelect,
    IconData icon,
  ) {
    return ClayContainer(
      color: Theme.of(context).cardColor,
      borderRadius: 12,
      depth: 4,
      spread: 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: selectedFile != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (selectedFile != null) ...[
              Text(
                path.basename(selectedFile.path),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              FutureBuilder<FileStat>(
                future: selectedFile.stat(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final sizeKB = (snapshot.data!.size / 1024).round();
                    return Text(
                      'Size: ${sizeKB}KB',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ] else ...[
              Text(
                'No file selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSelect,
                icon: const Icon(Icons.folder_open),
                label: Text(
                  selectedFile == null ? 'Select File' : 'Change File',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                      Icons.animation,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Animation Tools',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Compare animations and extract frames using anim_diff and anim_dump',
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

            // Tool selection
            ClayContainer(
              color: Theme.of(context).cardColor,
              borderRadius: 12,
              depth: 4,
              spread: 1,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text('Animation Comparison'),
                        subtitle: const Text(
                          'Compare two animations with anim_diff',
                        ),
                        value: 0,
                        groupValue: _selectedTool,
                        onChanged: _isProcessing
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedTool = value!;
                                  _outputPath = null;
                                  _statusMessage = _selectedTool == 0
                                      ? 'Select animation files to compare'
                                      : 'Select animation file to extract frames';
                                });
                              },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text('Frame Extraction'),
                        subtitle: const Text('Extract frames with anim_dump'),
                        value: 1,
                        groupValue: _selectedTool,
                        onChanged: _isProcessing
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedTool = value!;
                                  _outputPath = null;
                                  _statusMessage = _selectedTool == 0
                                      ? 'Select animation files to compare'
                                      : 'Select animation file to extract frames';
                                });
                              },
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
                  // Left panel - File selection
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        if (_selectedTool == 0) ...[
                          // Animation comparison files
                          Expanded(
                            child: _buildFileSelectionCard(
                              'First Animation',
                              _selectedAnimation1,
                              _selectAnimationFile1,
                              Icons.animation,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildFileSelectionCard(
                              'Second Animation',
                              _selectedAnimation2,
                              _selectAnimationFile2,
                              Icons.animation,
                            ),
                          ),
                        ] else ...[
                          // Frame extraction file
                          Expanded(
                            child: _buildFileSelectionCard(
                              'WebP Animation',
                              _selectedAnimationForDump,
                              _selectAnimationForDump,
                              Icons.animation,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Process controls
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
                                  _selectedTool == 0
                                      ? 'Comparison'
                                      : 'Frame Extraction',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),

                                Text(
                                  _statusMessage,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _selectedTool == 0
                                        ? (canCompare
                                              ? _compareAnimations
                                              : null)
                                        : (canDump ? _extractFrames : null),
                                    icon: _isProcessing
                                        ? const WebPSpinner(size: 24)
                                        : Icon(
                                            _selectedTool == 0
                                                ? Icons.compare
                                                : Icons.layers,
                                          ),
                                    label: Text(
                                      _isProcessing
                                          ? 'Processing...'
                                          : (_selectedTool == 0
                                                ? 'Compare Animations'
                                                : 'Extract Frames'),
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
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _openOutput,
                                      icon: Icon(
                                        _selectedTool == 0
                                            ? Icons.description
                                            : Icons.folder_open,
                                      ),
                                      label: Text(
                                        _selectedTool == 0
                                            ? 'View Report'
                                            : 'Open Frames Folder',
                                      ),
                                    ),
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
                              _selectedTool == 0
                                  ? 'Comparison Settings'
                                  : 'Extraction Settings',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 24),

                            if (_selectedTool == 0) ...[
                              // anim_diff settings
                              CheckboxListTile(
                                title: const Text('Raw Comparison'),
                                subtitle: const Text(
                                  'Use raw pixel comparison',
                                ),
                                value: _rawComparison,
                                onChanged: _isProcessing
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _rawComparison = value ?? false;
                                        });
                                      },
                              ),

                              CheckboxListTile(
                                title: const Text('Show All Frames'),
                                subtitle: const Text(
                                  'Show differences in all frames',
                                ),
                                value: _showAllFrames,
                                onChanged: _isProcessing
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _showAllFrames = value ?? false;
                                        });
                                      },
                              ),
                            ] else ...[
                              // anim_dump settings
                              Text(
                                'Output Format',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),

                              ...[
                                'png',
                                'pam',
                                'ppm',
                                'pgm',
                                'bmp',
                                'tiff',
                              ].map(
                                (format) => RadioListTile<String>(
                                  title: Text(format.toUpperCase()),
                                  value: format,
                                  groupValue: _outputFormat,
                                  onChanged: _isProcessing
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _outputFormat = value!;
                                          });
                                        },
                                ),
                              ),
                            ],
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
