// lib/screens/admin/produits_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';

class ProduitsScreen extends StatefulWidget {
  const ProduitsScreen({super.key});

  @override
  State<ProduitsScreen> createState() => _ProduitsScreenState();
}

class _ProduitsScreenState extends State<ProduitsScreen> {
  String _recherche = '';
  String? _filtreCategorie;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    var liste = prov.produits;
    if (_filtreCategorie != null) {
      liste = liste.where((p) => p.categorieId == _filtreCategorie).toList();
    }
    if (_recherche.isNotEmpty) {
      liste = liste
          .where((p) => p.nom.toLowerCase().contains(_recherche.toLowerCase()))
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _recherche = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  FilterChip(
                    label: const Text('Tous'),
                    selected: _filtreCategorie == null,
                    onSelected: (_) => setState(() => _filtreCategorie = null),
                  ),
                  const SizedBox(width: 8),
                  ...prov.categories.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(c.nom),
                          selected: _filtreCategorie == c.id,
                          onSelected: (_) =>
                              setState(() => _filtreCategorie = c.id),
                        ),
                      )),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          child: liste.isEmpty
              ? const Center(child: Text('Aucun produit'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liste.length,
                  itemBuilder: (_, i) {
                    final p = liste[i];
                    final cat = prov.categories
                        .where((c) => c.id == p.categorieId)
                        .firstOrNull;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2D3561),
                          child: Text(p.nom[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(p.nom,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${p.prix.toStringAsFixed(3)} DT | ${cat?.nom ?? '?'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF2D3561)),
                              onPressed: () => _showForm(context, produit: p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async => prov.supprimerProduit(p.id),
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
              label: const Text('Ajouter un produit',
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

  void _showForm(BuildContext context, {Produit? produit}) {
    showDialog(
      context: context,
      builder: (_) => _ProduitFormDialog(produit: produit),
    );
  }
}

class _ProduitFormDialog extends StatefulWidget {
  final Produit? produit;
  const _ProduitFormDialog({this.produit});

  @override
  State<_ProduitFormDialog> createState() => _ProduitFormDialogState();
}

class _ProduitFormDialogState extends State<_ProduitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _prixCtrl;
  String? _categorieId;
  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.produit?.nom ?? '');
    _prixCtrl =
        TextEditingController(text: widget.produit?.prix.toString() ?? '');
    _categorieId = widget.produit?.categorieId;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return AlertDialog(
      title: Text(widget.produit == null ? 'Ajouter produit' : 'Modifier produit'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nom du produit', border: OutlineInputBorder()),
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _prixCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.,]'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Prix (DT)',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: 8.500',
                    suffixText: 'DT',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final val = double.tryParse(v.replaceAll(',', '.'));
                    if (val == null || val < 0) return 'Prix invalide';
                    return null;
                  },
                  onChanged: (v) {
                    // Normaliser virgule → point pour la saisie mobile
                    if (v.contains(',')) {
                      final cursor = _prixCtrl.selection;
                      _prixCtrl.value = _prixCtrl.value.copyWith(
                        text: v.replaceAll(',', '.'),
                        selection: cursor,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                // initialValue au lieu de value (deprecated)
                DropdownButtonFormField<String>(
                  key: ValueKey(_categorieId),
                  initialValue: _categorieId,
                  decoration: const InputDecoration(
                      labelText: 'Catégorie', border: OutlineInputBorder()),
                  items: prov.categories
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nom)))
                      .toList(),
                  onChanged: (v) => setState(() => _categorieId = v),
                  validator: (v) =>
                      v == null ? 'Sélectionner une catégorie' : null,
                ),

              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final prov = context.read<AppProvider>();
            final p = Produit(
              id: widget.produit?.id ?? prov.newId(),
              nom: _nomCtrl.text.trim(),
              prix: double.tryParse(_prixCtrl.text.replaceAll(',', '.')) ?? 0,
              categorieId: _categorieId!,
              ingredients: [],
            );
            if (widget.produit == null) {
              await prov.ajouterProduit(p);
            } else {
              await prov.modifierProduit(p);
            }
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3561)),
          child: Text(widget.produit == null ? 'Ajouter' : 'Modifier',
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

}
