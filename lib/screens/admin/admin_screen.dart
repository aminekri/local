// lib/screens/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'stats_screen.dart';
import 'ventes_screen.dart';
import 'supplements_screen.dart';
import 'categories_screen.dart';
import 'produits_screen.dart';
import 'commentaires_screen.dart';
import 'z_rapport_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(Icons.bar_chart,      'Statistiques', StatsScreen()),
    _NavItem(Icons.receipt_long,   'Ventes',        VentesScreen()),
    _NavItem(Icons.summarize,      'Z-Rapport',     ZRapportScreen()),
    _NavItem(Icons.add_circle_outline, 'Suppléments', SupplementsScreen()),
    _NavItem(Icons.category,       'Catégories',    CategoriesScreen()),
    _NavItem(Icons.fastfood,       'Produits',      ProduitsScreen()),
    _NavItem(Icons.comment,        'Commentaires',  CommentairesScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(_items[_selectedIndex].label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D3561),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.exit_to_app, color: Colors.white70),
            label: const Text('Quitter', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: isWide
          ? Row(children: [
              _buildSideNav(),
              Expanded(child: _items[_selectedIndex].screen),
            ])
          : _items[_selectedIndex].screen,
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 200,
      color: const Color(0xFF2D3561),
      child: Column(children: [
        const SizedBox(height: 16),
        const Icon(Icons.restaurant, color: Colors.white, size: 36),
        const SizedBox(height: 4),
        const Text('Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              final selected = i == _selectedIndex;
              return ListTile(
                leading: Icon(item.icon, color: selected ? Colors.white : Colors.white60, size: 20),
                title: Text(item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white60,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    )),
                selected: selected,
                selectedTileColor: Colors.white.withValues(alpha: 0.15),
                onTap: () => setState(() => _selectedIndex = i),
                dense: true,
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomNav() {
    // Seulement 4 items en mobile (limite BottomNavigationBar)
    // On affiche les 4 premiers + "Plus"
    return BottomNavigationBar(
      currentIndex: _selectedIndex < 4 ? _selectedIndex : 4,
      onTap: (i) {
        if (i < 4) {
          setState(() => _selectedIndex = i);
        } else {
          _showMoreMenu();
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2D3561),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: [
        BottomNavigationBarItem(icon: Icon(_items[0].icon), label: _items[0].label),
        BottomNavigationBarItem(icon: Icon(_items[1].icon), label: _items[1].label),
        BottomNavigationBarItem(icon: Icon(_items[2].icon), label: _items[2].label),
        BottomNavigationBarItem(icon: Icon(_items[3].icon), label: _items[3].label),
        const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Plus'),
      ],
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: _items.skip(4).indexed.map((e) {
          final idx = e.$1 + 4;
          final item = e.$2;
          return ListTile(
            leading: Icon(item.icon, color: const Color(0xFF2D3561)),
            title: Text(item.label),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = idx);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  const _NavItem(this.icon, this.label, this.screen);
}
