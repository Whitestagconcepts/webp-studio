import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:clay_containers/clay_containers.dart';
import '../providers/conversion_provider.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final TextEditingController _fpsController = TextEditingController();
  final FocusNode _fpsFocusNode = FocusNode();
  bool _isManualInput = false;
  
  // FPS snap points and their corresponding delay times
  final List<double> _snapPoints = [1.67, 3.33, 4.0, 5.88, 11.11];
  final List<int> _snapFps = [60, 30, 25, 17, 9];

  @override
  void dispose() {
    _fpsController.dispose();
    _fpsFocusNode.dispose();
    super.dispose();
  }

  double _snapToNearestPoint(double value) {
    double closest = _snapPoints[0];
    double minDistance = (value - closest).abs();
    
    for (double snapPoint in _snapPoints) {
      double distance = (value - snapPoint).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closest = snapPoint;
      }
    }
    
    // Only snap if within reasonable distance
    return minDistance < 0.3 ? closest : value;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversionProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WebP Animation Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Segoe UI',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FPS Control
                      _buildFpsSection(context, provider),

                      const SizedBox(height: 24),

                      // Quality
                      _buildSettingSection(
                        context,
                        title: 'Image Quality',
                        subtitle: '${provider.quality}%',
                        child: ClayContainer(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: 8,
                          depth: 5,
                          spread: 1,
                          child: Slider(
                            value: provider.quality.toDouble(),
                            min: 1,
                            max: 100,
                            divisions: 99,
                            onChanged: (value) =>
                                provider.updateQuality(value.round()),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Loop Count
                      _buildSettingSection(
                        context,
                        title: 'Loop Count',
                        subtitle: provider.loopCount == 0
                            ? 'Infinite'
                            : '${provider.loopCount} times',
                        child: ClayContainer(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: 8,
                          depth: 5,
                          spread: 1,
                          child: Slider(
                            value: provider.loopCount.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            onChanged: (value) =>
                                provider.updateLoopCount(value.round()),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Animation Effects Section
                      Text(
                        'Animation Effects',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Segoe UI',
                          letterSpacing: 0.3,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Don't Stack (most important setting!)
                      _buildSettingSection(
                        context,
                        title: 'Don\'t Stack Frames',
                        subtitle:
                            'Remove frame when displaying next (prevents stacking)',
                        child: ClayContainer(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: 8,
                          depth: provider.dontStack ? -5 : 5,
                          spread: 1,
                          child: SwitchListTile(
                            title: Text(
                              provider.dontStack ? 'Enabled' : 'Disabled',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Segoe UI',
                                    letterSpacing: 0.3,
                                  ),
                            ),
                            value: provider.dontStack,
                            onChanged: provider.updateDontStack,
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Use First Frame as Background
                      _buildSettingSection(
                        context,
                        title: 'Use First Frame as Background',
                        subtitle:
                            'Use first frame as background for all images',
                        child: ClayContainer(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: 8,
                          depth: provider.useFirstFrameBackground ? -5 : 5,
                          spread: 1,
                          child: SwitchListTile(
                            title: Text(
                              provider.useFirstFrameBackground
                                  ? 'Enabled'
                                  : 'Disabled',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Segoe UI',
                                    letterSpacing: 0.3,
                                  ),
                            ),
                            value: provider.useFirstFrameBackground,
                            onChanged: provider.updateUseFirstFrameBackground,
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Crossfade Frames
                      _buildSettingSection(
                        context,
                        title: 'Crossfade Frames',
                        subtitle:
                            'Blend frames together for smooth transitions',
                        child: ClayContainer(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: 8,
                          depth: provider.crossfadeFrames ? -5 : 5,
                          spread: 1,
                          child: SwitchListTile(
                            title: Text(
                              provider.crossfadeFrames ? 'Enabled' : 'Disabled',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Segoe UI',
                                    letterSpacing: 0.3,
                                  ),
                            ),
                            value: provider.crossfadeFrames,
                            onChanged: provider.updateCrossfadeFrames,
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info Section
                      _buildInfoSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _delayToFps(double delay) {
    final fps = 100.0 / delay;
    return fps.toStringAsFixed(1);
  }

  Widget _buildSettingSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Segoe UI',
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
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
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'WebP Animation Settings',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Segoe UI',
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• FPS: 60fps (smooth), 30fps (standard), 9fps (slow)',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              '• Don\'t Stack: Essential for transparent backgrounds',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              '• First Frame Background: Helps with transparency',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              '• Quality 95-100% recommended for animations',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFpsSection(BuildContext context, ConversionProvider provider) {
    final currentFps = 100.0 / provider.delayTime;
    
    if (!_isManualInput) {
      _fpsController.text = currentFps.toStringAsFixed(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Frame Rate (FPS)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Segoe UI',
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isManualInput = !_isManualInput;
                  if (_isManualInput) {
                    _fpsFocusNode.requestFocus();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  _isManualInput ? Icons.tune : Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Current: ${currentFps.toStringAsFixed(1)} FPS (${provider.delayTime.toStringAsFixed(2)} delay)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        
        if (_isManualInput) ...[
          // Manual FPS Input
          ClayContainer(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: 8,
            depth: -3,
            spread: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fpsController,
                      focusNode: _fpsFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontFamily: 'Segoe UI',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter FPS (1-60)',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        suffixText: 'FPS',
                        suffixStyle: TextStyle(color: Colors.white70),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isManualInput = true;
                        });
                        final fps = double.tryParse(value);
                        if (fps != null && fps > 0 && fps <= 60) {
                          final delayTime = 100.0 / fps;
                          provider.updateDelayTime(delayTime);
                        }
                      },
                      onSubmitted: (value) {
                        final fps = double.tryParse(value);
                        if (fps != null && fps > 0 && fps <= 60) {
                          final delayTime = 100.0 / fps;
                          provider.updateDelayTime(delayTime);
                        } else {
                          // Reset to current value if invalid
                          _fpsController.text = currentFps.toStringAsFixed(1);
                        }
                        _fpsFocusNode.unfocus();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // FPS Slider with snap points
          ClayContainer(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: 8,
            depth: 5,
            spread: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Slider(
                    value: provider.delayTime.clamp(1.67, 11.11),
                    min: 1.67, // 60fps
                    max: 11.11, // 9fps
                    onChanged: (value) {
                      final snappedValue = _snapToNearestPoint(value);
                      provider.updateDelayTime(snappedValue);
                    },
                  ),
                  // FPS snap buttons
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(_snapFps.length, (index) {
                      final fps = _snapFps[index];
                      final delayTime = _snapPoints[index];
                      final isSelected = (provider.delayTime - delayTime).abs() < 0.1;
                      
                      return GestureDetector(
                        onTap: () => provider.updateDelayTime(delayTime),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 32),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${fps}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
