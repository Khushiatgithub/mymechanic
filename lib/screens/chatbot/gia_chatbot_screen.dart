import 'package:flutter/material.dart';

/// Message model for GIA conversational assistant.
class GiaChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Widget? actionWidget;

  const GiaChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actionWidget,
  });
}

/// GIA AI Car Assistant Chatbot Screen matching user reference screenshot.
///
/// Features:
/// - Dark ambient gradient background (deep charcoal to warm dark amber).
/// - Top bar with back arrow navigation.
/// - Glowing circular GIA mascot with automotive headset branding.
/// - "Hey, I am GIA" headline and "What do you need help with?" subtitle.
/// - Quick prompt pills: [Compare Services], [Find the right service].
/// - Bottom capsule input bar with attachment icon, prompt field, and microphone/send button.
/// - Real-time conversational AI mechanic assistance with interactive actions.
class GiaChatbotScreen extends StatefulWidget {
  final VoidCallback? onNavigateToServices;
  final VoidCallback? onNavigateToBookings;

  const GiaChatbotScreen({
    super.key,
    this.onNavigateToServices,
    this.onNavigateToBookings,
  });

  @override
  State<GiaChatbotScreen> createState() => _GiaChatbotScreenState();
}

class _GiaChatbotScreenState extends State<GiaChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<GiaChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String query) {
    final text = query.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(GiaChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate smart AI assistance response
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final reply = _generateGiaReply(text);
      setState(() {
        _isTyping = false;
        _messages.add(reply);
      });
      _scrollToBottom();
    });
  }

  GiaChatMessage _generateGiaReply(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('compare') || lower.contains('comparison')) {
      return GiaChatMessage(
        text:
            'Here is a quick comparison of our top Periodic Maintenance packages:\n\n'
            '• Basic Service (₹1,499): Engine oil replacement, oil filter, dry vacuuming & 15-point inspection.\n'
            '• Standard Service (₹2,799): Adds wiper fluid top-up, battery water top-up, coolant refill & 40-point inspection.\n'
            '• Comprehensive Service (₹4,499): Adds wheel alignment, balancing, brake pad cleaning & 100% genuine parts warranty.',
        isUser: false,
        timestamp: DateTime.now(),
        actionWidget: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onNavigateToServices != null) {
                widget.onNavigateToServices!();
              }
            },
            icon: const Icon(Icons.list_alt_rounded, size: 16),
            label: const Text('View All Packages'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    if (lower.contains('find') || lower.contains('right service') || lower.contains('help')) {
      return GiaChatMessage(
        text:
            'I can help you pinpoint the exact service your car needs! What are you experiencing?\n\n'
            '1. Routine maintenance or oil due?\n'
            '2. AC not blowing chilled air?\n'
            '3. Squeaking brakes or vibration?\n'
            '4. Scratches, dents or paint touch-up?',
        isUser: false,
        timestamp: DateTime.now(),
        actionWidget: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildQuickChip('Periodic Service', 'Tell me about Periodic Service'),
            _buildQuickChip('AC Repair', 'My AC is not cooling properly'),
            _buildQuickChip('Brakes', 'My car brakes are making noise'),
            _buildQuickChip('Car Spa', 'I want full car detailing'),
          ],
        ),
      );
    }

    if (lower.contains('ac') || lower.contains('cool')) {
      return GiaChatMessage(
        text:
            'For AC cooling issues, our High-Performance AC Service includes:\n'
            '• AC gas top-up (100% pure R134a refrigerant)\n'
            '• Cooling coil cleaning & filter replacement\n'
            '• Condenser high-pressure wash\n'
            '• Starting at only ₹1,299 with 60-day cooling warranty.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    if (lower.contains('brake') || lower.contains('noise')) {
      return GiaChatMessage(
        text:
            'Unusual brake noise or spongy pedal feeling usually indicates worn brake pads or disc scoring.\n'
            'We provide OEM brake pad replacement (Brembo / Bosch / TVS Girling) with free disc skimming inspection from ₹850.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    return GiaChatMessage(
      text:
          'Got it! At MyMechanic Premium Car Service, all our work is backed by 100% genuine OEM parts and up to 10,000 km warranty.\n\n'
          'Would you like to explore our service catalog or speak directly to a certified mechanic on our 24x7 helpline?',
      isUser: false,
      timestamp: DateTime.now(),
      actionWidget: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            if (widget.onNavigateToServices != null) {
              widget.onNavigateToServices!();
            }
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
          label: const Text('Explore Catalog', style: TextStyle(color: Colors.white, fontSize: 12)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white30),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String prompt) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      onPressed: () => _sendMessage(prompt),
    );
  }

  Widget _buildGiaAvatar({double size = 70}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF97316), width: 2.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.55),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.directions_car_filled_rounded,
              color: Color(0xFFEF4444),
              size: 38,
            ),
            Positioned(
              right: 6,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  color: Color(0xFF1E293B),
                  size: 16,
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
    final hasMessages = _messages.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF131316),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121215),
              Color(0xFF16151B),
              Color(0xFF22120E),
              Color(0xFF2A140F),
            ],
            stops: [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with back arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                  ],
                ),
              ),

              // Main Body: Either pristine Welcome Screen or Live Chat stream
              Expanded(
                child: hasMessages
                    ? ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
                            return _buildTypingIndicator();
                          }
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 80),
                            // Mascot Avatar
                            _buildGiaAvatar(size: 76),
                            const SizedBox(height: 24),

                            // "Hey, I am GIA"
                            const Text(
                              'Hey, I am GIA',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // "What do you need help with?"
                            Text(
                              'What do you need help with?',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Suggestion Pills matching screenshot
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSuggestionPill('Compare Services', () {
                                  _sendMessage('Compare Services');
                                }),
                                const SizedBox(width: 12),
                                _buildSuggestionPill('Find the right service', () {
                                  _sendMessage('Find the right service');
                                }),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),

              // Bottom Capsule Input Bar matching screenshot
              Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF261815).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Paperclip attachment icon in coral
                        Padding(
                          padding: const EdgeInsets.only(left: 14, right: 8),
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Attach car photo or diagnostic report'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: const Icon(
                              Icons.attach_file_rounded,
                              color: Color(0xFFF97316),
                              size: 24,
                            ),
                          ),
                        ),

                        // Input TextField (isolated from theme fill/borders with dedicated right margin)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextField(
                              controller: _textController,
                              cursorColor: const Color(0xFFF97316),
                              cursorWidth: 2,
                              onSubmitted: _sendMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                hintText: 'Ask GIA about your car',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),

                        // Spacing gap so the search/input bar never touches the microphone button
                        const SizedBox(width: 8),

                        // Circular microphone button in orange/red
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                              onPressed: () {
                                if (_textController.text.trim().isNotEmpty) {
                                  _sendMessage(_textController.text);
                                } else {
                                  _sendMessage('What is included in Periodic Service?');
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionPill(String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.1,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(GiaChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFFDC2626)
              : const Color(0xFF1E293B).withValues(alpha: 0.92),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser ? Colors.transparent : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            if (msg.actionWidget != null) msg.actionWidget!,
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGiaAvatar(size: 22),
            const SizedBox(width: 8),
            const Text(
              'GIA is typing...',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
