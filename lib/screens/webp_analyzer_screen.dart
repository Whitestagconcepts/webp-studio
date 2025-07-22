import 'package:flutter/material.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:process_run/process_run.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class WebPAnalyzerScreen extends StatefulWidget {
  const WebPAnalyzerScreen({super.key});

  @override
  State<WebPAnalyzerScreen> createState() => _WebPAnalyzerScreenState();
}

class _WebPAnalyzerScreenState extends State<WebPAnalyzerScreen> {
  File? _selectedWebP;
  bool _isAnalyzing = false;
  String _statusMessage = 'Select a WebP file to analyze';
  Map<String, dynamic> _analysisResult = {};

  bool get canAnalyze => _selectedWebP != null && !_isAnalyzing;
  bool get hasResult => _analysisResult.isNotEmpty;

  Future<void> _selectWebPFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['webp'],
        dialogTitle: 'Select WebP file to analyze',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedWebP = File(result.files.single.path!);
          _statusMessage =
              'WebP file selected: ${path.basename(_selectedWebP!.path)}';
          _analysisResult = {};
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _analyzeWebP() async {
    if (_selectedWebP == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Analyzing WebP file...';
      _analysisResult = {};
    });

    try {
      final webpinfoPath = path.join(
        Directory.current.path,
        'libwebp-1.5.0-windows-x64',
        'libwebp-1.5.0-windows-x64',
        'bin',
        'webpinfo.exe',
      );

      final args = [
        '-summary', // Show summary information
        '-bitstream_info', // Show bitstream information
        '-prediction_info', // Show prediction information
        '-quiet', // Reduce verbose output
        _selectedWebP!.path,
      ];

      debugPrint('🔧 webpinfo Command: $webpinfoPath ${args.join(' ')}');

      final result = await runExecutableArguments(
        webpinfoPath,
        args,
        verbose: true,
      );

      if (result.exitCode == 0) {
        _parseWebPInfo(result.stdout.toString());
        setState(() {
          _statusMessage = 'WebP file analyzed successfully!';
        });
      } else {
        setState(() {
          _statusMessage = 'Analysis failed: ${result.stderr}';
          _analysisResult = {};
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during analysis: $e';
        _analysisResult = {};
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _parseWebPInfo(String output) {
    final lines = output.split('\n');
    final result = <String, dynamic>{};

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Parse key information
      if (line.startsWith('File size:')) {
        result['fileSize'] = line.substring(10).trim();
      } else if (line.startsWith('Canvas size:')) {
        result['canvasSize'] = line.substring(12).trim();
      } else if (line.startsWith('Features present:')) {
        result['features'] = line.substring(17).trim();
      } else if (line.startsWith('Animation:')) {
        result['isAnimation'] = line.contains('yes');
      } else if (line.startsWith('Number of frames:')) {
        result['frameCount'] = line.substring(17).trim();
      } else if (line.startsWith('Format:')) {
        result['format'] = line.substring(7).trim();
      } else if (line.startsWith('Alpha channel:')) {
        result['hasAlpha'] = line.contains('yes');
      } else if (line.startsWith('Loop count:')) {
        result['loopCount'] = line.substring(11).trim();
      } else if (line.contains('Compression:')) {
        result['compression'] = line.split('Compression:')[1].trim();
      } else if (line.contains('Quality:')) {
        result['quality'] = line.split('Quality:')[1].trim();
      }
    }

    // Get file stats
    _selectedWebP!.stat().then((stats) {
      result['fileSizeBytes'] = stats.size;
      result['fileModified'] = stats.modified.toString();
      setState(() {
        _analysisResult = result;
      });
    });
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return ClayContainer(
      color: Theme.of(context).cardColor,
      borderRadius: 8,
      depth: 2,
      spread: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
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
                      Icons.analytics,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WebP File Analyzer',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Analyze WebP file structure and metadata using webpinfo',
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
                  // Left panel - File selection and analysis
                  Expanded(
                    flex: 1,
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
                                if (_selectedWebP == null) ...[
                                  Icon(
                                    Icons.image,
                                    size: 64,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No WebP file selected',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click to select a WebP file to analyze',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.image,
                                    size: 48,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    path.basename(_selectedWebP!.path),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  FutureBuilder<FileStat>(
                                    future: _selectedWebP!.stat(),
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
                                    onPressed: _selectWebPFile,
                                    icon: const Icon(Icons.folder_open),
                                    label: Text(
                                      _selectedWebP == null
                                          ? 'Select WebP File'
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

                        // Analysis controls
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
                                  'Analysis',
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
                                    onPressed: canAnalyze ? _analyzeWebP : null,
                                    icon: _isAnalyzing
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.analytics),
                                    label: Text(
                                      _isAnalyzing
                                          ? 'Analyzing...'
                                          : 'Analyze WebP',
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right panel - Analysis results
                  Expanded(
                    flex: 2,
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
                              'Analysis Results',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 24),

                            if (!hasResult) ...[
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 64,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No analysis results yet',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Select and analyze a WebP file to see detailed information',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // Basic Information
                                      if (_analysisResult['canvasSize'] != null)
                                        _buildInfoCard(
                                          'Canvas Size',
                                          _analysisResult['canvasSize'],
                                          Icons.aspect_ratio,
                                        ),

                                      const SizedBox(height: 12),

                                      if (_analysisResult['fileSizeBytes'] !=
                                          null)
                                        _buildInfoCard(
                                          'File Size',
                                          '${(_analysisResult['fileSizeBytes'] / 1024).round()} KB',
                                          Icons.storage,
                                        ),

                                      const SizedBox(height: 12),

                                      if (_analysisResult['format'] != null)
                                        _buildInfoCard(
                                          'Format',
                                          _analysisResult['format'],
                                          Icons.image,
                                        ),

                                      const SizedBox(height: 12),

                                      if (_analysisResult['compression'] !=
                                          null)
                                        _buildInfoCard(
                                          'Compression',
                                          _analysisResult['compression'],
                                          Icons.compress,
                                        ),

                                      const SizedBox(height: 12),

                                      if (_analysisResult['quality'] != null)
                                        _buildInfoCard(
                                          'Quality',
                                          _analysisResult['quality'],
                                          Icons.high_quality,
                                        ),

                                      const SizedBox(height: 12),

                                      if (_analysisResult.containsKey(
                                        'hasAlpha',
                                      ))
                                        _buildInfoCard(
                                          'Alpha Channel',
                                          _analysisResult['hasAlpha']
                                              ? 'Yes'
                                              : 'No',
                                          Icons.opacity,
                                        ),

                                      const SizedBox(height: 12),

                                      if (_analysisResult.containsKey(
                                        'isAnimation',
                                      ))
                                        _buildInfoCard(
                                          'Animation',
                                          _analysisResult['isAnimation']
                                              ? 'Yes'
                                              : 'No',
                                          Icons.animation,
                                        ),

                                      if (_analysisResult['isAnimation'] ==
                                          true) ...[
                                        const SizedBox(height: 12),

                                        if (_analysisResult['frameCount'] !=
                                            null)
                                          _buildInfoCard(
                                            'Frame Count',
                                            _analysisResult['frameCount'],
                                            Icons.layers,
                                          ),

                                        const SizedBox(height: 12),

                                        if (_analysisResult['loopCount'] !=
                                            null)
                                          _buildInfoCard(
                                            'Loop Count',
                                            _analysisResult['loopCount'] == '0'
                                                ? 'Infinite'
                                                : _analysisResult['loopCount'],
                                            Icons.loop,
                                          ),
                                      ],

                                      const SizedBox(height: 12),

                                      if (_analysisResult['features'] != null)
                                        _buildInfoCard(
                                          'Features',
                                          _analysisResult['features'],
                                          Icons.featured_play_list,
                                        ),
                                    ],
                                  ),
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
