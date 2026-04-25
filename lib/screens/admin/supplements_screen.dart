// lib/screens/admin/supplements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/numpad_utils.dart';

class SupplementsScreen extends StatelessWidget {
  const SupplementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final liste = prov.supplements;

    return Column(
      children: [
        Expanded(
          child: liste.isEmpty
              ? const Center(child: Text('Aucun supplément'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: liste.length,
                  itemBuilder: (_, i) {
                    final s = liste[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF2D3561),
                          child: Icon(Icons.add_circle,
                              color: Colors.white, size: 18),
                        ),
                        title: Text(s.nom,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Prix: ${s.prix.toStringAsFixed(3)} DT'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF2D3561)),
                              onPressed: () => _showForm(context, sup: s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async =>
                                  prov.supprimerSupplement(s.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter un supplément',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3561),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showForm(BuildContext context, {Supplement? sup}) {
    final prov    = context.read<AppProvider>();
    final nomCtrl  = TextEditingController(text: sup?.nom ?? '');
    final prixCtrl = TextEditingController(text: sup?.prix.toString() ?? '');
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(sup == null ? 'Ajouter supplément' : 'Modifier supplément'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nomCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Nom', border: OutlineInputBorder()),
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                // Prix avec numpad
                NumpadFormField(
                  controller: prixCtrl,
                  label: 'Prix (DT)',
                  decimal: true,
                  hintText: 'Ex: 1.500',
                  suffixText: 'DT',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final val = double.tryParse(v.replaceAll(',', '.'));
                    if (val == null) return 'Prix invalide';
                    return null;
                  },
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final newSup = Supplement(
                  id: sup?.id ?? prov.newId(),
                  nom: nomCtrl.text.trim(),
                  prix: double.tryParse(prixCtrl.text.replaceAll(',', '.')) ?? 0,
                  ingredientId: '',
                  quantiteUtilisee: 0,
                );
                if (sup == null) {
                  await prov.ajouterSupplement(newSup);
                } else {
                  await prov.modifierSupplement(newSup);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3561)),
              child: Text(sup == null ? 'Ajouter' : 'Modifier',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
