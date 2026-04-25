// lib/screens/admin/z_rapport_screen.dart
// Z-Rapport journalier
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/app_provider.dart';

class ZRapportScreen extends StatefulWidget {
  const ZRapportScreen({super.key});

  @override
  State<ZRapportScreen> createState() => _ZRapportScreenState();
}

class _ZRapportScreenState extends State<ZRapportScreen> {
  Map<String, dynamic>? _rapport;
  bool _loading = true;
  bool _impression = false;

  final _fmt         = NumberFormat('#,##0.000', 'fr_TN');
  final _fmtDateHeure = DateFormat('dd/MM/yyyy HH:mm:ss', 'fr_TN');
  final _fmtJour     = DateFormat('dd/MM/yyyy', 'fr_TN');

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final rapport = await context.read<AppProvider>().getZRapport();
    if (mounted) {
      setState(() {
        _rapport = rapport;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_rapport == null) return const Center(child: Text('Erreur de chargement'));

    final r           = _rapport!;
    final parProduit  = (r['par_produit'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final config      = context.read<AppProvider>().config;
    final nbTickets   = r['nb_tickets'] as int? ?? 0;
    final totalTtc    = (r['total_ttc'] as num?)?.toDouble() ?? 0.0;
    final date        = r['date'] as DateTime? ?? DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEnTete(config, date),
          const SizedBox(height: 16),
          _buildTotaux(nbTickets, totalTtc),
          const SizedBox(height: 12),
          _buildParProduit(parProduit),
          const SizedBox(height: 16),
          _buildBoutons(config, nbTickets, totalTtc, parProduit, date),
          const SizedBox(height: 12),
          _buildNoteLegale(),
        ],
      ),
    );
  }

  // ─── En-tête ────────────────────────────────────────────────────────────────
  Widget _buildEnTete(Map<String, String> config, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3561),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Z - RAPPORT JOURNALIER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoLigne('Date du rapport', _fmtJour.format(date)),
          _infoLigne('Généré le',       _fmtDateHeure.format(DateTime.now())),
          const Divider(color: Colors.white24, height: 16),
          _infoLigne('Restaurant',      config['nom_restaurant'] ?? '—'),
          _infoLigne('Adresse',         config['adresse'] ?? '—'),
          _infoLigne('Matricule Fiscal',config['mf'] ?? '—'),
        ],
      ),
    );
  }

  // ─── Totaux (SANS TVA) ──────────────────────────────────────────────────────
  Widget _buildTotaux(int nbTickets, double total) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RÉCAPITULATIF DU JOUR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2D3561),
              ),
            ),
            const Divider(),
            _totalLigne(
              'Nombre de tickets',
              '$nbTickets',
              icone: Icons.confirmation_num_outlined,
            ),
            const Divider(),
            _totalLigneGras('TOTAL', '${_fmt.format(total)} DT'),
          ],
        ),
      ),
    );
  }

  // ─── Ventes par produit ─────────────────────────────────────────────────────
  Widget _buildParProduit(List<Map<String, dynamic>> parProduit) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VENTES PAR PRODUIT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2D3561),
              ),
            ),
            const Divider(),
            if (parProduit.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucune vente aujourd\'hui',
                    style: TextStyle(color: Colors.grey)),
              )
            else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text('Produit',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                    SizedBox(width: 40, child: Text('Qté',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                    SizedBox(width: 90, child: Text('Montant',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              ...parProduit.asMap().entries.map((e) {
                final p       = e.value;
                final montant = (p['montant'] as num?)?.toDouble() ?? 0.0;
                return Container(
                  decoration: BoxDecoration(
                    color: e.key.isEven ? Colors.grey.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(p['nom'] as String? ?? '',
                            style: const TextStyle(fontSize: 13))),
                        SizedBox(width: 40, child: Text('×${p['qte']}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                        SizedBox(width: 90, child: Text('${_fmt.format(montant)} DT',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Boutons ────────────────────────────────────────────────────────────────
  Widget _buildBoutons(
    Map<String, String> config,
    int nbTickets,
    double total,
    List<Map<String, dynamic>> parProduit,
    DateTime date,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _charger,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _impression
                ? null
                : () => _imprimerZRapport(config, nbTickets, total, parProduit, date),
            icon: _impression
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.print),
            label: Text(_impression ? 'Impression...' : 'Imprimer Z'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D3561),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteLegale() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Le Z-Rapport est un document journalier obligatoire. '
              'Il doit être imprimé et archivé en fin de chaque journée.',
              style: TextStyle(fontSize: 11, color: Colors.brown),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  Widget _infoLigne(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(width: 120,
              child: Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11))),
          Expanded(child: Text(val,
              style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _totalLigne(String label, String val, {IconData? icone, Color? couleur}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icone != null) ...[
            Icon(icone, size: 16, color: couleur ?? Colors.grey.shade500),
            const SizedBox(width: 6),
          ],
          Expanded(child: Text(label,
              style: TextStyle(color: couleur ?? Colors.grey.shade700))),
          Text(val,
              style: TextStyle(fontWeight: FontWeight.w600, color: couleur)),
        ],
      ),
    );
  }

  Widget _totalLigneGras(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          Text(val,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2D3561))),
        ],
      ),
    );
  }

  // ─── Impression PDF (SANS TVA) ──────────────────────────────────────────────
  Future<void> _imprimerZRapport(
    Map<String, String> config,
    int nbTickets,
    double total,
    List<Map<String, dynamic>> parProduit,
    DateTime date,
  ) async {
    setState(() => _impression = true);
    try {
      final pdf = pw.Document();

      final boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13); // ignore: prefer_const_constructors
      final bold11    = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11); // ignore: prefer_const_constructors
      final bold12    = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12); // ignore: prefer_const_constructors
      final normal    = pw.TextStyle(fontSize: 10); // ignore: prefer_const_constructors
      final small     = pw.TextStyle(fontSize: 9);  // ignore: prefer_const_constructors
      final tiny      = pw.TextStyle(fontSize: 8);  // ignore: prefer_const_constructors

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity), // ignore: prefer_const_constructors
          margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: pw.Text('*** Z - RAPPORT ***', style: boldStyle)),
              pw.SizedBox(height: 3),
              pw.Center(child: pw.Text(config['nom_restaurant'] ?? '',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold))), // ignore: prefer_const_constructors
              if ((config['adresse'] ?? '').isNotEmpty)
                pw.Center(child: pw.Text(config['adresse']!, style: tiny)),
              if ((config['mf'] ?? '').isNotEmpty)
                pw.Center(child: pw.Text('MF: ${config['mf']}', style: tiny)),
              pw.Divider(),
              _pdfLigne('Date:',     _fmtJour.format(date), normal),
              _pdfLigne('Imprimé:', _fmtDateHeure.format(DateTime.now()), normal),
              pw.Divider(),
              pw.Text('RÉCAPITULATIF',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)), // ignore: prefer_const_constructors
              pw.SizedBox(height: 4),
              _pdfLigne('Nb tickets:', '$nbTickets', normal),
              pw.Divider(),
              _pdfLigneGras('TOTAL:', '${_fmt.format(total)} DT', bold12),
              pw.Divider(),
              pw.Text('VENTES PAR PRODUIT',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)), // ignore: prefer_const_constructors
              pw.SizedBox(height: 4),
              if (parProduit.isEmpty)
                pw.Text('Aucune vente', style: small)
              else
                ...parProduit.map((p) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(
                          '${p['nom']} ×${p['qte']}', style: small)),
                      pw.Text(
                          '${_fmt.format((p['montant'] as num?)?.toDouble() ?? 0)} DT',
                          style: small),
                    ],
                  ),
                )),
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text('Document journalier — À conserver', style: tiny)),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => pdf.save());

      if (mounted) {
        await context.read<AppProvider>().resetNumeroTicketSeulement();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Z-Rapport imprimé — N° ticket remis à 1',
                  style: TextStyle(color: Colors.white))),
            ]),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        await _charger();
      }
    } finally {
      if (mounted) setState(() => _impression = false);
    }
  }

  pw.Widget _pdfLigne(String label, String val, pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(label, style: style), pw.Text(val, style: style)],
    );
  }

  pw.Widget _pdfLigneGras(String label, String val, pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(label, style: style), pw.Text(val, style: style)],
    );
  }
}
