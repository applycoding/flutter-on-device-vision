import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_device_vision/domain/model_spec.dart';
import 'package:on_device_vision/providers/providers.dart';
import 'package:on_device_vision/ui/theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DetectionSettings settings = ref.watch(settingsProvider);
    final int percent = (settings.confidenceThreshold * 100).round();
    return ColoredBox(
      color: visionInk,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: <Widget>[
            const Text(
              'Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Portfolio demo for Arpan Bom. Detection runs on device.',
              style: TextStyle(color: visionMuted, height: 1.4),
            ),
            const SizedBox(height: 28),
            Text(
              'Confidence  $percent%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Slider(
              key: const Key('confidence-slider'),
              value: settings.confidenceThreshold,
              min: 0.05,
              max: 0.95,
              onChanged: ref.read(settingsProvider.notifier).setConfidence,
            ),
            const Text(
              'Boxes below this score are hidden.',
              style: TextStyle(color: visionMuted),
            ),
            const SizedBox(height: 28),
            const Text(
              'Model',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _ModelCard(
              spec: ModelSpec.ssdMobileNet,
              selected: settings.model == ModelChoice.ssdMobileNet,
              onTap: () => ref
                  .read(settingsProvider.notifier)
                  .selectModel(ModelChoice.ssdMobileNet),
            ),
            const SizedBox(height: 12),
            _ModelCard(
              spec: ModelSpec.efficientDetLite0,
              selected: settings.model == ModelChoice.efficientDetLite0,
              onTap: () => ref
                  .read(settingsProvider.notifier)
                  .selectModel(ModelChoice.efficientDetLite0),
            ),
            const SizedBox(height: 28),
            const Text(
              'Weights are fetched by tool/download_models.sh and are not stored in git.',
              style: TextStyle(color: visionMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final ModelSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: visionPanel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('model-${spec.choice.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? visionAccent : visionLine,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                spec.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                spec.summary,
                style: const TextStyle(color: visionMuted, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
