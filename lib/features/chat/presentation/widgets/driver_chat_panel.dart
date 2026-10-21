import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../bloc/chat_bloc.dart';

class DriverChatPanel extends StatefulWidget {
  const DriverChatPanel({super.key});

  @override
  State<DriverChatPanel> createState() => _DriverChatPanelState();
}

class _DriverChatPanelState extends State<DriverChatPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (!state.open) return const SizedBox.shrink();
        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 340,
            height: 420,
            child: Column(
              children: [
                ListTile(
                  title: Text('${s.chat}: ${state.driverName ?? ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        context.read<ChatBloc>().add(const ChatClosed()),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: state.messages.length,
                          itemBuilder: (context, i) {
                            final m = state.messages[i];
                            final mine = m.direction == 'to_driver';
                            return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.body),
                                    Text(
                                      DateFormat.Hm().format(m.createdAt.toLocal()),
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: s.chat,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _send(context),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _send(context),
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _send(BuildContext context) {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<ChatBloc>().add(ChatSendRequested(text));
    _controller.clear();
  }
}
