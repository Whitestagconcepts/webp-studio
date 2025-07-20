import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:path/path.dart' as path;
import '../providers/conversion_provider.dart';
import '../widgets/image_thumbnail.dart';
import '../widgets/settings_panel.dart';
import '../widgets/neumorphic_button.dart';

class AnimationScreen extends StatefulWidget {
  const AnimationScreen({super.key});

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  bool _isDragging = false;
  bool _showSettings = false;
  final ScrollController _imageScrollController = ScrollController();

  @override
  void dispose() {
    _imageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebP Maker'),
        actions: [
          IconButton(
            icon: Icon(_showSettings ? Icons.close : Icons.settings),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
        ],
      ),
      body: Consumer<ConversionProvider>(
        builder: (context, provider, child) {
          return Row(
            children: [
              // Main content area
              Expanded(
                flex: _showSettings ? 2 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drop zone - scales with window
                      Expanded(flex: 3, child: _buildDropZone(provider)),
                      const SizedBox(height: 16),

                      // Image list - also scales with window
                      if (provider.selectedImages.isNotEmpty) ...[
                        Expanded(flex: 2, child: _buildImageList(provider)),
                        const SizedBox(height: 16),
                      ],

                      // Progress section - flexible height
                      if (provider.isConverting || provider.progress > 0) ...[
                        _buildProgressSection(provider),
                        const SizedBox(height: 12),
                      ],

                      // Action buttons - fixed but responsive
                      _buildActionButtons(provider),
                    ],
                  ),
                ),
              ),

              // Settings panel
              if (_showSettings)
                Container(
                  width: 250, // Reduced from 300
                  color: Theme.of(context).colorScheme.surface,
                  child: SettingsPanel(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropZone(ConversionProvider provider) {
    return DropTarget(
      onDragDone: (detail) async {
        final files = detail.files
            .where((file) => file.path.toLowerCase().endsWith('.png'))
            .map((file) => File(file.path))
            .toList();

        if (files.isNotEmpty) {
          provider.addImages(files);
        }

        setState(() {
          _isDragging = false;
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _isDragging = false;
        });
      },
      child: ClayContainer(
        color: Theme.of(context).cardColor,
        borderRadius: 16,
        depth: _isDragging ? -8 : 8,
        spread: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: _isDragging
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: InkWell(
            onTap: _selectFiles,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: provider.hasOutput
                  ? _buildPreviewArea(provider)
                  : _buildUploadArea(provider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea(ConversionProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isDragging
              ? Icons.file_download
              : Icons.cloud_upload_outlined,
          size: 64,
          color: _isDragging
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          _isDragging
              ? 'Drop PNG files here'
              : provider.selectedImages.isEmpty
              ? 'Drag & Drop PNG Images Here'
              : '${provider.selectedImages.length} images selected',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _isDragging
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Supports: PNG files only',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _selectFiles,
          icon: const Icon(Icons.file_open),
          label: const Text('Browse Files'),
        ),
      ],
    );
  }

  Widget _buildPreviewArea(ConversionProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success icon and title
        Icon(
          Icons.check_circle,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'WebP Animation Created!',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        
        // Preview container
        Container(
          constraints: const BoxConstraints(
            maxWidth: 180,
            maxHeight: 180,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(provider.outputPath!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Download button
        ElevatedButton.icon(
          onPressed: () => _saveFile(provider),
          icon: const Icon(Icons.download),
          label: const Text('Download WebP'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Instructions
        Text(
          'Click anywhere or drag to add more images',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImageList(ConversionProvider provider) {
    return ClayContainer(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: 12,
      depth: 10,
      spread: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Images (${provider.selectedImages.length})',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                NeumorphicButton(
                  onPressed: provider.clearImages,
                  child: const Icon(Icons.clear_all),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    // Handle horizontal mouse wheel scrolling
                    final scrollOffset = pointerSignal.scrollDelta.dy * 2;

                    if (_imageScrollController.hasClients) {
                      final newOffset =
                          (_imageScrollController.offset + scrollOffset).clamp(
                            0.0,
                            _imageScrollController.position.maxScrollExtent,
                          );
                      _imageScrollController.jumpTo(newOffset);
                    }
                  }
                },
                child: Scrollbar(
                  controller: _imageScrollController,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: ReorderableListView.builder(
                    scrollController: _imageScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.selectedImages.length,
                    onReorder: (oldIndex, newIndex) {
                      provider.reorderImages(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      return ImageThumbnail(
                        key: ValueKey(provider.selectedImages[index].path),
                        file: provider.selectedImages[index],
                        index: index,
                        onRemove: () => provider.removeImage(index),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(ConversionProvider provider) {
    return ClayContainer(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: 12,
      depth: 10,
      spread: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              width: null, // Let it use available width
              lineHeight: 8.0,
              percent: provider.progress,
              backgroundColor: Theme.of(context).colorScheme.surface,
              progressColor: Theme.of(context).colorScheme.primary,
              barRadius: const Radius.circular(4),
              animation: true,
              animationDuration: 300,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    provider.statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (provider.progress > 0)
                  Text(
                    '${(provider.progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ConversionProvider provider) {
    return Row(
      children: [
        // Convert button
        Expanded(
          child: NeumorphicButton(
            onPressed: provider.canConvert
                ? () => _startConversion(provider)
                : null,
            isLoading: provider.isConverting,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                provider.isConverting ? 'Converting...' : 'Convert to WebP',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Save button
        if (provider.hasOutput)
          NeumorphicButton(
            onPressed: () => _saveFile(provider),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.save_alt, size: 20),
            ),
          ),
      ],
    );
  }

  Future<void> _selectFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
      allowMultiple: true,
    );

    if (result != null) {
      final files = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      if (files.isNotEmpty && mounted) {
        context.read<ConversionProvider>().addImages(files);
      }
    }
  }

  Future<void> _startConversion(ConversionProvider provider) async {
    final success = await provider.startConversion();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('WebP animation created successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          action: SnackBarAction(
            label: 'Save',
            onPressed: () => _saveFile(provider),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conversion failed: ${provider.statusMessage}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _saveFile(ConversionProvider provider) async {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save WebP Animation',
      fileName: 'animated.webp',
      type: FileType.custom,
      allowedExtensions: ['webp'],
      lockParentWindow: true,
    );

    if (outputPath != null) {
      // Ensure the file has .webp extension
      String finalPath = outputPath;
      if (!finalPath.toLowerCase().endsWith('.webp')) {
        finalPath = '$outputPath.webp';
      }

      final success = await provider.saveAs(finalPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'File saved successfully as ${path.basename(finalPath)}!'
                  : 'Failed to save file',
            ),
            backgroundColor: success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
