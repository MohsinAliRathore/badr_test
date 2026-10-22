import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/async_body.dart';
import '../../../../core/widgets/page_chrome.dart';
import '../../../../generated/openapi_models.dart';
import '../bloc/riders_bloc.dart';

class RidersPage extends StatelessWidget {
  const RidersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return BlocConsumer<RidersBloc, RidersState>(
      listenWhen: (p, c) => p.error != c.error,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: s.navRiders,
              subtitle: 'Rider directory for your city',
              actions: [
                if (state.canCreate)
                  FilledButton.icon(
                    onPressed: () => _create(context, state),
                    icon: const Icon(Icons.add),
                    label: Text(s.create),
                  ),
              ],
            ),
            Expanded(
              child: AsyncBody(
                loading: state.loading,
                error: state.error,
                isEmpty: state.riders.isEmpty,
                onRetry: () => context
                    .read<RidersBloc>()
                    .add(const RidersRefreshRequested()),
                child: SpacedList(
                  itemCount: state.riders.length,
                  itemBuilder: (context, i) {
                    final r = state.riders[i];
                    return Card(
                      child: ListTile(
                        title: Text(r.name),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${r.phone} · ${r.cityName ?? r.cityId}'
                            '${r.email != null ? ' · ${r.email}' : ''}',
                          ),
                        ),
                        trailing: state.canUpdate
                            ? IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _edit(context, r),
                              )
                            : null,
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

  Future<void> _create(BuildContext context, RidersState state) async {
    final name = TextEditingController();
    final phone = TextEditingController(text: '+97433');
    final email = TextEditingController();
    var cityId = state.cities.isNotEmpty ? state.cities.first.id : 'city_doh';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create rider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              DropdownButtonFormField<String>(
                initialValue: cityId,
                items: state.cities
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => cityId = v ?? cityId),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      context.read<RidersBloc>().add(
            RiderCreateRequested(
              CreateRiderInput(
                cityId: cityId,
                name: name.text.trim(),
                phone: phone.text.trim(),
                email: email.text.trim().isEmpty ? null : email.text.trim(),
              ),
            ),
          );
    }
  }

  Future<void> _edit(BuildContext context, ApiRider rider) async {
    final name = TextEditingController(text: rider.name);
    final phone = TextEditingController(text: rider.phone);
    final email = TextEditingController(text: rider.email ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${rider.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<RidersBloc>().add(
            RiderUpdateRequested(
              rider.id,
              UpdateRiderInput(
                name: name.text.trim(),
                phone: phone.text.trim(),
                email: email.text.trim().isEmpty ? null : email.text.trim(),
              ),
            ),
          );
    }
  }
}
