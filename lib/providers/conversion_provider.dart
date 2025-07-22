import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:process_run/process_run.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ConversionProvider extends ChangeNotifier {
  // State variables
  final List<File> _selectedImages = [];
  bool _isConverting = false;
  bool _isCancelled = false;
  double _progress = 0.0;
  String _statusMessage = 'Ready to convert';
  String? _outputPath;

  // Google WebP conversion settings
  double _delayTime = 3.33; // 1/100 second (3.33 = 30fps exactly)
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
  bool get isCancelled => _isCancelled;

  // Startup cleanup method
  Future<void> cleanupStartup() async {
    try {
      final currentDir = Directory.current;
      final files = await currentDir.list().toList();
      
      for (final entity in files) {
        if (entity is File) {
          final name = path.basename(entity.path);
          // Clean up numbered PNG files (1.png, 2.png, etc.)
          if (RegExp(r'^\d+\.png$').hasMatch(name)) {
            await entity.delete();
            debugPrint('Cleaned up: $name');
          }
          // Clean up frame WebP files (f_0.webp, f_1.webp, etc.)
          else if (RegExp(r'^f_\d+\.webp$').hasMatch(name)) {
            await entity.delete();
            debugPrint('Cleaned up: $name');
          }
          // Clean up temp files
          else if (name == 'temp_basic.webp' || 
                   name == 'convert.bat' || 
                   name == 'webpmux.bat' ||
                   name == 'webpmux_args.txt' ||
                   name.startsWith('chunk_') && name.endsWith('.webp')) {
            await entity.delete();
            debugPrint('Cleaned up: $name');
          }
        }
      }
      debugPrint('Startup cleanup completed');
    } catch (e) {
      debugPrint('Startup cleanup error: $e');
    }
  }

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

  // Cancel conversion
  Future<void> cancelConversion() async {
    if (!_isConverting) return;
    
    _isCancelled = true;
    _statusMessage = 'Cancelling conversion...';
    notifyListeners();
    
    // Cleanup any temp files
    await _cleanupTempFiles();
    
    _isConverting = false;
    _isCancelled = false;
    _progress = 0.0;
    _statusMessage = 'Conversion cancelled';
    notifyListeners();
  }

  // Start the conversion process using Google WebP tools
  Future<bool> startConversion() async {
    if (_selectedImages.isEmpty || _isConverting) return false;

    _isConverting = true;
    _isCancelled = false;
    _progress = 0.0;
    _statusMessage = 'Preparing conversion...';
    notifyListeners();

    try {
      // Use app root directory directly for shortest possible paths
      final workDir = Directory.current;

      _statusMessage = 'Copying files...';
      _progress = 0.1;
      notifyListeners();
      
      if (_isCancelled) return false;

      // Copy files directly to app root with simple numeric names
      final tempFiles = <File>[];
      for (int i = 0; i < _selectedImages.length; i++) {
        final originalFile = _selectedImages[i];
        final tempFile = File('${i + 1}.png'); // Ultra short: 1.png, 2.png, 3.png...
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
      
      if (_isCancelled) return false;

      // SIMPLIFIED WEBPMUX APPROACH: Just like ezgif
      // Step 1: Convert each PNG to WebP frame
      // Step 2: Use webpmux to create animated WebP with disposal methods
      
      _statusMessage = 'Converting PNG frames to WebP...';
      _progress = 0.3;
      notifyListeners();

      final cwebpPath = path.join(
        Directory.current.path,
        'libwebp-1.5.0-windows-x64',
        'libwebp-1.5.0-windows-x64',
        'bin',
        'cwebp.exe',
      );

      // Convert each PNG to individual WebP frame
      for (int i = 0; i < tempFiles.length; i++) {
        final frameWebpPath = 'f_$i.webp';
        final cwebpArgs = <String>['${i + 1}.png', '-o', frameWebpPath];

        if (_quality >= 100) {
          cwebpArgs.insertAll(1, ['-lossless', '-exact', '-mt']);
        } else {
          cwebpArgs.insertAll(1, ['-q', _quality.toString(), '-exact', '-mt', '-alpha_method', '1']);
        }

        final cwebpResult = await runExecutableArguments(
          cwebpPath, 
          cwebpArgs, 
          verbose: false,
          workingDirectory: Directory.current.path,
        );
        
        if (cwebpResult.exitCode != 0) {
          _statusMessage = 'Frame conversion failed: ${cwebpResult.stderr}';
          _progress = 0.0;
          notifyListeners();
          return false;
        }
      }

      _statusMessage = 'Creating animated WebP with webpmux...';
      _progress = 0.7;
      notifyListeners();
      
      if (_isCancelled) return false;

      // Step 2: Use webpmux to create animated WebP
      final webpmuxPath = path.join(
        Directory.current.path,
        'libwebp-1.5.0-windows-x64',
        'libwebp-1.5.0-windows-x64',
        'bin',
        'webpmux.exe',
      );

      final webpmuxArgs = <String>[];

      // Add each frame with disposal method - CRITICAL: space between filename and timing
      for (int i = 0; i < tempFiles.length; i++) {
        final frameWebpPath = 'f_$i.webp';
        final delayMs = (_delayTime * 10).round();
        final disposeMethod = _dontStack ? '1' : '0'; // 1 = dispose to background, 0 = no disposal
        final timingArg = '+$delayMs+0+0+$disposeMethod';
        
        webpmuxArgs.add('-frame');
        webpmuxArgs.add(frameWebpPath);
        webpmuxArgs.add(timingArg);
      }

      // Add loop count and optional background
      webpmuxArgs.addAll(['-loop', _loopCount.toString()]);

      if (_useFirstFrameBackground) {
        webpmuxArgs.addAll(['-bgcolor', '255,255,255,255']);
      }

      webpmuxArgs.addAll(['-o', _outputPath!]);

      // Use direct execution - syntax is now correct
      debugPrint('🔧 Creating animated WebP with ${tempFiles.length} frames');
      debugPrint('   - Disposal method: ${_dontStack ? '1 (dispose to background)' : '0 (no disposal)'}');
      debugPrint('   - Delay per frame: ${(_delayTime * 10).round()}ms');
      debugPrint('   - Loop count: $_loopCount');
      debugPrint('   - Total webpmux args: ${webpmuxArgs.length}');
      debugPrint('   - First few args: ${webpmuxArgs.take(8).join(' ')}');
      
      final webpmuxResult = await runExecutableArguments(
        webpmuxPath,
        webpmuxArgs,
        verbose: true,
        workingDirectory: Directory.current.path,
      );

      if (webpmuxResult.exitCode != 0) {
        _statusMessage = 'webpmux failed: ${webpmuxResult.stderr}';
        _progress = 0.0;
        notifyListeners();
        return false;
      }

      _statusMessage = 'Conversion completed successfully!';
      _progress = 1.0;

      // Clean up temporary files
      await _cleanupTempFiles();

      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'Error during conversion: $e';
      _progress = 0.0;
      notifyListeners();
      return false;
    } finally {
      _isConverting = false;
      _isCancelled = false;
      notifyListeners();
    }
  }
  
  // Extract cleanup into separate method
  Future<void> _cleanupTempFiles() async {
    try {
      // Clean up numbered PNG files
      final currentDir = Directory.current;
      final files = await currentDir.list().toList();
      
      for (final entity in files) {
        if (entity is File) {
          final name = path.basename(entity.path);
          if (RegExp(r'^\d+\.png$').hasMatch(name) ||
              RegExp(r'^f_\d+\.webp$').hasMatch(name) ||
              name == 'temp_basic.webp' ||
              name == 'convert.bat' ||
              name == 'webpmux.bat' ||
              name == 'webpmux_args.txt' ||
              (name.startsWith('chunk_') && name.endsWith('.webp'))) {
            await entity.delete();
            debugPrint('Cleaned up: $name');
          }
        }
      }
    } catch (e) {
      debugPrint('Cleanup error: $e');
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
