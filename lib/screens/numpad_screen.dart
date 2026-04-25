// lib/screens/numpad_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin/admin_screen.dart';
import 'caisse/caisse_screen.dart';

class NumpadScreen extends StatefulWidget {
  const NumpadScreen({super.key});

  @override
  State<NumpadScreen> createState() => _NumpadScreenState();
}

class _NumpadScreenState extends State<NumpadScreen> {
  String _saisie = '';
  String _message = '';

  void _onTouche(String valeur) {
    if (_saisie.length >= 4) return;
    setState(() => _saisie += valeur);
    _verifierCode();
  }

  void _effacer() {
    if (_saisie.isEmpty) return;
    setState(() {
      _saisie = _saisie.substring(0, _saisie.length - 1);
      _message = '';
    });
  }

  void _toutEffacer() {
    setState(() {
      _saisie = '';
      _message = '';
    });
  }

  void _verifierCode() {
    if (_saisie.length < 4) return;
    if (_saisie == '0000') {
      setState(() => _saisie = '');
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
    } else if (_saisie == '1111') {
      setState(() => _saisie = '');
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CaisseScreen()));
    } else {
      setState(() {
        _message = 'Code incorrect';
        _saisie = '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final char = event.character;
      if (char != null && RegExp(r'[0-9]').hasMatch(char)) {
        _onTouche(char);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _effacer();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _toutEffacer();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Taille bouton adaptative — évite l'overflow vertical
    final availH = size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;
    final btnSize = (availH * 0.09).clamp(52.0, 84.0);
    final fontSize = (btnSize * 0.38).clamp(16.0, 28.0);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant, size: 56, color: Color(0xFFE94560)),
                  const SizedBox(height: 10),
                  const Text(
                    'CAISSE RESTAURANT',
                    style: TextStyle(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 6),
                  const Text('Entrez votre code d\'accès',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 24),

                  // Afficheur 4 points
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE94560), width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final rempli = i < _saisie.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rempli ? const Color(0xFFE94560) : Colors.white24,
                          ),
                        );
                      }),
                    ),
                  ),

                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_message, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],

                  const SizedBox(height: 20),
                  _buildNumpad(btnSize, fontSize),
                  const SizedBox(height: 16),
                  Text('0000 = Admin  •  1111 = Caisse',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad(double btnSize, double fontSize) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((label) {
              final isErase = label == '⌫';
              final isClear = label == 'C';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: btnSize,
                  height: btnSize,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isErase) {
                        _effacer();
                      } else if (isClear) {
                        _toutEffacer();
                      } else {
                        _onTouche(label);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isClear
                          ? Colors.redAccent
                          : isErase
                              ? const Color(0xFF0F3460)
                              : const Color(0xFF16213E),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isClear
                              ? Colors.redAccent
                              : const Color(0xFFE94560).withValues(alpha: 0.5),
                        ),
                      ),
                      elevation: 4,
                    ),
                    child: Text(label,
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
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
