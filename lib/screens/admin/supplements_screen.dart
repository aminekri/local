// lib/screens/admin/supplements_screen.dart — Touch Optimized
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/numpad_utils.dart';

const _kAccent = Color(0xFF2D3561);
const _kTouchH = 56.0;

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
              ? const Center(child: Text('Aucun supplément', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: liste.length,
                  itemBuilder: (_, i) {
                    final s = liste[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: SizedBox(
                        height: 70,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: const CircleAvatar(
                            radius: 24,
                            backgroundColor: _kAccent,
                            child: Icon(Icons.add_circle, color: Colors.white, size: 22),
                          ),
                          title: Text(s.nom,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text('Prix: ${s.prix.toStringAsFixed(3)} DT',
                              style: const TextStyle(fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _iconBtn(Icons.edit, _kAccent, () => _showForm(context, sup: s)),
                              const SizedBox(width: 4),
                              _iconBtn(Icons.delete, Colors.red, () async => prov.supprimerSupplement(s.id)),
                            ],
                          ),
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
            height: _kTouchH + 4,
            child: ElevatedButton.icon(
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              label: const Text('Ajouter un supplément',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(sup == null ? 'Ajouter supplément' : 'Modifier supplément',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: nomCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                  ),
                  const SizedBox(height: 14),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(fontSize: 15)),
            ),
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
                backgroundColor: _kAccent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(sup == null ? 'Ajouter' : 'Modifier',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
