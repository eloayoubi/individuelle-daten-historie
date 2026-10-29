import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../data/vehicle_drive.dart';

/// Antrieb wählen – Benzin/Diesel, Elektro, Hybrid – mit Hinweis, was er an den Feldern ändert.
class VehicleDrivePicker extends StatelessWidget {
  const VehicleDrivePicker({super.key, required this.drive, required this.onChanged});

  /// `null` = noch nicht gewählt (Menge ohne Einheit aus früheren Vorlagen).
  final VehicleDrive? drive;
  final ValueChanged<VehicleDrive> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.m,
        children: [
          AppSegmented<VehicleDrive>(
            value: drive,
            segments: {
              VehicleDrive.fuel: l10n.vehicleDriveFuel,
              VehicleDrive.electric: l10n.vehicleDriveElectric,
              VehicleDrive.hybrid: l10n.vehicleDriveHybrid,
            },
            onChanged: onChanged,
          ),
          AppText(l10n.vehicleDriveHint, style: (t) => t.footnote, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}
