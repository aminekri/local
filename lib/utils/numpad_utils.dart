// lib/utils/numpad_utils.dart
// Numpad réutilisable — fonctionne touch ET clavier PC
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Affiche un numpad modal et retourne la valeur saisie (ou null si annulé).
/// [decimal] : autorise le point décimal
/// [label]   : libellé affiché en titre
Future<String?> showNumpadInput(
  BuildContext context, {
  String initialValue = '',
  bool decimal = true,
  String label = 'Saisir la valeur',
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _NumpadDialog(
      initialValue: initialValue,
      decimal: decimal,
      label: label,
    ),
  );
}

class _NumpadDialog extends StatefulWidget {
  final String initialValue;
  final bool decimal;
  final String label;
  const _NumpadDialog({
    required this.initialValue,
    required this.decimal,
    required this.label,
  });

  @override
  State<_NumpadDialog> createState() => _NumpadDialogState();
}

class _NumpadDialogState extends State<_NumpadDialog> {
  late String _valeur;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _valeur = widget.initialValue;
    // Capture le clavier PC dès l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _append(String ch) {
    setState(() {
      // Empêcher double point décimal
      if (ch == '.' && _valeur.contains('.')) return;
      // Remplacer '0' seul par le chiffre
      if (_valeur == '0' && ch != '.') {
        _valeur = ch;
        return;
      }
      _valeur = _valeur + ch;
    });
  }

  void _effacer() {
    setState(() {
      if (_valeur.length <= 1) {
        _valeur = '';
      } else {
        _valeur = _valeur.substring(0, _valeur.length - 1);
      }
    });
  }

  void _vider() => setState(() => _valeur = '');

  void _confirmer() {
    Navigator.pop(context, _valeur.isEmpty ? null : _valeur);
  }

  // Touche clavier PC → même logique que les boutons tactiles
  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final char = event.character;
    if (char != null && RegExp(r'[0-9]').hasMatch(char)) {
      _append(char);
    } else if ((char == '.' || char == ',') && widget.decimal) {
      _append('.');
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _effacer();
    } else if (event.logicalKey == LogicalKeyboardKey.delete) {
      _vider();
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _confirmer();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _valeur.isEmpty;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        title: Text(widget.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Afficheur ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEmpty ? '0' : _valeur,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isEmpty ? Colors.white38 : Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Grille numpad ──────────────────────────────────────────
              _buildGrille(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: isEmpty ? null : _confirmer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D3561),
            ),
            child:
                const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGrille() {
    // Disposition : 1 2 3 / 4 5 6 / 7 8 9 / [.] 0 [⌫]
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [widget.decimal ? '.' : '', '0', '⌫'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Row(
          children: row.map((key) {
            if (key.isEmpty) {
              return const Expanded(child: SizedBox(height: 52));
            }
            final isErase = key == '⌫';
            final isDot = key == '.';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isErase) {
                        _effacer();
                      } else {
                        _append(key);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isErase
                          ? Colors.orange.shade700
                          : isDot
                              ? Colors.grey.shade600
                              : const Color(0xFF2D3561),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

/// Widget TextField numérique qui ouvre le numpad au tap
/// ET accepte le clavier PC directement.
class NumpadFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool decimal;
  final String? Function(String?)? validator;
  final String? suffixText;
  final String? hintText;

  const NumpadFormField({
    super.key,
    required this.controller,
    required this.label,
    this.decimal = true,
    this.validator,
    this.suffixText,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      // Clavier numérique mobile/tactile
      keyboardType: TextInputType.numberWithOptions(
        decimal: decimal,
        signed: false,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixText: suffixText,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        // Icône qui ouvre le numpad tactile
        suffixIcon: IconButton(
          icon: const Icon(Icons.dialpad, size: 20, color: Color(0xFF2D3561)),
          tooltip: 'Numpad',
          onPressed: () async {
            final result = await showNumpadInput(
              context,
              initialValue: controller.text.replaceAll(',', '.'),
              decimal: decimal,
              label: label,
            );
            if (result != null) {
              controller.text = result;
            }
          },
        ),
      ),
      validator: validator,
      // Normalise virgule → point à la saisie PC
      onChanged: decimal
          ? (v) {
              if (v.contains(',')) {
                final selection = controller.selection;
                controller.value = controller.value.copyWith(
                  text: v.replaceAll(',', '.'),
                  selection: selection,
                );
              }
            }
          : null,
    );
  }
}
