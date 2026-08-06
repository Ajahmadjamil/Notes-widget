import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/features/shared_note/entry/controller.dart';
import 'package:provider/provider.dart';

/// Resolves a shared note and routes to text, document, or handwriting editor.
class SharedNoteEntryScreen extends StatefulWidget {
  final String sharedNoteId;
  final String friendLabel;
  final String? friendUid;

  const SharedNoteEntryScreen({
    super.key,
    required this.sharedNoteId,
    required this.friendLabel,
    this.friendUid,
  });

  @override
  State<SharedNoteEntryScreen> createState() => _SharedNoteEntryScreenState();
}

class _SharedNoteEntryScreenState extends State<SharedNoteEntryScreen> {
  late final SharedNoteEntryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SharedNoteEntryController(
      sharedNoteId: widget.sharedNoteId,
      friendLabel: widget.friendLabel,
      friendUid: widget.friendUid,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.resolve(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: const _SharedNoteEntryBody(),
    );
  }
}

class _SharedNoteEntryBody extends StatelessWidget {
  const _SharedNoteEntryBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SharedNoteEntryController>();

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Center(
        child: controller.isLoading
            ? CircularProgressIndicator(color: AppColors.selectedColor)
            : controller.error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
