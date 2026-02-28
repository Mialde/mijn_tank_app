// lib/widgets/settings/user_profile_section.dart

import 'package:flutter/material.dart';
import '../../models/user_settings.dart';
import '../../data_provider.dart';
import 'accordion_card.dart';

class UserProfileSection extends StatefulWidget {
  final Color appColor;
  final UserSettings settings;
  final DataProvider provider;

  const UserProfileSection({
    super.key,
    required this.appColor,
    required this.settings,
    required this.provider,
  });

  @override
  State<UserProfileSection> createState() => _UserProfileSectionState();
}

class _UserProfileSectionState extends State<UserProfileSection> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.settings.firstName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccordionCard(
      title: 'Gebruikersprofiel',
      icon: Icons.person_outline,
      appColor: widget.appColor,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Jouw Naam',
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onChanged: (v) => widget.provider.updateSettings(widget.settings.copyWith(firstName: v)),
          ),
        ),
        ListTile(
          minTileHeight: 72,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: const Text('Begroeting tonen'),
          trailing: Switch(
            value: widget.settings.useGreeting,
            activeTrackColor: widget.appColor,
            onChanged: (v) => widget.provider.updateSettings(widget.settings.copyWith(useGreeting: v)),
          ),
          onTap: () => widget.provider.updateSettings(
            widget.settings.copyWith(useGreeting: !widget.settings.useGreeting),
          ),
        ),
        ListTile(
          minTileHeight: 72,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: const Text('Quotes tonen'),
          trailing: Switch(
            value: widget.settings.showQuotes,
            activeTrackColor: widget.appColor,
            onChanged: (v) => widget.provider.updateSettings(widget.settings.copyWith(showQuotes: v)),
          ),
          onTap: () => widget.provider.updateSettings(
            widget.settings.copyWith(showQuotes: !widget.settings.showQuotes),
          ),
        ),
      ],
    );
  }
}