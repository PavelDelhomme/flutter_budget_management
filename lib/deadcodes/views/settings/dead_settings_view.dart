import 'package:flutter/material.dart';

class DeadSettingsView extends StatefulWidget {
  const DeadSettingsView({Key? key}) : super(key: key);

  @override
  _DeadSettingsViewState createState() => _DeadSettingsViewState();
}

class _DeadSettingsViewState extends State<DeadSettingsView> {
  bool _notificationsEnabled = false;
  double _reminderTime = 10.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gérer vos paramètres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Notifications'),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Heure de rappel : ${_reminderTime.toInt()} minutes avant',
            ),
            Slider(
              value: _reminderTime,
              min: 5,
              max: 60,
              divisions: 11,
              label: '${_reminderTime.toInt()} min',
              onChanged: (double value) {
                setState(() {
                  _reminderTime = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Enregistrer les paramètres dans Firestore ou localement
              },
              child: const Text('Enregistrer les paramètres'),
            ),
          ],
        ),
      ),
    );
  }
}