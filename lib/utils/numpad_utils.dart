// lib/utils/numpad_utils.dart
// Numpad tactile optimisé — grands boutons rectangulaires pour tablette
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Couleurs globales du thème
const _kPrimary   = Color(0xFF1A1A2E);
const _kAccent    = Color(0xFF2D3561);
const _kErase     = Color(0xFFD84315);
const _kConfirm   = Color(0xFF2E7D32);
const _kDot       = Color(0xFF455A64);

/// Affiche un numpad modal et retourne la valeur saisie (ou null si annulé).
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
      if (ch == '.' && _valeur.contains('.')) return;
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
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Afficheur
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isEmpty ? '0' : _valeur,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isEmpty ? Colors.white38 : Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Grille numpad
              _buildGrille(),
              const SizedBox(height: 14),

              // Boutons Annuler / OK
              Row(
                children: [
                  Expanded(
                    child: _TouchBtn(
                      label: 'Annuler',
                      color: Colors.grey.shade200,
                      textColor: Colors.black87,
                      height: 52,
                      fontSize: 15,
                      onTap: () => Navigator.pop(context, null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _TouchBtn(
                      label: 'Confirmer ✓',
                      color: _kConfirm,
                      textColor: Colors.white,
                      height: 52,
                      fontSize: 15,
                      onTap: isEmpty ? null : _confirmer,
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

  Widget _buildGrille() {
    final rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      [widget.decimal ? '.' : '', '0', '⌫'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              if (key.isEmpty) {
                return const Expanded(child: SizedBox());
              }
              final isErase = key == '⌫';
              final isDot   = key == '.';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _TouchBtn(
                    label: key,
                    color: isErase ? _kErase : isDot ? _kDot : _kAccent,
                    textColor: Colors.white,
                    height: 62,
                    fontSize: 24,
                    onTap: () {
                      if (isErase) {
                        _effacer();
                      } else {
                        _append(key);
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

/// Bouton tactile unifié — grand rectangle avec retour visuel
class _TouchBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final double height;
  final double fontSize;
  final VoidCallback? onTap;

  const _TouchBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.height,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? Colors.grey.shade300 : color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        splashColor: Colors.white24,
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: onTap == null ? Colors.grey.shade500 : textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
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
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
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
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            suffixText: suffixText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            filled: true,
            fillColor: const Color(0xFFF0F4FF),
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.dialpad, size: 28, color: _kAccent),
            ),
          ),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _kPrimary,
          ),
          validator: validator,
        ),
      ),
    );
  }
}
