// lib/utils/ticket_service.dart
// Impression ticket fiscal conforme réglementation tunisienne
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
    final tva = ticket.total - (ticket.total / 1.19);
    final ht = ticket.total / 1.19;

    final bold14 = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14); // ignore: prefer_const_constructors
    final bold10 = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10); // ignore: prefer_const_constructors
    final bold11 = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11); // ignore: prefer_const_constructors
    final style8 = pw.TextStyle(fontSize: 8); // ignore: prefer_const_constructors
    final style9 = pw.TextStyle(fontSize: 9); // ignore: prefer_const_constructors
    final style7 = pw.TextStyle(fontSize: 7); // ignore: prefer_const_constructors
    final italicStyle = pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic); // ignore: prefer_const_constructors

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(58 * PdfPageFormat.mm, double.infinity), // ignore: prefer_const_constructors
        margin: pw.EdgeInsets.all(4), // ignore: prefer_const_constructors
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // En-tête restaurant
            pw.Text(config['nom_restaurant'] ?? 'Restaurant', style: bold14),
            pw.SizedBox(height: 2),
            pw.Text(config['adresse'] ?? '', style: style8),
            pw.Text('MF: ${config['mf'] ?? ''}', style: style8),
            pw.Divider(),

            // Numéro ticket
            pw.Text(
              'TICKET N° ${ticket.numero.toString().padLeft(6, '0')}',
              style: bold10,
            ),
            pw.Text(_fmtDate.format(ticket.dateHeure), style: style8),
            pw.Divider(),

            // Lignes commande
            ...ticket.lignes.map((ligne) => pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${ligne.produit.nom} x${ligne.quantite}',
                            style: style9,
                          ),
                        ),
                        pw.Text(
                          '${_fmt.format(ligne.sousTotal)} DT',
                          style: style9,
                        ),
                      ],
                    ),
                    ...ligne.supplements.map(
                      (s) => pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('  + ${s.nom}', style: style8),
                          pw.Text('${_fmt.format(s.prix)} DT', style: style8),
                        ],
                      ),
                    ),
                    if (ligne.commentaire.isNotEmpty)
                      pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Text(
                          '  Note: ${ligne.commentaire}',
                          style: italicStyle,
                        ),
                      ),
                  ],
                )),

            pw.Divider(),

            // Totaux fiscaux Tunisie
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('HT:', style: style9),
                pw.Text('${_fmt.format(ht)} DT', style: style9),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TVA 19%:', style: style9),
                pw.Text('${_fmt.format(tva)} DT', style: style9),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL TTC:', style: bold11),
                pw.Text('${_fmt.format(ticket.total)} DT', style: bold11),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('Merci de votre visite!', style: style8),
            pw.Text('www.impots.finances.gov.tn', style: style7),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}