import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clay_containers/clay_containers.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
            ],
          ),
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
                        Icons.coffee,
                        size: 32,
                        color: Colors.brown[600],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support WebP Studio',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Help keep this free tool alive and growing',
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

              // Main content
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side - About the project
                    Expanded(
                      flex: 2,
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
                                'About This Project',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              
                              _buildFeatureItem(
                                context,
                                Icons.movie_creation,
                                'PNG to Animated WebP',
                                'Convert image sequences to optimized animations',
                              ),
                              
                              _buildFeatureItem(
                                context,
                                Icons.image,
                                'Static Image Conversion',
                                'Convert various formats to WebP with quality control',
                              ),
                              
                              _buildFeatureItem(
                                context,
                                Icons.transform,
                                'WebP Decoder',
                                'Extract frames from WebP animations',
                              ),
                              
                              _buildFeatureItem(
                                context,
                                Icons.gif,
                                'GIF to WebP',
                                'Convert legacy GIF animations to modern WebP',
                              ),
                              
                              _buildFeatureItem(
                                context,
                                Icons.animation,
                                'Animation Tools',
                                'Advanced frame manipulation and optimization',
                              ),

                              const SizedBox(height: 24),
                              
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.code,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Built with',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('• Flutter & Dart', style: TextStyle(fontSize: 14)),
                                    const Text('• Google libwebp tools', style: TextStyle(fontSize: 14)),
                                    const Text('• Modern neumorphic design', style: TextStyle(fontSize: 14)),
                                    const Text('• Hours of optimization work', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Right side - Support options
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          // Coffee donation
                          ClayContainer(
                            color: Theme.of(context).cardColor,
                            borderRadius: 16,
                            depth: 8,
                            spread: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.coffee,
                                    size: 48,
                                    color: Colors.brown[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Buy Me Coffee',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'If this tool has saved you time or helped your workflow, consider supporting its development!',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // PayPal button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _launchPayPal(),
                                      icon: const Icon(Icons.payment),
                                      label: const Text('PayPal Donation'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Contact info
                          ClayContainer(
                            color: Theme.of(context).cardColor,
                            borderRadius: 16,
                            depth: 8,
                            spread: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact & Feedback',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  _buildContactItem(
                                    context,
                                    Icons.bug_report,
                                    'Report Issues',
                                    'Found a bug? Let me know!',
                                  ),
                                  
                                  _buildContactItem(
                                    context,
                                    Icons.lightbulb,
                                    'Feature Requests',
                                    'Have ideas for improvements?',
                                  ),
                                  
                                  _buildContactItem(
                                    context,
                                    Icons.star,
                                    'General Feedback',
                                    'Share your experience!',
                                  ),

                                  const SizedBox(height: 16),
                                  
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This is a passion project made with ❤️',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.secondary,
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
                        ],
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

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchPayPal() async {
    const url = 'https://www.paypal.com/donate/?hosted_button_id=KQNYW5QMJU82Q';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}