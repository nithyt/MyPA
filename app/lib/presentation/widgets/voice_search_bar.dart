import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Voice-enabled search box: mic icon + text field + search button,
/// per the requested Home screen spec and FDD Section 3.2 / 4.2.
///
/// Uses platform-native speech recognition by default (Architecture v1.4,
/// Section 7 — no API cost for on-device STT). A cloud fallback (e.g.
/// Whisper via Edge Function) can be wired in later behind the same
/// onVoiceResult callback without changing this widget's public API.
class VoiceSearchBar extends StatefulWidget {
  const VoiceSearchBar({
    super.key,
    required this.onSubmitted,
    this.hintText = 'Search or speak an idea',
  });

  final ValueChanged<String> onSubmitted;
  final String hintText;

  @override
  State<VoiceSearchBar> createState() => _VoiceSearchBarState();
}

class _VoiceSearchBarState extends State<VoiceSearchBar> {
  final _speech = stt.SpeechToText();
  final _controller = TextEditingController();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required for voice input.')),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        _controller.text = result.recognizedWords;
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Theme.of(context).colorScheme.primary : null,
                ),
                tooltip: 'Speak',
                onPressed: _toggleListening,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () => widget.onSubmitted(_controller.text),
        ),
      ],
    );
  }
}
