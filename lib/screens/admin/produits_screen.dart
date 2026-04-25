// lib/screens/admin/produits_screen.dart — Touch Optimized
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/numpad_utils.dart';

const _kPrimary = Color(0xFF1A1A2E);
const _kAccent  = Color(0xFF2D3561);
const _kTouchH  = 56.0;

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
      liste = liste.where((p) => p.nom.toLowerCase().contains(_recherche.toLowerCase())).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Grande barre de recherche
            SizedBox(
              height: _kTouchH,
              child: TextField(
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  hintStyle: const TextStyle(fontSize: 15),
                  prefixIcon: const Icon(Icons.search, size: 26),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (v) => setState(() => _recherche = v),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _catChip(null, 'Tous'),
                  ...prov.categories.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _catChip(c.id, c.nom),
                      )),
                ],
              ),
            ),
          ]),
        ),
        Expanded(
          child: liste.isEmpty
              ? const Center(child: Text('Aucun produit', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liste.length,
                  itemBuilder: (_, i) {
                    final p = liste[i];
                    final cat = prov.categories.where((c) => c.id == p.categorieId).firstOrNull;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: SizedBox(
                        height: 72,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: _kAccent,
                            child: Text(p.nom[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(p.nom,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text('${p.prix.toStringAsFixed(3)} DT  |  ${cat?.nom ?? '?'}',
                              style: const TextStyle(fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _iconBtn(Icons.edit, _kAccent, () => _showForm(context, produit: p)),
                              const SizedBox(width: 4),
                              _iconBtn(Icons.delete, Colors.red, () async => prov.supprimerProduit(p.id)),
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
              label: const Text('Ajouter un produit',
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

  Widget _catChip(String? id, String label) {
    final selected = _filtreCategorie == id;
    return GestureDetector(
      onTap: () => setState(() => _filtreCategorie = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _kAccent : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
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

  void _showForm(BuildContext context, {Produit? produit}) {
    showDialog(context: context, builder: (_) => _ProduitFormDialog(produit: produit));
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
    _nomCtrl  = TextEditingController(text: widget.produit?.nom ?? '');
    _prixCtrl = TextEditingController(text: widget.produit?.prix.toString() ?? '');
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(widget.produit == null ? 'Ajouter produit' : 'Modifier produit',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom
                TextFormField(
                  controller: _nomCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'Nom du produit',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
                // Prix avec numpad tactile
                NumpadFormField(
                  controller: _prixCtrl,
                  label: 'Prix (DT)',
                  decimal: true,
                  hintText: 'Ex: 8.500',
                  suffixText: 'DT',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final val = double.tryParse(v.replaceAll(',', '.'));
                    if (val == null || val < 0) return 'Prix invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  key: ValueKey(_categorieId),
                  initialValue: _categorieId,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  items: prov.categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom)))
                      .toList(),
                  onChanged: (v) => setState(() => _categorieId = v),
                  validator: (v) => v == null ? 'Sélectionner une catégorie' : null,
                ),
              ],
            ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccent,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            widget.produit == null ? 'Ajouter' : 'Modifier',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
