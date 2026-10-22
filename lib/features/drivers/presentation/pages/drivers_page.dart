import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/async_body.dart';
import '../../../../core/widgets/page_chrome.dart';
import '../../../../generated/openapi_models.dart';
import '../bloc/drivers_bloc.dart';

class DriversPage extends StatelessWidget {
  const DriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return BlocConsumer<DriversBloc, DriversState>(
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
              title: s.navDrivers,
              subtitle: 'Fleet directory for your city',
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
                isEmpty: state.drivers.isEmpty,
                onRetry: () => context
                    .read<DriversBloc>()
                    .add(const DriversRefreshRequested()),
                child: SpacedList(
                  itemCount: state.drivers.length,
                  itemBuilder: (context, i) {
                    final d = state.drivers[i];
                    return Card(
                      child: ListTile(
                        title: Text(d.name),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${d.phone} · ${d.status} · ${d.cityName ?? d.cityId}'
                            '${d.vehicle != null ? ' · ${d.vehicle!.plate}' : ''}',
                          ),
                        ),
                        trailing: state.canUpdate
                            ? IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _edit(context, d),
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

  Future<void> _create(BuildContext context, DriversState state) async {
    final name = TextEditingController();
    final phone = TextEditingController(text: '+97455');
    final make = TextEditingController(text: 'Toyota');
    final model = TextEditingController(text: 'Camry');
    final plate = TextEditingController(text: 'QA-NEW');
    final color = TextEditingController(text: 'White');
    var cityId = state.cities.isNotEmpty ? state.cities.first.id : 'city_doh';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create driver'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 12),
                  TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone (+974…)')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: cityId,
                    items: state.cities
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => cityId = v ?? cityId),
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: make, decoration: const InputDecoration(labelText: 'Make')),
                  const SizedBox(height: 12),
                  TextField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
                  const SizedBox(height: 12),
                  TextField(controller: plate, decoration: const InputDecoration(labelText: 'Plate')),
                  const SizedBox(height: 12),
                  TextField(controller: color, decoration: const InputDecoration(labelText: 'Color')),
                ],
              ),
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
      context.read<DriversBloc>().add(
            DriverCreateRequested(
              CreateDriverInput(
                cityId: cityId,
                name: name.text.trim(),
                phone: phone.text.trim(),
                vehicle: ApiVehicle(
                  make: make.text.trim(),
                  model: model.text.trim(),
                  plate: plate.text.trim(),
                  color: color.text.trim(),
                ),
              ),
            ),
          );
    }
  }

  Future<void> _edit(BuildContext context, ApiDriver driver) async {
    final name = TextEditingController(text: driver.name);
    final phone = TextEditingController(text: driver.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${driver.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<DriversBloc>().add(
            DriverUpdateRequested(
              driver.id,
              UpdateDriverInput(name: name.text.trim(), phone: phone.text.trim()),
            ),
          );
    }
  }
}
