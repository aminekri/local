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
  List<Map<String, dynamic>> _topProduits = [];
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
    final t = await prov.getTopProduits(limit: 10);
    setState(() {
      _semaine = s;
      _mois = m;
      _ventesJours = v;
      _topProduits = t;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _charger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Titre ───────────────────────────────────────────────────────
            const Text('Tableau de bord',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // ── Cartes KPI ───────────────────────────────────────────────────
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
                  'Top produit',
                  _topProduits.isNotEmpty
                      ? '${_topProduits.first['nom']}'
                      : '—',
                  _topProduits.isNotEmpty
                      ? '${_topProduits.first['qte']} vendu(s)'
                      : 'aucune vente',
                  Icons.emoji_events,
                  Colors.amber.shade700,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Graphe ventes 7 jours ────────────────────────────────────────
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
                            width: 18,
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
                            if (idx < 0 || idx >= _ventesJours.length) {
                              return const SizedBox();
                            }
                            final jour =
                                _ventesJours[idx]['jour'] as String? ?? '';
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
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: true),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ════════════════════════════════════════════════════════════════
            //  TOP PRODUITS
            // ════════════════════════════════════════════════════════════════
            const Text('🏆  Top Produits',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_topProduits.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('Aucune vente enregistrée'),
                ),
              )
            else
              ..._topProduits.asMap().entries.map((e) {
                final rang = e.key + 1;
                final item = e.value;
                final qte = (item['qte'] as num?)?.toInt() ?? 0;
                final montant = (item['montant'] as num?)?.toDouble() ?? 0.0;
                final Color couleurMedaille;
                if (rang == 1) {
                  couleurMedaille = Colors.amber;
                } else if (rang == 2) {
                  couleurMedaille = Colors.blueGrey.shade400;
                } else if (rang == 3) {
                  couleurMedaille = Colors.brown.shade400;
                } else {
                  couleurMedaille = const Color(0xFF2D3561).withValues(alpha: 0.7);
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        // Médaille / rang
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: couleurMedaille,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            rang <= 3 ? ['🥇', '🥈', '🥉'][rang - 1] : '$rang',
                            style: TextStyle(
                              fontSize: rang <= 3 ? 18 : 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Nom produit
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['nom']?.toString() ?? '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '$qte vendu(s)',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // Montant
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_fmt.format(montant)} DT',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFE94560),
                              ),
                            ),
                            Text(
                              'chiffre d\'affaires',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
          ],
        ),
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
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
          Text(titre, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(sous, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}
