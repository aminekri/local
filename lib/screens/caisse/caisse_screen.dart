// lib/screens/caisse/caisse_screen.dart  — v12 Touch Optimized
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../utils/ticket_service.dart';
import '../../utils/numpad_utils.dart';

// ── Constantes de taille tactile ─────────────────────────────────────────────
const _kTouchMin   = 56.0;   // hauteur minimale d'un élément tactile
const _kBtnRadius  = 10.0;
const _kPrimary    = Color(0xFF1A1A2E);
const _kAccent     = Color(0xFF2D3561);
const _kRed        = Color(0xFFE94560);
const _kGreen      = Color(0xFF2E7D32);
const _kBg         = Color(0xFFF0F2F5);

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

  String _qteBuffer = '';
  String? _ligneSelectionneeId;
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

  bool _onKey(KeyEvent event) {
    if (!_clavierActif) return false;
    if (event is! KeyDownEvent) return false;
    final char = event.character;
    if (char != null && RegExp(r'[0-9]').hasMatch(char)) { _appendQte(char); return true; }
    if (event.logicalKey == LogicalKeyboardKey.backspace) { _deleteQte(); return true; }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_ligneSelectionneeId != null && _qteBuffer.isNotEmpty) _appliquerQteBuffer();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) { _resetBuffer(); return true; }
    return false;
  }

  void _appendQte(String digit) {
    setState(() {
      _qteBuffer = _qteBuffer + digit;
      if (_qteBuffer.startsWith('0') && _qteBuffer.length > 1) {
        _qteBuffer = _qteBuffer.replaceFirst(RegExp(r'^0+'), '');
      }
    });
  }

  void _deleteQte() {
    if (_qteBuffer.isEmpty) return;
    setState(() {
      _qteBuffer = _qteBuffer.length > 1 ? _qteBuffer.substring(0, _qteBuffer.length - 1) : '';
    });
  }

  void _resetBuffer() {
    setState(() { _qteBuffer = ''; _ligneSelectionneeId = null; });
  }

  int get _qteEffective => int.tryParse(_qteBuffer) ?? 1;

  void _ajouterProduit(Produit p) {
    final prov = context.read<AppProvider>();
    final qte = _qteEffective;
    try {
      prov.ajouterProduitAvecQuantite(p, qte);
    } catch (e) {
      _showErreur(e.toString().replaceAll('Exception: ', ''));
    }
    setState(() { _qteBuffer = ''; _ligneSelectionneeId = null; });
  }

  void _appliquerQteBuffer() {
    if (_ligneSelectionneeId == null || _qteBuffer.isEmpty) return;
    try {
      context.read<AppProvider>().modifierQuantiteLigne(_ligneSelectionneeId!, _qteEffective);
    } catch (e) {
      _showErreur(e.toString().replaceAll('Exception: ', ''));
    }
    setState(() { _qteBuffer = ''; _ligneSelectionneeId = null; });
  }

  void _showErreur(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
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
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('CAISSE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3, fontSize: 20)),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        toolbarHeight: 60,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                DateFormat('dd/MM/yyyy  HH:mm').format(DateTime.now()),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: isWide
          ? Row(children: [
              Expanded(flex: 5, child: _buildCatalogue(isWide: true)),
              Container(width: 1, color: Colors.grey.shade300),
              SizedBox(width: size.width * 0.40, child: _buildPanier(isWide: true)),
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
      produits = produits.where((p) => p.categorieId == _filtreCategorie).toList();
    }
    if (_recherche.isNotEmpty) {
      produits = produits.where((p) => p.nom.toLowerCase().contains(_recherche.toLowerCase())).toList();
    }

    return Column(
      children: [
        // ── Barre de recherche (grande, tactile) ─────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            height: 54,
            child: TextField(
              controller: _searchCtrl,
              onTap: () => setState(() => _clavierActif = false),
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
                setState(() => _clavierActif = true);
              },
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: const TextStyle(fontSize: 15),
                prefixIcon: const Icon(Icons.search, size: 26),
                suffixIcon: _recherche.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 24),
                        onPressed: () { _searchCtrl.clear(); setState(() => _recherche = ''); },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) => setState(() => _recherche = v),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Filtres catégories (grands chips) ─────────────────────────────
        SizedBox(
          height: 46,
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

        // ── Grille produits ───────────────────────────────────────────────
        Expanded(
          child: produits.isEmpty
              ? const Center(child: Text('Aucun produit trouvé', style: TextStyle(fontSize: 16)))
              : LayoutBuilder(builder: (_, constraints) {
                  final cols = constraints.maxWidth > 700
                      ? 4
                      : constraints.maxWidth > 480
                          ? 3
                          : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: produits.length,
                    itemBuilder: (_, i) => _buildProduitCard(produits[i]),
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
      child: GestureDetector(
        onTap: () => setState(() => _filtreCategorie = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _kAccent : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProduitCard(Produit p) {
    final qteLabel = _qteBuffer.isNotEmpty ? '×$_qteBuffer' : '';

    return GestureDetector(
      onTap: () => _ajouterProduit(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kBtnRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_kBtnRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(_kBtnRadius),
            onTap: () => _ajouterProduit(p),
            splashColor: _kAccent.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge quantité pré-saisie
                  if (qteLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(qteLabel,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fastfood, size: 26, color: _kAccent),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    p.nom,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_fmt.format(p.prix)} DT',
                      style: const TextStyle(
                        color: _kRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // En-tête panier
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: _kPrimary,
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text('COMMANDE',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                if (lignes.isNotEmpty)
                  TextButton(
                    onPressed: _confirmerAnnulation,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                    child: const Text('Annuler tout',
                        style: TextStyle(color: Colors.redAccent, fontSize: 14)),
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
                        Icon(Icons.receipt_long, size: 52, color: Colors.grey.shade200),
                        const SizedBox(height: 10),
                        Text('Commande vide',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: lignes.length,
                    itemBuilder: (_, i) => _buildLigneCommande(lignes[i]),
                  ),
          ),

          // Numpad intégré
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
            _ligneSelectionneeId = null;
            _qteBuffer = '';
          } else {
            _ligneSelectionneeId = ligne.id;
            _qteBuffer = '${ligne.quantite}';
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withValues(alpha: 0.06) : null,
          border: Border(
            left: BorderSide(
              color: selected ? _kAccent : Colors.transparent,
              width: 4,
            ),
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              // ── Boutons quantité (grands, tactiles) ─────────────────────
              _qteBtn(Icons.remove, () {
                try {
                  prov.modifierQuantiteLigne(ligne.id, ligne.quantite - 1);
                  if (ligne.quantite - 1 <= 0 && _ligneSelectionneeId == ligne.id) {
                    setState(() => _ligneSelectionneeId = null);
                  }
                } catch (e) {
                  _showErreur(e.toString().replaceAll('Exception: ', ''));
                }
              }),

              // Affichage quantité
              Container(
                width: 46,
                height: _kTouchMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  color: selected ? _kAccent.withValues(alpha: 0.05) : null,
                ),
                child: Text(
                  selected && _qteBuffer.isNotEmpty ? _qteBuffer : '${ligne.quantite}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: selected && _qteBuffer.isNotEmpty ? _kRed : Colors.black87,
                  ),
                ),
              ),

              _qteBtn(Icons.add, () {
                try {
                  prov.modifierQuantiteLigne(ligne.id, ligne.quantite + 1);
                } catch (e) {
                  _showErreur(e.toString().replaceAll('Exception: ', ''));
                }
              }),
              const SizedBox(width: 10),

              // Détails
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ligne.produit.nom,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ligne.supplements.isNotEmpty)
                      Text(
                        '+ ${ligne.supplements.map((s) => s.nom).join(', ')}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (ligne.commentaire.isNotEmpty)
                      Text(
                        '📝 ${ligne.commentaire}',
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              Text(
                '${_fmt.format(ligne.sousTotal)} DT',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 4),

              // Menu contextuel (icône plus grande)
              SizedBox(
                width: 40,
                height: _kTouchMin,
                child: PopupMenuButton<String>(
                  onSelected: (action) => _handleLigneAction(action, ligne),
                  icon: const Icon(Icons.more_vert, size: 24, color: Colors.grey),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'supplement',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.add_circle_outline),
                        title: Text('Supplément'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'commentaire',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.comment),
                        title: Text('Commentaire'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'supprimer',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouton +/- grand et tactile
  Widget _qteBtn(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 44,
      height: _kTouchMin,
      child: Material(
        color: _kAccent,
        child: InkWell(
          onTap: onPressed,
          splashColor: Colors.white24,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  // ── Numpad intégré (toujours visible) ──────────────────────────────────────
  Widget _buildNumpad({required bool isWide}) {
    final hasSelection = _ligneSelectionneeId != null;
    final btnH = isWide ? 54.0 : 42.0;
    final fontSize = isWide ? 20.0 : 18.0;

    final String modeLabel;
    final Color modeColor;
    if (_qteBuffer.isNotEmpty && !hasSelection) {
      modeLabel = 'Qté pré-saisie: $_qteBuffer  →  cliquez un produit';
      modeColor = _kAccent;
    } else if (hasSelection && _qteBuffer.isNotEmpty) {
      modeLabel = 'Nouvelle qté: $_qteBuffer  →  ✓ pour valider';
      modeColor = _kGreen;
    } else if (hasSelection) {
      modeLabel = 'Tapez la nouvelle quantité...';
      modeColor = Colors.grey;
    } else {
      modeLabel = 'Saisir la quantité ou sélectionner une ligne';
      modeColor = Colors.grey.shade400;
    }

    return Container(
      color: const Color(0xFFF4F6FA),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isWide ? 10 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 8),

          // ── Afficheur de saisie ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _qteBuffer.isNotEmpty ? Icons.dialpad : Icons.touch_app,
                  size: 16,
                  color: Colors.white54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    modeLabel,
                    style: TextStyle(color: modeColor == Colors.grey.shade400
                        ? Colors.white38 : Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _qteBuffer.isEmpty ? '—' : _qteBuffer,
                  style: TextStyle(
                    color: _qteBuffer.isEmpty ? Colors.white24 : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Grille 3 colonnes ───────────────────────────────────────────
          Row(
            children: [
              for (final col in [
                ['7', '4', '1', '⌫'],
                ['8', '5', '2', '0'],
                ['9', '6', '3', '✓'],
              ])
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: col.map((k) {
                      final isErase   = k == '⌫';
                      final isConfirm = k == '✓';
                      final confirmEnabled = hasSelection && _qteBuffer.isNotEmpty;
                      final enabled = isConfirm ? confirmEnabled : true;

                      Color btnColor;
                      if (isConfirm) {
                        btnColor = _kGreen;
                      } else if (isErase) {
                        btnColor = const Color(0xFFD84315);
                      } else {
                        btnColor = _kAccent;
                      }

                      return Padding(
                        padding: const EdgeInsets.all(3),
                        child: Material(
                          color: enabled ? btnColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(_kBtnRadius),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(_kBtnRadius),
                            onTap: enabled
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
                            splashColor: Colors.white24,
                            child: SizedBox(
                              height: btnH,
                              child: Center(
                                child: Text(
                                  k,
                                  style: TextStyle(
                                    color: enabled ? Colors.white : Colors.grey.shade500,
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    final containerPadding = isWide ? 14.0 : 10.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: _kPrimary,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${_fmt.format(total)} DT',
                  style: const TextStyle(
                      color: _kRed, fontWeight: FontWeight.bold, fontSize: 24)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Avec ticket',
                  icon: Icons.print,
                  color: _kGreen,
                  height: 56,
                  enabled: prov.lignesCommande.isNotEmpty,
                  onTap: () => _valider(avecTicket: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Sans ticket',
                  icon: Icons.check_circle,
                  color: _kAccent,
                  height: 56,
                  enabled: prov.lignesCommande.isNotEmpty,
                  onTap: () => _valider(avecTicket: false),
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
          setState(() { _ligneSelectionneeId = null; _qteBuffer = ''; });
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
          final ligneActuelle = prov.lignesCommande.firstWhere((l) => l.id == ligne.id, orElse: () => ligne);
          return AlertDialog(
            title: Text('Suppléments — ${ligne.produit.nom}'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ligneActuelle.supplements.isNotEmpty) ...[
                      const Text('Déjà ajoutés:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ...ligneActuelle.supplements.map((s) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            title: Text(s.nom),
                            subtitle: Text('+${s.prix.toStringAsFixed(3)} DT'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 26),
                              onPressed: () { prov.supprimerSupplementLigne(ligne.id, s.id); setS(() {}); },
                            ),
                          )),
                      const Divider(),
                    ],
                    const Text('Disponibles:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ...prov.supplements
                        .where((s) => !ligneActuelle.supplements.any((ls) => ls.id == s.id))
                        .map((s) => ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              title: Text(s.nom),
                              subtitle: Text('+${s.prix.toStringAsFixed(3)} DT'),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green, size: 26),
                                onPressed: () { prov.ajouterSupplementLigne(ligne.id, s); setS(() {}); },
                              ),
                            )),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: _kAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                child: const Text('Fermer', style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCommentaire(LigneCommande ligne) async {
    List<String> predefinis = ['Sans oignons', 'Bien cuit', 'Peu épicé', 'Extra sauce'];
    try {
      final prefs = await SharedPreferences.getInstance();
      predefinis = prefs.getStringList('commentaires_predefinis') ?? predefinis;
    } catch (_) {}

    if (!mounted) return;
    final ctrl = TextEditingController(text: ligne.commentaire);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Commentaire — ${ligne.produit.nom}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 16),
                onTap: () => setState(() => _clavierActif = false),
                onTapOutside: (_) => setState(() => _clavierActif = true),
                decoration: const InputDecoration(
                  labelText: 'Commentaire libre',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              if (predefinis.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Rapide:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: predefinis.map((c) => GestureDetector(
                        onTap: () => ctrl.text = c,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _kAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(c, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      )).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { setState(() => _clavierActif = true); Navigator.pop(context); },
            child: const Text('Annuler', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppProvider>().setCommentaireLigne(ligne.id, ctrl.text.trim());
              setState(() => _clavierActif = true);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Appliquer', style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void _confirmerAnnulation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler la commande', style: TextStyle(fontSize: 18)),
        content: const Text('Voulez-vous vraiment annuler toute la commande en cours ?', style: TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppProvider>().annulerCommande();
              setState(() { _ligneSelectionneeId = null; _qteBuffer = ''; });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Future<void> _valider({required bool avecTicket}) async {
    try {
      final prov = context.read<AppProvider>();
      final ticket = await prov.validerCommande(avecTicket: avecTicket);
      setState(() { _ligneSelectionneeId = null; _qteBuffer = ''; });
      if (avecTicket && mounted) {
        await TicketService.imprimerTicket(ticket, prov.config);
      }
      if (mounted) {
        _showSucces('Commande validée — Ticket N° ${ticket.numero.toString().padLeft(6, '0')}');
      }
    } catch (e) {
      _showErreur(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

/// Bouton d'action principal (Valider / Imprimer)
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double height;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.height,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color : Colors.grey.shade600,
      borderRadius: BorderRadius.circular(_kBtnRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_kBtnRadius),
        onTap: enabled ? onTap : null,
        splashColor: Colors.white24,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
