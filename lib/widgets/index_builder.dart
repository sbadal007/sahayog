import 'package:flutter/material.dart';
import '../services/error_service.dart';
import '../services/index_service.dart';

/// Widget that automatically handles Firestore index creation for chat queries
class AutoIndexBuilder extends StatefulWidget {
  final Widget child;
  final String collection;
  final Map<String, dynamic> queryParams;
  final String location;

  const AutoIndexBuilder({
    super.key,
    required this.child,
    required this.collection,
    required this.queryParams,
    required this.location,
  });

  @override
  State<AutoIndexBuilder> createState() => _AutoIndexBuilderState();
}

class _AutoIndexBuilderState extends State<AutoIndexBuilder> {
  bool _indexCreationTriggered = false;
  bool _isWaitingForIndex = false;

  @override
  void initState() {
    super.initState();
    _checkAndTriggerIndexCreation();
  }

  Future<void> _checkAndTriggerIndexCreation() async {
    if (_indexCreationTriggered) return;

    try {
      _indexCreationTriggered = true;
      setState(() {
        _isWaitingForIndex = true;
      });

      // Trigger index creation
      await IndexService.triggerIndexCreation(
        collection: widget.collection,
        queryParams: widget.queryParams,
      );

      ErrorService.logError(
        message: 'Index creation triggered successfully',
        location: widget.location,
        type: ErrorType.firebase,
        severity: ErrorSeverity.low,
        additionalData: {
          'collection': widget.collection,
          'queryParams': widget.queryParams,
        },
      );

    } catch (e) {
      ErrorService.logError(
        message: 'Index creation trigger failed',
        location: widget.location,
        type: ErrorType.firebase,
        severity: ErrorSeverity.medium,
        error: e,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWaitingForIndex = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWaitingForIndex) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing database...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Setting up required indexes for optimal performance.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return widget.child;
  }
}

/// Specific widget for chat conversations with automatic index management
class ChatIndexBuilder extends StatelessWidget {
  final Widget child;
  final String userId;

  const ChatIndexBuilder({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return AutoIndexBuilder(
      collection: 'conversations',
      queryParams: {
        'participants': userId,
        'isArchived': false,
        'orderBy': 'lastMessageAt',
      },
      location: 'ChatIndexBuilder',
      child: child,
    );
  }
}

/// Enhanced loading widget specifically for index building
class IndexBuildingWidget extends StatefulWidget {
  final String? message;
  final String? indexUrl;
  final VoidCallback? onCancel;

  const IndexBuildingWidget({
    super.key,
    this.message,
    this.indexUrl,
    this.onCancel,
  });

  @override
  State<IndexBuildingWidget> createState() => _IndexBuildingWidgetState();
}

class _IndexBuildingWidgetState extends State<IndexBuildingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading indicator
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 40 + (_animation.value * 20),
                      height: 40 + (_animation.value * 20),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.withOpacity(0.7 + (_animation.value * 0.3)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Main message
            Text(
              widget.message ?? 'Setting up database...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Detailed explanation
            Text(
              'Database indexing is required for optimal performance. Please create the required indexes in Firebase Console using the provided URL.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Manual index creation guidance
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Manual Setup Required',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Due to security settings, indexes must be created manually. Check the console output for the Firebase Console URL.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Progress steps
            _buildProgressSteps(),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.onCancel != null) ...[
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Go Back'),
                  ),
                  const SizedBox(width: 16),
                ],
                if (widget.indexUrl != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      // Could open URL in browser
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Index URL: ${widget.indexUrl}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Technical Details'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildProgressStep(
            icon: Icons.check_circle,
            title: 'Database Connection',
            subtitle: 'Connected successfully',
            isCompleted: true,
          ),
          const SizedBox(height: 12),
          _buildProgressStep(
            icon: Icons.settings,
            title: 'Index Creation',
            subtitle: 'Setting up optimal performance...',
            isCompleted: false,
            isActive: true,
          ),
          const SizedBox(height: 12),
          _buildProgressStep(
            icon: Icons.chat,
            title: 'Chat Ready',
            subtitle: 'Ready for real-time messaging',
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isActive = false,
  }) {
    final color = isCompleted 
        ? Colors.green 
        : isActive 
            ? Colors.blue 
            : Colors.grey;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (isActive)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
      ],
    );
  }
}
