import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class RemitoGenerator {
  
  static Future<void> generateAndPrint(Map<String, dynamic> dispatchData, List<dynamic> items) async {
    try {
      final doc = pw.Document();
      final font = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();
      String date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

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
                        pw.Text("Remito de Salida de Materiales", style: pw.TextStyle(font: font, fontSize: 14)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("N°: ${dispatchData['dispatchNumber'] ?? '---'}", style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.red)),
                        pw.Text("Fecha: $date", style: pw.TextStyle(font: font, fontSize: 12)),
                      ],
                    )
                  ]
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),

                // --- DATOS ---
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("DESTINO (OBRA): ${dispatchData['projectName'] ?? 'General'}", style: pw.TextStyle(font: fontBold, fontSize: 14)),
                      pw.Text("NOTA: ${dispatchData['note'] ?? '-'}", style: pw.TextStyle(font: font, fontSize: 12)),
                    ]
                  )
                ),
                pw.SizedBox(height: 20),

                // --- TABLA ---
                pw.Table.fromTextArray(
                  headers: ['Producto', 'Cantidad', 'Unidad'],
                  data: items.map((item) {
                    return [
                      item['productName'] ?? 'Item',
                      item['quantity'].toString(),
                      'Unid.' 
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
                  cellStyle: pw.TextStyle(font: font),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                pw.Spacer(),
                
                // --- FIRMAS ---
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(children: [pw.Container(width: 150, height: 1, color: PdfColors.black), pw.SizedBox(height: 5), pw.Text("Entregó (Pañol)")]),
                    pw.Column(children: [pw.Container(width: 150, height: 1, color: PdfColors.black), pw.SizedBox(height: 5), pw.Text("Recibió (Capataz)")]),
                  ]
                ),
              ],
            );
          },
        ),
      );

      // --- GUARDAR Y ABRIR ---
      final output = await getApplicationDocumentsDirectory();
      final fileName = "Remito_${dispatchData['dispatchNumber'] ?? 'temp'}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$fileName");

      await file.writeAsBytes(await doc.save());

      print("✅ PDF Guardado en: ${file.path}");
      await OpenFile.open(file.path);

    } catch (e) {
      print("❌ ERROR PDF: $e");
    }
  }
}