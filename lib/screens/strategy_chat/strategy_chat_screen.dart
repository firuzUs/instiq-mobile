import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/providers/project_provider.dart';

class StrategyChatScreen extends ConsumerStatefulWidget {
  const StrategyChatScreen({super.key});

  @override
  ConsumerState<StrategyChatScreen> createState() => _StrategyChatScreenState();
}

class _StrategyChatScreenState extends ConsumerState<StrategyChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final user = supabase.auth.currentUser;
    final projectId = ref.read(currentProjectIdProvider) ?? await _firstProjectId();
    if (user == null || projectId == null) return;
    final res = await supabase
        .from('strategy_chat_messages')
        .select()
        .eq('user_id', user.id)
        .eq('project_id', projectId)
        .order('created_at');
    if (!mounted) return;
    setState(() {
      _messages.clear();
      for (final r in res ?? <dynamic>[]) {
        final map = r as Map<String, dynamic>;
        _messages.add({
          'role': map['role'] as String? ?? 'user',
          'content': map['content'] as String? ?? '',
        });
      }
      _initialLoad = false;
    });
  }

  Future<String?> _firstProjectId() async {
    final list = await ref.read(projectsListProvider.future);
    return list.isNotEmpty ? list.first['id'] as String? : null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;
    final user = supabase.auth.currentUser;
    final projectId = ref.read(currentProjectIdProvider) ?? await _firstProjectId();
    if (user == null || projectId == null) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messageController.clear();
      _isLoading = true;
    });
    try {
      await supabase.from('strategy_chat_messages').insert({
        'user_id': user.id,
        'project_id': projectId,
        'role': 'user',
        'content': text,
      });
      final history = _messages.map((m) => {'role': m['role'], 'content': m['content']}).toList();
      final response = await supabase.functions.invoke(
        'strategy-chat',
        body: {'message': text, 'history': history, 'projectId': projectId},
      );
      final reply = response.data != null && response.data is Map
          ? (response.data as Map)['reply'] as String? ?? 'Нет ответа.'
          : 'Ошибка ответа.';
      await supabase.from('strategy_chat_messages').insert({
        'user_id': user.id,
        'project_id': projectId,
        'role': 'assistant',
        'content': reply,
      });
      if (mounted) setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _messages.add({'role': 'assistant', 'content': 'Ошибка: $e'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Text('AI-стратег', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('AI', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primaryDark.withValues(alpha: 0.3)
                          : AppColors.cardDark.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: isUser ? null : Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
                    ),
                    child: Text(m['content'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Спросите стратега...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
