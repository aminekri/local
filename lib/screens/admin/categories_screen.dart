// lib/screens/admin/categories_screen.dart — Touch Optimized
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

const _kAccent  = Color(0xFF2D3561);
const _kPrimary = Color(0xFF1A1A2E);
const _kTouchH  = 56.0;

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final cats = prov.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: cats.isEmpty
          ? const Center(child: Text('Aucune catégorie', style: TextStyle(fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final cat = cats[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: SizedBox(
                    height: 68,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: const CircleAvatar(
                        radius: 24,
                        backgroundColor: _kAccent,
                        child: Icon(Icons.category, color: Colors.white, size: 22),
                      ),
                      title: Text(cat.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      trailing: Material(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async => await prov.supprimerCategorie(cat.id),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.delete, color: Colors.red, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAjout(context),
        backgroundColor: _kAccent,
        icon: const Icon(Icons.add, color: Colors.white, size: 26),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  void _showAjout(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Nouvelle catégorie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom de la catégorie',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await context.read<AppProvider>().ajouterCategorie(ctrl.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ajouter',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
