// lib/screens/caisse/caisse_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/ticket_service.dart';
import '../../utils/numpad_utils.dart';

class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen> {
  final _fmt = NumberFormat('#,##0.000', 'fr_TN');
  final _searchCtrl = TextEditingController();
  String _recherche = '';
  String? _filtreCategorie;

  // ── Nouveau flux : quantité PRÉ-SAISIE avant de cliquer le produit ──────────
  // Mode A : "pré-saisie"  → on tape la qté PUIS on clique le produit/ligne
  // Mode B : ligne sélectionnée → on tape la qté pour modifier une ligne existante
  String _qteBuffer = '';                  // buffer partagé
  String? _ligneSelectionneeId;            // ligne ciblée (mode B)

  // La caisse a le focus clavier uniquement quand aucun TextField n'est actif
  bool _clavierActif = true;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Gestion clavier physique (PC/tablette) ──────────────────────────────────
  bool _onKey(KeyEvent event) {
    if (!_clavierActif) return false;           // laisser passer si un TextField a le focus
    if (event is! KeyDownEvent) return false;

    final char = event.character;
    if (char != null && RegExp(r'[0-9]').hasMatch(char)) {
      _appendQte(char);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _deleteQte();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_ligneSelectionneeId != null && _qteBuffer.isNotEmpty) {
        _appliquerQteBuffer();
      }
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _resetBuffer();
      return true;
    }
    return false;
  }

  // ── Buffer quantité ─────────────────────────────────────────────────────────
  void _appendQte(String digit) {
    setState(() {
      _qteBuffer = _qteBuffer + digit;
      // Supprimer les zéros en tête
      if (_qteBuffer.startsWith('0') && _qteBuffer.length > 1) {
        _qteBuffer = _qteBuffer.replaceFirst(RegExp(r'^0+'), '');
      }
    });
  }

  void _deleteQte() {
    if (_qteBuffer.isEmpty) return;
    setState(() {
      _qteBuffer = _qteBuffer.length > 1
          ? _qteBuffer.substring(0, _qteBuffer.length - 1)
          : '';
    });
  }

  void _resetBuffer() {
    setState(() {
      _qteBuffer = '';
      _ligneSelectionneeId = null;
    });
  }

  // Quantité à utiliser (1 par défaut si buffer vide)
  int get _qteEffective => int.tryParse(_qteBuffer) ?? 1;

  // ── Ajouter un produit (avec quantité pré-saisie) ───────────────────────────
  void _ajouterProduit(Produit p) {
    final prov = context.read<AppProvider>();
    final qte = _qteEffective; // 1 si buffer vide, sinon la valeur saisie
    try {
      // Ajouter une nouvelle ligne avec la quantité pré-saisie
      prov.ajouterProduitAvecQuantite(p, qte);
    } catch (e) {
      _showErreur(e.toString().replaceAll('Exception: ', ''));
    }
    // Toujours réinitialiser le buffer après l'action
    setState(() {
      _qteBuffer = '';
      _ligneSelectionneeId = null;
    });
  }

  // ── Modifier quantité d'une ligne existante ─────────────────────────────────
  void _appliquerQteBuffer() {
    if (_ligneSelectionneeId == null || _qteBuffer.isEmpty) return;
    final qte = _qteEffective;
    try {
      context.read<AppProvider>().modifierQuantiteLigne(_ligneSelectionneeId!, qte);
    } catch (e) {
      _showErreur(e.toString().replaceAll('Exception: ', ''));
    }
    setState(() {
      _qteBuffer = '';
      _ligneSelectionneeId = null;
    });
  }

  void _showErreur(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSucces(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('CAISSE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: isWide
          ? Row(children: [
              Expanded(flex: 5, child: _buildCatalogue(isWide: true)),
              Container(width: 1, color: Colors.grey.shade300),
              SizedBox(
                  width: size.width * 0.38,
                  child: _buildPanier(isWide: true)),
            ])
          : Column(children: [
              Expanded(flex: 55, child: _buildCatalogue(isWide: false)),
              Divider(height: 1, color: Colors.grey.shade400),
              Expanded(flex: 45, child: _buildPanier(isWide: false)),
            ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  CATALOGUE
  // ════════════════════════════════════════════════════════
  Widget _buildCatalogue({required bool isWide}) {
    final prov = context.watch<AppProvider>();
    var produits = prov.produits;

    if (_filtreCategorie != null) {
      produits = produits
          .where((p) => p.categorieId == _filtreCategorie)
          .toList();
    }
    if (_recherche.isNotEmpty) {
      produits = produits
          .where((p) =>
              p.nom.toLowerCase().contains(_recherche.toLowerCase()))
          .toList();
    }

    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            onTap: () => setState(() => _clavierActif = false),
            onTapOutside: (_) {
              FocusScope.of(context).unfocus();
              setState(() => _clavierActif = true);
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _recherche.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _recherche = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) => setState(() => _recherche = v),
          ),
        ),
        const SizedBox(height: 8),

        // Filtres catégories
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _catChip(null, 'Tous'),
              ...prov.categories.map((c) => _catChip(c.id, c.nom)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Grille produits
        Expanded(
          child: produits.isEmpty
              ? const Center(child: Text('Aucun produit trouvé'))
              : LayoutBuilder(builder: (_, constraints) {
                  final cols = constraints.maxWidth > 600
                      ? 4
                      : constraints.maxWidth > 400
                          ? 3
                          : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: produits.length,
                    itemBuilder: (_, i) =>
                        _buildProduitCard(produits[i]),
                  );
                }),
        ),
      ],
    );
  }

  Widget _catChip(String? id, String label) {
    final selected = _filtreCategorie == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : null)),
        selected: selected,
        selectedColor: const Color(0xFF2D3561),
        onSelected: (_) => setState(() => _filtreCategorie = id),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildProduitCard(Produit p) {
    // Afficher la quantité pré-saisie sur la carte si buffer non vide
    final qteLabel = _qteBuffer.isNotEmpty ? '×$_qteBuffer' : '';

    return GestureDetector(
      onTap: () => _ajouterProduit(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge quantité pré-saisie
              if (qteLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3561),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    qteLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                )
              else
                const Icon(
                  Icons.fastfood,
                  size: 28,
                  color: Color(0xFF2D3561),
                ),
              const SizedBox(height: 4),
              Text(
                p.nom,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_fmt.format(p.prix)} DT',
                style: const TextStyle(
                  color: Color(0xFFE94560),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PANIER
  // ════════════════════════════════════════════════════════
  Widget _buildPanier({required bool isWide}) {
    final prov = context.watch<AppProvider>();
    final lignes = prov.lignesCommande;
    final hasSelection = _ligneSelectionneeId != null;
    final showNumpad = isWide || hasSelection || _qteBuffer.isNotEmpty;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // En-tête
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1A1A2E),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('COMMANDE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (lignes.isNotEmpty)
                  TextButton(
                    onPressed: _confirmerAnnulation,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Annuler tout',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          ),

          // Liste des lignes
          Expanded(
            child: lignes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 40, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Commande vide',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: lignes.length,
                    itemBuilder: (_, i) =>
                        _buildLigneCommande(lignes[i]),
                  ),
          ),

          // Numpad
          if (showNumpad || isWide)
            _buildNumpad(isWide: isWide),

          // Barre total
          _buildTotalBar(prov, isWide: isWide),
        ],
      ),
    );
  }

  Widget _buildLigneCommande(LigneCommande ligne) {
    final prov = context.read<AppProvider>();
    final selected = _ligneSelectionneeId == ligne.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            // Désélectionner
            _ligneSelectionneeId = null;
            _qteBuffer = '';
          } else {
            // Sélectionner pour modifier
            _ligneSelectionneeId = ligne.id;
            _qteBuffer = '${ligne.quantite}';
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2D3561).withValues(alpha: 0.06)
              : null,
          border: Border(
            left: BorderSide(
              color: selected
                  ? const Color(0xFF2D3561)
                  : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Contrôles quantité
              _qteBtn(Icons.remove, () {
                try {
                  prov.modifierQuantiteLigne(
                      ligne.id, ligne.quantite - 1);
                  if (ligne.quantite - 1 <= 0 &&
                      _ligneSelectionneeId == ligne.id) {
                    setState(() => _ligneSelectionneeId = null);
                  }
                } catch (e) {
                  _showErreur(
                      e.toString().replaceAll('Exception: ', ''));
                }
              }),
              Container(
                width: 38,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300)),
                child: Text(
                  selected && _qteBuffer.isNotEmpty
                      ? _qteBuffer
                      : '${ligne.quantite}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected && _qteBuffer.isNotEmpty
                        ? const Color(0xFFE94560)
                        : null,
                  ),
                ),
              ),
              _qteBtn(Icons.add, () {
                try {
                  prov.modifierQuantiteLigne(
                      ligne.id, ligne.quantite + 1);
                } catch (e) {
                  _showErreur(
                      e.toString().replaceAll('Exception: ', ''));
                }
              }),
              const SizedBox(width: 8),

              // Détails
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ligne.produit.nom,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ligne.supplements.isNotEmpty)
                      Text(
                        '+ ${ligne.supplements.map((s) => s.nom).join(', ')}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (ligne.commentaire.isNotEmpty)
                      Text(
                        '📝 ${ligne.commentaire}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.blueGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              Text(
                '${_fmt.format(ligne.sousTotal)} DT',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 4),

              PopupMenuButton<String>(
                onSelected: (action) =>
                    _handleLigneAction(action, ligne),
                icon: const Icon(Icons.more_vert,
                    size: 18, color: Colors.grey),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'supplement',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.add_circle_outline),
                      title: Text('Supplément'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'commentaire',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.comment),
                      title: Text('Commentaire'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'supprimer',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qteBtn(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 26,
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF2D3561),
          shape: const RoundedRectangleBorder(),
          minimumSize: Size.zero,
        ),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }

  // ── Numpad unifié ───────────────────────────────────────────────────────────
  Widget _buildNumpad({required bool isWide}) {
    final hasSelection = _ligneSelectionneeId != null;
    final btnH = isWide ? 44.0 : 30.0;
    final fontSize = isWide ? 18.0 : 15.0;

    // Mode actuel du numpad
    final String modeLabel;
    final Color modeColor;
    if (_qteBuffer.isNotEmpty && !hasSelection) {
      modeLabel = 'Qté pré-saisie: $_qteBuffer  →  cliquez un produit';
      modeColor = const Color(0xFF2D3561);
    } else if (hasSelection && _qteBuffer.isNotEmpty) {
      modeLabel = 'Nouvelle qté: $_qteBuffer  →  ✓ pour valider';
      modeColor = Colors.green.shade700;
    } else if (hasSelection) {
      modeLabel = 'Tapez la nouvelle quantité...';
      modeColor = Colors.grey;
    } else {
      modeLabel = isWide
          ? 'Tapez la quantité puis cliquez un produit'
          : 'Tapez la quantité ou sélectionnez une ligne';
      modeColor = Colors.grey.shade400;
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      padding: EdgeInsets.symmetric(
          horizontal: 12, vertical: isWide ? 10 : 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWide)
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
          SizedBox(height: isWide ? 6 : 3),

          // Label d'état
          Row(
            children: [
              Icon(
                _qteBuffer.isNotEmpty
                    ? Icons.dialpad
                    : Icons.touch_app,
                size: 13,
                color: modeColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  modeLabel,
                  style: TextStyle(
                    color: modeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isWide ? 8 : 4),

          // Grille numpad
          Row(
            children: [
              for (final col in [
                ['1', '4', '7', '⌫'],
                ['2', '5', '8', '0'],
                ['3', '6', '9', '✓'],
              ])
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: col.map((k) {
                      final isErase = k == '⌫';
                      final isConfirm = k == '✓';
                      // ✓ actif seulement si ligne sélectionnée + buffer non vide
                      final confirmEnabled =
                          hasSelection && _qteBuffer.isNotEmpty;
                      final enabled = isConfirm ? confirmEnabled : true;

                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: SizedBox(
                          height: btnH,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: enabled
                                ? () {
                                    if (isErase) {
                                      _deleteQte();
                                    } else if (isConfirm) {
                                      _appliquerQteBuffer();
                                    } else {
                                      _appendQte(k);
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isConfirm
                                  ? Colors.green
                                  : isErase
                                      ? Colors.orange
                                      : const Color(0xFF2D3561),
                              disabledBackgroundColor:
                                  Colors.grey.shade300,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(4)),
                            ),
                            child: Text(
                              k,
                              style: TextStyle(
                                color: enabled
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Barre Total ─────────────────────────────────────────────────────────────
  Widget _buildTotalBar(AppProvider prov, {required bool isWide}) {
    final total = prov.totalCommande;
    final btnVPadding = isWide ? 11.0 : 7.0;
    final totalFontSize = isWide ? 20.0 : 17.0;
    final labelFontSize = isWide ? 15.0 : 13.0;
    final containerPadding = isWide ? 12.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: labelFontSize,
                  )),
              Text('${_fmt.format(total)} DT',
                  style: TextStyle(
                    color: const Color(0xFFE94560),
                    fontWeight: FontWeight.bold,
                    fontSize: totalFontSize,
                  )),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: prov.lignesCommande.isEmpty
                      ? null
                      : () => _valider(avecTicket: true),
                  icon: const Icon(Icons.print, size: 15),
                  label: const Text('Avec ticket',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(vertical: btnVPadding),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: prov.lignesCommande.isEmpty
                      ? null
                      : () => _valider(avecTicket: false),
                  icon: const Icon(Icons.check, size: 15),
                  label: const Text('Sans ticket',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3561),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(vertical: btnVPadding),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  ACTIONS
  // ════════════════════════════════════════════════════════
  void _handleLigneAction(String action, LigneCommande ligne) {
    final prov = context.read<AppProvider>();
    switch (action) {
      case 'supprimer':
        prov.supprimerLigne(ligne.id);
        if (_ligneSelectionneeId == ligne.id) {
          setState(() {
            _ligneSelectionneeId = null;
            _qteBuffer = '';
          });
        }
        break;
      case 'supplement':
        _showSupplements(ligne);
        break;
      case 'commentaire':
        _showCommentaire(ligne);
        break;
    }
  }

  void _showSupplements(LigneCommande ligne) {
    final prov = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final ligneActuelle = prov.lignesCommande
              .firstWhere((l) => l.id == ligne.id, orElse: () => ligne);
          return AlertDialog(
            title: Text('Suppléments — ${ligne.produit.nom}'),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ligneActuelle.supplements.isNotEmpty) ...[
                      const Text('Déjà ajoutés:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      ...ligneActuelle.supplements.map((s) => ListTile(
                            dense: true,
                            title: Text(s.nom),
                            subtitle: Text(
                                '+${s.prix.toStringAsFixed(3)} DT'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red, size: 20),
                              onPressed: () {
                                prov.supprimerSupplementLigne(
                                    ligne.id, s.id);
                                setS(() {});
                              },
                            ),
                          )),
                      const Divider(),
                    ],
                    const Text('Disponibles:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    ...prov.supplements
                        .where((s) => !ligneActuelle.supplements
                            .any((ls) => ls.id == s.id))
                        .map((s) => ListTile(
                              dense: true,
                              title: Text(s.nom),
                              subtitle: Text(
                                  '+${s.prix.toStringAsFixed(3)} DT'),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.green, size: 20),
                                onPressed: () {
                                  prov.ajouterSupplementLigne(
                                      ligne.id, s);
                                  setS(() {});
                                },
                              ),
                            )),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3561)),
                child: const Text('Fermer',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCommentaire(LigneCommande ligne) async {
    List<String> predefinis = [
      'Sans oignons',
      'Bien cuit',
      'Peu épicé',
      'Extra sauce'
    ];
    try {
      final prefs = await SharedPreferences.getInstance();
      predefinis =
          prefs.getStringList('commentaires_predefinis') ?? predefinis;
    } catch (_) {}

    if (!mounted) return;
    final ctrl = TextEditingController(text: ligne.commentaire);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Commentaire — ${ligne.produit.nom}'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                maxLines: 2,
                onTap: () => setState(() => _clavierActif = false),
                onTapOutside: (_) =>
                    setState(() => _clavierActif = true),
                decoration: const InputDecoration(
                  labelText: 'Commentaire libre',
                  border: OutlineInputBorder(),
                ),
              ),
              if (predefinis.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Rapide:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: predefinis
                      .map((c) => ActionChip(
                            label: Text(c,
                                style: const TextStyle(fontSize: 11)),
                            onPressed: () => ctrl.text = c,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                setState(() => _clavierActif = true);
                Navigator.pop(context);
              },
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              context
                  .read<AppProvider>()
                  .setCommentaireLigne(ligne.id, ctrl.text.trim());
              setState(() => _clavierActif = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3561)),
            child: const Text('Appliquer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmerAnnulation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text(
            'Voulez-vous vraiment annuler toute la commande en cours ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Non')),
          ElevatedButton(
            onPressed: () {
              context.read<AppProvider>().annulerCommande();
              setState(() {
                _ligneSelectionneeId = null;
                _qteBuffer = '';
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _valider({required bool avecTicket}) async {
    try {
      final prov = context.read<AppProvider>();
      final ticket = await prov.validerCommande(avecTicket: avecTicket);
      setState(() {
        _ligneSelectionneeId = null;
        _qteBuffer = '';
      });
      if (avecTicket && mounted) {
        await TicketService.imprimerTicket(ticket, prov.config);
      }
      if (mounted) {
        _showSucces(
          'Commande validée — Ticket N° ${ticket.numero.toString().padLeft(6, '0')}',
        );
      }
    } catch (e) {
      _showErreur(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
