// lib/screens/admin/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final cats = prov.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: cats.isEmpty
          ? const Center(child: Text('Aucune catégorie'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final cat = cats[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2D3561),
                      child: Icon(Icons.category, color: Colors.white, size: 18),
                    ),
                    title: Text(cat.nom),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async => await prov.supprimerCategorie(cat.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAjout(context),
        backgroundColor: const Color(0xFF2D3561),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAjout(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'Nom de la catégorie', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await context.read<AppProvider>().ajouterCategorie(ctrl.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3561)),
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
