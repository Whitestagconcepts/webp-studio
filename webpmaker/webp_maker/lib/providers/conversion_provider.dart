import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:process_run/process_run.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ConversionProvider extends ChangeNotifier {
  // State variables
  final List<File> _selectedImages = [];
  bool _isConverting = false;
  double _progress = 0.0;
  String _statusMessage = 'Ready to convert';
  String? _outputPath;

  // Google WebP conversion settings
  double _delayTime = 3.3; // 1/100 second (3.3 = 30fps, 20 = 5fps)
  int _quality = 95;
  int _loopCount = 0; // 0 = infinite loop
  bool _dontStack = true; // Remove frame when displaying next
  bool _useFirstFrameBackground = false; // Use first frame as background
  bool _crossfadeFrames = false; // Blend frames for smooth transitions

  // Getters
  List<File> get selectedImages => _selectedImages;
  bool get isConverting => _isConverting;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String? get outputPath => _outputPath;
  double get delayTime => _delayTime;
  double get frameRate => 100.0 / _delayTime; // Convert delay to FPS
  int get quality => _quality;
  int get loopCount => _loopCount;
  bool get dontStack => _dontStack;
  bool get useFirstFrameBackground => _useFirstFrameBackground;
  bool get crossfadeFrames => _crossfadeFrames;

  bool get canConvert => _selectedImages.isNotEmpty && !_isConverting;
  bool get hasOutput => _outputPath != null && File(_outputPath!).existsSync();

  // Add images to the list
  void addImages(List<File> images) {
    _selectedImages.addAll(
      images.where(
        (img) =>
            img.path.toLowerCase().endsWith('.png') &&
            !_selectedImages.any((existing) => existing.path == img.path),
      ),
    );
    notifyListeners();
  }

  // Remove an image from the list
  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  // Reorder images
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final File item = _selectedImages.removeAt(oldIndex);
    _selectedImages.insert(newIndex, item);
    notifyListeners();
  }

  // Clear all images
  void clearImages() {
    _selectedImages.clear();
    _outputPath = null;
    notifyListeners();
  }

  // Update conversion settings
  void updateDelayTime(double value) {
    _delayTime = value;
    notifyListeners();
  }

  void updateQuality(int value) {
    _quality = value;
    notifyListeners();
  }

  void updateLoopCount(int value) {
    _loopCount = value;
    notifyListeners();
  }

  void updateDontStack(bool value) {
    _dontStack = value;
    notifyListeners();
  }

  void updateUseFirstFrameBackground(bool value) {
    _useFirstFrameBackground = value;
    notifyListeners();
  }

  void updateCrossfadeFrames(bool value) {
    _crossfadeFrames = value;
    notifyListeners();
  }

  // Start the conversion process using Google WebP tools
  Future<bool> startConversion() async {
    if (_selectedImages.isEmpty || _isConverting) return false;

    _isConverting = true;
    _progress = 0.0;
    _statusMessage = 'Preparing conversion...';
    notifyListeners();

    try {
      // Create temporary directory for processing
      final tempDir = await getTemporaryDirectory();
      final workDir = Directory(path.join(tempDir.path, 'webp_conversion'));

      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
      await workDir.create(recursive: true);

      _statusMessage = 'Copying files...';
      _progress = 0.1;
      notifyListeners();

      // Copy files to temp directory
      final tempFiles = <File>[];
      for (int i = 0; i < _selectedImages.length; i++) {
        final originalFile = _selectedImages[i];
        final tempFile = File(
          path.join(workDir.path, 'frame_${i.toString().padLeft(4, '0')}.png'),
        );
        await originalFile.copy(tempFile.path);
        tempFiles.add(tempFile);
      }

      // Prepare output path
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _outputPath = path.join(outputDir.path, 'animated_$timestamp.webp');

      _statusMessage = 'Creating animated WebP...';
      _progress = 0.3;
      notifyListeners();

      // GOOGLE WEBP APPROACH: Use official Google WebP tools

      // Step 1: Use img2webp to create basic animated WebP
      final img2webpPath =
          'C:\\Users\\th31n\\webpmaker\\webp_maker\\libwebp-1.5.0-windows-x64\\libwebp-1.5.0-windows-x64\\bin\\img2webp.exe';

      final img2webpArgs = <String>[
        '-loop', _loopCount.toString(),
        '-d', (_delayTime * 10).round().toString(), // Convert to milliseconds
      ];

      // Quality settings
      if (_quality >= 100) {
        img2webpArgs.add('-lossless');
      } else {
        img2webpArgs.addAll(['-q', _quality.toString()]);
      }

      // Add all PNG files
      for (final file in tempFiles) {
        img2webpArgs.add(file.path);
      }

      final tempWebpPath = path.join(workDir.path, 'temp_basic.webp');
      img2webpArgs.addAll(['-o', tempWebpPath]);

      debugPrint(
        '🔧 img2webp Command: $img2webpPath ${img2webpArgs.join(' ')}',
      );

      final img2webpResult = await runExecutableArguments(
        img2webpPath,
        img2webpArgs,
        verbose: true,
      );

      if (img2webpResult.exitCode != 0) {
        _statusMessage = 'img2webp failed: ${img2webpResult.stderr}';
        _progress = 0.0;
        notifyListeners();
        return false;
      }

      _statusMessage = 'Applying disposal methods...';
      _progress = 0.7;
      notifyListeners();

      // Step 2: Use webpmux to fix disposal methods (THE KEY TO PREVENTING STACKING!)
      if (_dontStack) {
        final webpmuxPath =
            'C:\\Users\\th31n\\webpmaker\\webp_maker\\libwebp-1.5.0-windows-x64\\libwebp-1.5.0-windows-x64\\bin\\webpmux.exe';
        final cwebpPath =
            'C:\\Users\\th31n\\webpmaker\\webp_maker\\libwebp-1.5.0-windows-x64\\libwebp-1.5.0-windows-x64\\bin\\cwebp.exe';

        // Create individual WebP frames with proper disposal
        final frameDir = path.join(workDir.path, 'frames');
        await Directory(frameDir).create();

        final webpmuxArgs = <String>[];

        for (int i = 0; i < tempFiles.length; i++) {
          // Convert each PNG to individual WebP frame
          final frameWebpPath = path.join(frameDir, 'frame_$i.webp');

          final cwebpArgs = <String>[tempFiles[i].path, '-o', frameWebpPath];

          if (_quality >= 100) {
            cwebpArgs.insert(1, '-lossless');
          } else {
            cwebpArgs.insertAll(1, ['-q', _quality.toString()]);
          }

          await runExecutableArguments(cwebpPath, cwebpArgs, verbose: false);

          // Add frame with disposal method = 1 (dispose to background - PREVENTS STACKING!)
          final delayMs = (_delayTime * 10).round();
          final disposeMethod = '1'; // 1 = dispose to background (key fix!)
          webpmuxArgs.addAll([
            '-frame',
            '$frameWebpPath+$delayMs+0+0+$disposeMethod',
          ]);
        }

        // Add loop count and optional background
        webpmuxArgs.addAll(['-loop', _loopCount.toString()]);

        if (_useFirstFrameBackground) {
          webpmuxArgs.addAll(['-bgcolor', '255,255,255,255']);
        }

        webpmuxArgs.addAll(['-o', _outputPath!]);

        debugPrint('🔧 webpmux Command: $webpmuxPath ${webpmuxArgs.join(' ')}');

        final webpmuxResult = await runExecutableArguments(
          webpmuxPath,
          webpmuxArgs,
          verbose: true,
        );

        if (webpmuxResult.exitCode != 0) {
          // Fallback: copy the basic WebP if webpmux fails
          await File(tempWebpPath).copy(_outputPath!);
          _statusMessage = 'Used basic WebP (webpmux processing failed)';
        }
      } else {
        // Don't stack is disabled, use basic WebP
        await File(tempWebpPath).copy(_outputPath!);
      }

      _statusMessage = 'Conversion completed successfully!';
      _progress = 1.0;

      // Clean up temporary files
      await workDir.delete(recursive: true);

      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Error during conversion: $e';
      _progress = 0.0;
      notifyListeners();
      return false;
    } finally {
      _isConverting = false;
      notifyListeners();
    }
  }

  // Save the output file to a custom location
  Future<bool> saveAs(String destinationPath) async {
    if (_outputPath == null || !File(_outputPath!).existsSync()) {
      return false;
    }

    try {
      await File(_outputPath!).copy(destinationPath);
      return true;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return false;
    }
  }
}
