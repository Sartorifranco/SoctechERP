import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class InvoiceGenerator {
  
  static Future<void> generate(Map<String, dynamic> invoiceData) async {
    try {
      final doc = pw.Document();
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();
      
      final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
      String date = DateFormat('dd/MM/yyyy').format(DateTime.now());

      // Extraer datos con seguridad (si es nulo, pone 0)
      final double net = (invoiceData['netAmount'] ?? 0).toDouble();
      final double vatPct = (invoiceData['vatPercentage'] ?? 21).toDouble();
      final double retainagePct = (invoiceData['retainagePercentage'] ?? 0).toDouble();
      
      // Recalculamos para asegurar consistencia visual en el PDF
      final double vatAmount = net * (vatPct / 100);
      final double total = net + vatAmount;
      final double retainageAmount = net * (retainagePct / 100);
      final double collectible = total - retainageAmount;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // --- ENCABEZADO ---
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("SOCTECH CONSTRUCTORA", style: pw.TextStyle(font: fontBold, fontSize: 20)),
                        pw.Text("Av. Principal 123, Córdoba"),
                        pw.Text("IVA Responsable Inscripto"),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Column(
                        children: [
                          pw.Text("FACTURA A", style: pw.TextStyle(font: fontBold, fontSize: 24)),
                          pw.Text("N° 0001-0000${DateTime.now().millisecond}", style: pw.TextStyle(font: font, fontSize: 14)),
                          pw.Text("Fecha: $date", style: pw.TextStyle(font: font, fontSize: 12)),
                        ],
                      ),
                    )
                  ]
                ),
                pw.SizedBox(height: 20),

                // --- DATOS CLIENTE ---
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.grey200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("CLIENTE: ${invoiceData['clientName'] ?? 'Consumidor Final'}", style: pw.TextStyle(font: fontBold)),
                      pw.Text("CUIT: ${invoiceData['clientCuit'] ?? '-'}"),
                      pw.Text("OBRA ID: ${invoiceData['projectId'] ?? '-'}"),
                    ]
                  )
                ),
                pw.SizedBox(height: 20),

                // --- DETALLE ---
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Concepto", style: pw.TextStyle(font: fontBold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text("Importe Neto", style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right)),
                      ]
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(invoiceData['concept'] ?? '-')),
                        pw.Padding(padding: const pw.EdgeInsets.all(10), child: pw.Text(currencyFormat.format(net), textAlign: pw.TextAlign.right)),
                      ]
                    )
                  ]
                ),
                pw.SizedBox(height: 20),

                // --- TOTALES ---
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Subtotal Neto: ${currencyFormat.format(net)}"),
                        pw.Text("IVA ($vatPct%): ${currencyFormat.format(vatAmount)}"),
                        pw.Divider(),
                        pw.Text("TOTAL FACTURA: ${currencyFormat.format(total)}", style: pw.TextStyle(font: fontBold, fontSize: 14)),
                        if (retainageAmount > 0) ...[
                          pw.SizedBox(height: 5),
                          pw.Text("(-) Fondo Reparo ($retainagePct%): ${currencyFormat.format(retainageAmount)}", style: const pw.TextStyle(color: PdfColors.red)),
                          pw.Divider(),
                          pw.Text("A COBRAR: ${currencyFormat.format(collectible)}", style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green900)),
                        ]
                      ]
                    )
                  ]
                ),

                pw.Spacer(),
                pw.Divider(),
                pw.Center(child: pw.Text("Documento generado electrónicamente por Soctech ERP", style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10))),
              ],
            );
          },
        ),
      );

      // --- GUARDAR Y ABRIR ---
      final output = await getApplicationDocumentsDirectory();
      final fileName = "Factura_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$fileName");

      await file.writeAsBytes(await doc.save());
      
      print("✅ Factura PDF generada: ${file.path}");
      await OpenFile.open(file.path);

    } catch (e) {
      print("❌ ERROR PDF: $e");
    }
  }
}