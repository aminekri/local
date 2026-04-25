// lib/screens/admin/commentaires_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentairesScreen extends StatefulWidget {
  const CommentairesScreen({super.key});

  @override
  State<CommentairesScreen> createState() => _CommentairesScreenState();
}

class _CommentairesScreenState extends State<CommentairesScreen> {
  List<String> _commentaires = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _commentaires = prefs.getStringList('commentaires_predefinis') ?? [
        'Sans oignons',
        'Bien cuit',
        'Peu épicé',
        'Extra sauce',
        'Allergie noix',
      ];
    });
  }

  Future<void> _sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('commentaires_predefinis', _commentaires);
  }

  void _ajouter() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau commentaire'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Commentaire', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _commentaires.add(ctrl.text.trim()));
                _sauvegarder();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3561)),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _commentaires.isEmpty
          ? const Center(child: Text('Aucun commentaire prédéfini'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _commentaires.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _commentaires.removeAt(oldIndex);
                  _commentaires.insert(newIndex, item);
                });
                _sauvegarder();
              },
              itemBuilder: (_, i) {
                return Card(
                  key: ValueKey(_commentaires[i]),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle, color: Colors.grey),
                    title: Text(_commentaires[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _commentaires.removeAt(i));
                        _sauvegarder();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        backgroundColor: const Color(0xFF2D3561),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
