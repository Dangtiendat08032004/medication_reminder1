import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onAddMedication;

  const EmptyStateWidget({super.key, required this.onAddMedication});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medication, size: 64),
          const SizedBox(height: 16),
          Text(
            'No medications added yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onAddMedication,
            child: const Text('Add Your First Medication'),
          ),
        ],
      ),
    );
  }
}
