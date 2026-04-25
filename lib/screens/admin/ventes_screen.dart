// lib/screens/admin/ventes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';

class VentesScreen extends StatelessWidget {
  const VentesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final tickets = prov.tickets;
    final fmt = NumberFormat('#,##0.000', 'fr_TN');
    final fmtDate = DateFormat('dd/MM/yyyy HH:mm', 'fr_TN');
    final total = tickets.fold(0.0, (s, t) => s + t.total);

    return Column(
      children: [
        // ── En-tête total ──────────────────────────────
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3561),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total des ventes',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '${fmt.format(total)} DT',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.receipt, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${tickets.length} ticket(s)',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.tag, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'N° actuel: ${prov.numeroTicketActuel}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Info : remise à zéro automatique via Z-Rapport
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white54, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Le numéro de ticket est remis à 1 automatiquement '
                        'lors de l\'impression du Z-Rapport.',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Liste des tickets ──────────────────────────
        Expanded(
          child: tickets.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Aucune vente enregistrée',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tickets.length,
                  itemBuilder: (_, i) {
                    final t = tickets[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2D3561),
                          child: Text(
                            '#${t.numero}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ),
                        title: Text(
                          'Ticket N° ${t.numero.toString().padLeft(6, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(fmtDate.format(t.dateHeure)),
                        trailing: Text(
                          '${fmt.format(t.total)} DT',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3561),
                          ),
                        ),
                        children: [
                          ...t.lignes.map(
                            (l) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${l.produit.nom} ×${l.quantite}',
                                      style:
                                          const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${fmt.format(l.sousTotal)} DT',
                                    style:
                                        const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'TOTAL TTC: ${fmt.format(t.total)} DT',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
