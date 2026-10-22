import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/async_body.dart';
import '../../../../core/widgets/page_chrome.dart';
import '../../../../generated/openapi_models.dart';
import '../bloc/users_bloc.dart';

const _roles = [
  'ops_manager',
  'dispatcher',
  'support',
  'viewer',
  'super_admin',
];

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return BlocConsumer<UsersBloc, UsersState>(
      listenWhen: (p, c) => p.error != c.error || p.message != c.message,
      listener: (context, state) {
        final msg = state.error ?? state.message;
        if (msg != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: s.navUsers,
              subtitle: 'Create, re-role, and ban console users',
              actions: [
                if (state.canCreate)
                  FilledButton.icon(
                    onPressed: () => _create(context),
                    icon: const Icon(Icons.person_add),
                    label: Text(s.create),
                  ),
              ],
            ),
            Expanded(
              child: AsyncBody(
                loading: state.loading,
                error: state.error,
                isEmpty: state.users.isEmpty,
                onRetry: () =>
                    context.read<UsersBloc>().add(const UsersRefreshRequested()),
                child: SpacedList(
                  itemCount: state.users.length,
                  itemBuilder: (context, i) {
                    final u = state.users[i];
                    return Card(
                      child: ListTile(
                        title: Text(u.name),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${u.email} · ${u.role}'
                            '${u.cityId != null ? ' · ${u.cityId}' : ''}'
                            '${u.banned ? ' · BANNED' : ''}',
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            if (state.canSetRole)
                              IconButton.filledTonal(
                                tooltip: 'Change role',
                                onPressed: () => _editRole(context, u),
                                icon: const Icon(Icons.manage_accounts),
                              ),
                            if (state.canBan)
                              IconButton.filledTonal(
                                tooltip: u.banned ? s.unban : s.ban,
                                onPressed: () => u.banned
                                    ? context
                                        .read<UsersBloc>()
                                        .add(UserUnbanRequested(u.id))
                                    : _ban(context, u),
                                icon: Icon(
                                  u.banned ? Icons.lock_open : Icons.block,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _create(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController(text: 'Demo@12345');
    String role = 'viewer';
    String? cityId = 'city_doh';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create user'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: password, decoration: const InputDecoration(labelText: 'Password')),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => role = v ?? role),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                DropdownButtonFormField<String?>(
                  initialValue: cityId,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All cities')),
                    DropdownMenuItem(value: 'city_doh', child: Text('Doha')),
                    DropdownMenuItem(value: 'city_ray', child: Text('Al Rayyan')),
                    DropdownMenuItem(value: 'city_wak', child: Text('Al Wakrah')),
                  ],
                  onChanged: (v) => setState(() => cityId = v),
                  decoration: const InputDecoration(labelText: 'City'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      context.read<UsersBloc>().add(
            UserCreateRequested(
              CreateUserInput(
                name: name.text.trim(),
                email: email.text.trim(),
                password: password.text,
                role: role,
                cityId: role == 'super_admin' ? null : cityId,
              ),
            ),
          );
    }
  }

  Future<void> _editRole(BuildContext context, ApiUser user) async {
    String role = user.role;
    String? cityId = user.cityId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Re-role ${user.email}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: role,
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => role = v ?? role),
              ),
              DropdownButtonFormField<String?>(
                initialValue: cityId,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All cities')),
                  DropdownMenuItem(value: 'city_doh', child: Text('Doha')),
                  DropdownMenuItem(value: 'city_ray', child: Text('Al Rayyan')),
                  DropdownMenuItem(value: 'city_wak', child: Text('Al Wakrah')),
                ],
                onChanged: (v) => setState(() => cityId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      context.read<UsersBloc>().add(
            UserUpdateRequested(
              user.id,
              UpdateUserInput(
                role: role,
                cityId: role == 'super_admin' ? null : cityId,
              ),
            ),
          );
    }
  }

  Future<void> _ban(BuildContext context, ApiUser user) async {
    final reason = TextEditingController(text: 'Assessment ban test');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ban ${user.email}'),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ban')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<UsersBloc>().add(UserBanRequested(user.id, reason.text.trim()));
    }
  }
}
