import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:zsdk/zsdk.dart' as Printer;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController ipController =
  TextEditingController(text: '0.tcp.sa.ngrok.io');
  final TextEditingController portController =
  TextEditingController(text: '15801');
  final TextEditingController textController = TextEditingController();

  final Printer.ZSDK zsdk = Printer.ZSDK();

  String qrFormat = 'json';
  final List<String> qrFormats = ['json', 'csv'];

  final Map<String, String> etiquetaData = {
    "N° etiqueta impresión": "IMP-000002",
    "N° etiqueta extrusión": "EXT-000003",
    "Orden Prod.": "OPIMP-005",
    "Fecha": "26/07/2024",
    "Turno": "Turno 2",
    "Operador": "Pedro Sanchez",
    "Máquina": "15",
    "Tipo Producto": "Emp. Tarrina diamante",
    "Color prep.": "Transparente",
    "Peso Neto Extrusión": "130",
    "Peso Neto Impresión": "120",
    "Densidad": "Baja",
    "Cliente": "Stock"
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      populateTextField();  // Poblar después de que se construya la UI
    });
  }

  void populateTextField() {
    setState(() {
      textController.text = etiquetaData.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Generar PDF y enviar a Zebra"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: ipController,
              decoration: InputDecoration(
                labelText: "Ingrese IP de la impresora",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: portController,
              decoration: InputDecoration(
                labelText: "Ingrese Puerto de la impresora",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: qrFormat,
              items: qrFormats.map((String format) {
                return DropdownMenuItem<String>(
                  value: format,
                  child: Text("Formato QR: $format"),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  qrFormat = newValue ?? 'json';
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: textController,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: "Texto de la etiqueta (modificable)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (ipController.text.isNotEmpty &&
                    portController.text.isNotEmpty) {
                  Map<String, String> etiquetaDataParsed =
                  parseTextInput(textController.text);

                  final pdfPath = await generateAndSavePdf(etiquetaDataParsed);
                  await sendPdfToPrinter(
                      pdfPath, ipController.text, portController.text);
                } else {
                  print("Por favor, ingrese la IP y el Puerto de la impresora");
                }
              },
              child: Text("Generar y enviar PDF"),
            ),
          ],
        ),
      ),
    );
  }

  /// Parsea el texto ingresado en el campo para convertirlo en un objeto [Map]
  Map<String, String> parseTextInput(String text) {
    final Map<String, String> parsedData = {};

    text.split('\n').forEach((line) {
      final parts = line.split(':');
      if (parts.length == 2) {
        parsedData[parts[0].trim()] = parts[1].trim();
      }
    });

    if (parsedData.isEmpty) {
      return etiquetaData;
    }
    return parsedData;
  }

  /// Generates a PDF with the provided data and saves it in a temporary directory
  Future<String> generateAndSavePdf(Map<String, String> data) async {
    final pdf = pw.Document();

    String qrData;
    if (qrFormat == 'json') {
      qrData = data.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
      qrData = '{$qrData}';
    } else {
      qrData = data.entries.map((e) => '${e.key},${e.value}').join('\n');
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(289, 144),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
                ),
                margin: pw.EdgeInsets.all(5),
                padding: pw.EdgeInsets.all(5),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Container(
                        padding: pw.EdgeInsets.only(left: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            for (var entry in data.entries)
                              pw.Column(
                                children: [
                                  pw.Text("${entry.key}: ${entry.value}",
                                      style: pw.TextStyle(fontSize: 7)),
                                  pw.SizedBox(height: 1),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: 400,
                        height: 400,
                        padding: pw.EdgeInsets.only(right: 10),
                        alignment: pw.Alignment.centerRight,
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: qrData,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final outputFile = File("${outputDir.path}/etiqueta.pdf");

    await outputFile.writeAsBytes(await pdf.save());
    return outputFile.path;
  }

  /// Sends the generated PDF to the Zebra printer and deletes the file after sending
  Future<void> sendPdfToPrinter(
      String pdfPath, String printerIp, String printerPort) async {
    try {
      final File pdfFile = File(pdfPath);

      if (await pdfFile.exists()) {
        print(
            "Enviando PDF a la impresora...  ${printerIp} ${int.parse(printerPort)}");

        await zsdk.printPdfFileOverTCPIP(
          filePath: pdfFile.path,
          address: printerIp,
          port: int.parse(printerPort),
          printerConf: Printer.PrinterConf(
            cmWidth: 10.2,
            cmHeight: 5.1,
            dpi: 203,
            orientation: Printer.Orientation.LANDSCAPE,
          ),
        );
        print("PDF enviado correctamente.");

        await pdfFile.delete();
        print("Archivo PDF temporal eliminado.");
      } else {
        print("Error: el archivo PDF no existe.");
      }
    } catch (e) {
      print("Error al enviar o eliminar el PDF: $e");
    }
  }
}
