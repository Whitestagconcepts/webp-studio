import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clay_containers/clay_containers.dart';
import '../providers/conversion_provider.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

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
                      // Delay Time (1/100 second)
                      _buildSettingSection(
                        context,
                        title: 'Delay Time (1/100 second)',
                        subtitle:
                            '${provider.delayTime.toStringAsFixed(1)} = ${_delayToFps(provider.delayTime)} FPS',
                        child: ClayContainer(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: 8,
                          depth: 5,
                          spread: 1,
                          child: Slider(
                            value: provider.delayTime,
                            min: 1.0,
                            max: 50.0,
                            divisions: 49,
                            onChanged: (value) =>
                                provider.updateDelayTime(value),
                          ),
                        ),
                      ),

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
              '• Delay time: 3.3 = 30fps, 10 = 10fps, 20 = 5fps',
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
}
