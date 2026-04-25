// lib/utils/ticket_service.dart
// Impression ticket 80mm — ticket client + bon de cuisine
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class TicketService {
  static final _fmt = NumberFormat('#,##0.000', 'fr_TN');
  static final _fmtDate = DateFormat('dd/MM/yyyy HH:mm', 'fr_TN');

  static Future<void> imprimerTicket(
      Ticket ticket, Map<String, String> config) async {
    final pdf = pw.Document();

    final bold16 = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16);
    final bold13 = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13);
    final bold12 = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12);
    final bold11 = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11);
    final style10 = pw.TextStyle(fontSize: 10);
    final style9  = pw.TextStyle(fontSize: 9);
    final style8  = pw.TextStyle(fontSize: 8);
    final italic9 = pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic);

    // ════════════════════════════════════════════════════════════════════════
    //  PAGE 1 — TICKET CLIENT (avec prix)
    // ════════════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              config['nom_restaurant'] ?? 'Restaurant',
              style: bold16,
              textAlign: pw.TextAlign.center,
            ),
            if ((config['adresse'] ?? '').isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(config['adresse']!, style: style9, textAlign: pw.TextAlign.center),
            ],
            if ((config['mf'] ?? '').isNotEmpty)
              pw.Text('MF: ${config['mf']}', style: style8, textAlign: pw.TextAlign.center),
            pw.Divider(thickness: 1),
            pw.Text(
              'TICKET N° ${ticket.numero.toString().padLeft(6, '0')}',
              style: bold12,
            ),
            pw.Text(_fmtDate.format(ticket.dateHeure), style: style8),
            pw.Divider(thickness: 0.5),
            ...ticket.lignes.map((ligne) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${ligne.quantite} x ${ligne.produit.nom}', style: bold11),
                      ),
                      pw.Text('${_fmt.format(ligne.sousTotal)} DT', style: bold11),
                    ],
                  ),
                  ...ligne.supplements.map((s) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('  + ${s.nom}', style: style9),
                      pw.Text('+${_fmt.format(s.prix)} DT', style: style9),
                    ],
                  )),
                  if (ligne.commentaire.isNotEmpty)
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text('  Note: ${ligne.commentaire}', style: italic9),
                    ),
                ],
              ),
            )),
            pw.Divider(thickness: 1),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL:', style: bold13),
                pw.Text('${_fmt.format(ticket.total)} DT', style: bold13),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text('Merci de votre visite !', style: style9, textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );

    // ════════════════════════════════════════════════════════════════════════
    //  PAGE 2 — BON DE CUISINE (sans prix)
    // ════════════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text('=====  BON DE CUISINE  =====', style: bold16)),
            pw.Center(child: pw.Text('N° ${ticket.numero.toString().padLeft(6, '0')}', style: bold13)),
            pw.Center(child: pw.Text(_fmtDate.format(ticket.dateHeure), style: style9)),
            pw.Divider(thickness: 1.5),
            ...ticket.lignes.map((ligne) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${ligne.quantite}x  ${ligne.produit.nom.toUpperCase()}',
                    style: bold13,
                  ),
                  ...ligne.supplements.map((s) => pw.Text('    + ${s.nom}', style: style10)),
                  if (ligne.commentaire.isNotEmpty)
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 2, left: 4),
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(left: pw.BorderSide(width: 2)),
                      ),
                      child: pw.Text(
                        '! ${ligne.commentaire}',
                        style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                ],
              ),
            )),
            pw.Divider(thickness: 1.5),
            pw.Center(
              child: pw.Text(
                '${ticket.lignes.fold(0, (s, l) => s + l.quantite)} article(s)',
                style: bold11,
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
