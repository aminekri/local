// lib/screens/admin/ingredients_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/numpad_utils.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final liste = prov.ingredients
        .where((i) =>
            i.nom.toLowerCase().contains(_recherche.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un ingrédient...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (v) => setState(() => _recherche = v),
          ),
        ),
        Expanded(
          child: liste.isEmpty
              ? const Center(child: Text('Aucun ingrédient'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liste.length,
                  itemBuilder: (_, i) {
                    final ing = liste[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              ing.estEnRupture ? Colors.red : Colors.green,
                          child: Icon(
                            ing.estImportant
                                ? Icons.star
                                : Icons.inventory,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        title: Text(ing.nom,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Qté: ${ing.quantite} ${ing.unite} | Seuil: ${ing.seuilAlerte} ${ing.unite}'),
                            if (ing.estEnRupture)
                              const Text('⚠️ STOCK INSUFFISANT',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 11)),
                          ],
                        ),
                        isThreeLine: ing.estEnRupture,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ing.estImportant)
                              const Chip(
                                label: Text('Important',
                                    style: TextStyle(fontSize: 10)),
                                backgroundColor: Color(0xFFE94560),
                                labelStyle:
                                    TextStyle(color: Colors.white),
                                padding: EdgeInsets.zero,
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF2D3561)),
                              onPressed: () =>
                                  _showForm(context, ing: ing),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  _confirmerSupprimer(context, prov, ing.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showForm(BuildContext context, {Ingredient? ing}) {
    final nomCtrl   = TextEditingController(text: ing?.nom ?? '');
    final qteCtrl   = TextEditingController(text: ing?.quantite.toString() ?? '');
    final uniteCtrl = TextEditingController(text: ing?.unite ?? '');
    final seuilCtrl = TextEditingController(text: ing?.seuilAlerte.toString() ?? '');
    bool estImportant = ing?.estImportant ?? false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
              ing == null ? 'Ajouter ingrédient' : 'Modifier ingrédient'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Nom — clavier texte
                TextFormField(
                  controller: nomCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                // Quantité — numpad décimal
                NumpadFormField(
                  controller: qteCtrl,
                  label: 'Quantité',
                  decimal: true,
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                // Unité — clavier texte
                TextFormField(
                  controller: uniteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Unité (kg, pièce...)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                // Seuil d'alerte — numpad décimal
                NumpadFormField(
                  controller: seuilCtrl,
                  label: 'Seuil d\'alerte',
                  decimal: true,
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Ingrédient important'),
                  subtitle: const Text(
                      'Bloque la commande si stock insuffisant'),
                  value: estImportant,
                  onChanged: (v) => setS(() => estImportant = v),
                  activeTrackColor: const Color(0xFFE94560),
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
                final prov = context.read<AppProvider>();
                final newIng = Ingredient(
                  id: ing?.id ?? prov.newId(),
                  nom: nomCtrl.text.trim(),
                  quantite:
                      double.tryParse(qteCtrl.text.replaceAll(',', '.')) ?? 0,
                  unite: uniteCtrl.text.trim(),
                  seuilAlerte: double.tryParse(
                          seuilCtrl.text.replaceAll(',', '.')) ??
                      0,
                  estImportant: estImportant,
                );
                if (ing == null) {
                  await prov.ajouterIngredient(newIng);
                } else {
                  await prov.modifierIngredient(newIng);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3561)),
              child: Text(ing == null ? 'Ajouter' : 'Modifier',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmerSupprimer(
      BuildContext context, AppProvider prov, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Confirmer la suppression ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await prov.supprimerIngredient(id);
              if (context.mounted) Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
