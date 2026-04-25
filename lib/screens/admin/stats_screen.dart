// lib/screens/admin/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic> _semaine = {};
  Map<String, dynamic> _mois = {};
  List<Map<String, dynamic>> _ventesJours = [];
  bool _loading = true;
  final _fmt = NumberFormat('#,##0.000', 'fr_TN');

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prov = context.read<AppProvider>();
    final s = await prov.getStatsSemaine();
    final m = await prov.getStatsMois();
    final v = await prov.getVentesParJour(7);
    setState(() {
      _semaine = s;
      _mois = m;
      _ventesJours = v;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tableau de bord',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard(
                'Ventes cette semaine',
                '${_fmt.format(_semaine['total'] ?? 0)} DT',
                '${_semaine['nb_tickets'] ?? 0} tickets',
                Icons.calendar_view_week,
                const Color(0xFF2D3561),
              ),
              _statCard(
                'Ventes ce mois',
                '${_fmt.format(_mois['total'] ?? 0)} DT',
                '${_mois['nb_tickets'] ?? 0} tickets',
                Icons.calendar_month,
                const Color(0xFFE94560),
              ),
              _statCard(
                'Alertes stock',
                '${context.watch<AppProvider>().ingredients.where((i) => i.estEnRupture).length}',
                'ingrédients en rupture',
                Icons.warning_amber,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_ventesJours.isNotEmpty) ...[
            const Text('Ventes 7 derniers jours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _ventesJours.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: (e.value['total'] as num?)?.toDouble() ?? 0,
                          color: const Color(0xFF2D3561),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= _ventesJours.length) return const SizedBox();
                          final jour = _ventesJours[idx]['jour'] as String? ?? '';
                          return Text(
                            jour.length >= 5 ? jour.substring(5) : jour,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()} DT',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Alertes de stock',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...context.watch<AppProvider>().ingredients
              .where((i) => i.estEnRupture)
              .map((i) => Card(
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber, color: Colors.orange),
                      title: Text(i.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'Stock: ${i.quantite} ${i.unite} | Seuil: ${i.seuilAlerte} ${i.unite}'),
                      trailing: i.estImportant
                          ? const Chip(
                              label: Text('Important', style: TextStyle(fontSize: 11)),
                              backgroundColor: Colors.red,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                  )),
          if (context.watch<AppProvider>().ingredients.where((i) => i.estEnRupture).isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Tous les stocks sont suffisants'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String titre, String valeur, String sous, IconData icon, Color couleur) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 8),
          Text(valeur,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(titre, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(sous, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}
