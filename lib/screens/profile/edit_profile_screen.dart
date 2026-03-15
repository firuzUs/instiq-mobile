import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/supabase/supabase_client.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

const _niches = ['Лайфстайл', 'Красота', 'Фитнес', 'Еда', 'Путешествия', 'Бизнес', 'Образование', 'Другое'];

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedNiche;
  File? _avatarFile;
  bool _saving = false;
  String? _error;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile != null && !_initialized) {
            _initialized = true;
            _nameController.text = profile['display_name'] as String? ?? '';
            _bioController.text = profile['bio'] as String? ?? '';
            _selectedNiche = profile['blog_niche'] as String?;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryDark.withValues(alpha: 0.3),
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : (profile?['avatar_url'] != null && (profile!['avatar_url'] as String).isNotEmpty)
                              ? NetworkImage(profile['avatar_url'] as String) as ImageProvider
                              : null,
                      child: _avatarFile == null && (profile?['avatar_url'] == null || (profile!['avatar_url'] as String).isEmpty)
                          ? Text(
                              (_nameController.text.isNotEmpty ? _nameController.text[0] : '?').toUpperCase(),
                              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 36),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Имя'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'О себе (био)',
                    hintText: '100–3000 символов',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  maxLength: 3000,
                  onChanged: (_) => setState(() {}),
                ),
                if (_bioController.text.isNotEmpty && (_bioController.text.length < 100 || _bioController.text.length > 3000))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Био должно быть от 100 до 3000 символов',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.accentDark),
                    ),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedNiche ?? (profile?['blog_niche'] as String?),
                  decoration: const InputDecoration(labelText: 'Ниша блога'),
                  items: _niches.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (v) => setState(() => _selectedNiche = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                GradientButton(
                  onPressed: _saving || _bioController.text.length < 100 || _bioController.text.length > 3000
                      ? null
                      : () => _save(context),
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400);
    if (x != null) setState(() => _avatarFile = File(x.path));
  }

  Future<void> _save(BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        final path = '${user.id}/avatar.jpg';
        await supabase.storage.from('avatar-photos').upload(path, _avatarFile!, fileOptions: const FileOptions(upsert: true));
        avatarUrl = supabase.storage.from('avatar-photos').getPublicUrl(path);
      }
      await supabase.from('profiles').update({
        'display_name': _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'blog_niche': _selectedNiche ?? _niches.first,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }).eq('user_id', user.id);
      ref.invalidate(profileProvider);
      ref.invalidate(onboardingProgressProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }
}
