import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;

class NombramientoPdfGenerator {
  // Método principal para generar el PDF
  static Future<Uint8List> generateNombramientoPdf({
    required String numeroNombramiento,
    required String nombre,
    required String cargo,
    required String renglon,
    required String sueldo,
    required String nit,
    required String dependencia,
    required DateTime? fechaInicio,
    required DateTime? fechaFin,
    required String motivo,
    required String tipoTransporte,
    required String placas,
    required String firmante,
  }) async {
    // Cargar la fuente Arvo como solicitaste
    final font = await PdfGoogleFonts.arvoRegular();
    final fontBold = await PdfGoogleFonts.arvoBold();
    final fontItalic = await PdfGoogleFonts.arvoItalic();
    
    // Cargar el logo con el nombre correcto
    final ByteData logoData = await rootBundle.load('assets/OJ.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

    // Crear el documento PDF
    final pdf = pw.Document();

    // Inicializar datos de localización para español
    try {
      await initializeDateFormatting('es', null);
    } catch (e) {
      // Si ya está inicializado o hay un error, continuamos
      print('Nota: Locale ya inicializado o error: $e');
    }

    // Formatear fechas
    final fechaInicioStr = fechaInicio != null 
        ? DateFormat('dd/MM/yyyy').format(fechaInicio) 
        : '';
    final fechaFinStr = fechaFin != null 
        ? DateFormat('dd/MM/yyyy').format(fechaFin) 
        : '';
    
    // Fecha actual para el pie del documento
    String fechaActual;
    try {
      fechaActual = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'es').format(DateTime.now());
    } catch (e) {
      // Si hay un error con el formato en español, usar formato simple
      fechaActual = DateFormat('dd/MM/yyyy').format(DateTime.now());
      print('Error al formatear fecha en español: $e');
    }
    
    // Determinar qué checkbox marcar
    bool vehiculoInstitucion = tipoTransporte == 'Vehículo de la Institución';
    bool vehiculoPropio = tipoTransporte == 'Vehículo Propio';
    bool transporteExtraUrbano = tipoTransporte == 'Transporte Extra Urbano';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado con logo y título
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Primera columna: Logo
                  pw.Container(
                    width: 120,
                    height: 120,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Image(logoImage, width: 80, height: 80),
                  ),
                  
                  // Segunda columna: Título
                  pw.Expanded(
                    child: pw.Container(
                      height: 120,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'ORGANISMO JUDICIAL',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 16,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'NOMBRAMIENTO DE COMISIÓN',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Tercera columna: Número de nombramiento y dependencia
                  pw.Container(
                    width: 200,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 200,
                          padding: const pw.EdgeInsets.all(5),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(width: 1)),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'NOMBRAMIENTO No.',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 10,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                numeroNombramiento,
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Container(
                          width: 200,
                          padding: const pw.EdgeInsets.all(5),
                          alignment: pw.Alignment.center,
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'Dependencia:',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 10,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                dependencia,
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  font: fontItalic,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Sección "Se nombra a:"
              pw.Text(
                'Se nombra a:',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                ),
              ),
              
              pw.SizedBox(height: 5),
              
              // Tabla de información del empleado
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                  5: const pw.FlexColumnWidth(3),
                },
                children: [
                  // Encabezados
                  pw.TableRow(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'No.',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Nombre completo',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Cargo y Renglón presupuestario',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Sueldo Mensual',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'NIT',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Firma de Recepción de Nombramiento',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Datos del empleado
                  pw.TableRow(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        height: 40,
                        child: pw.Text(
                          '1',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        height: 40,
                        child: pw.Text(
                          nombre,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        height: 40,
                        child: pw.Text(
                          cargo + renglon,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        height: 40,
                        child: pw.Text(
                          'Q$sueldo',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        height: 40,
                        child: pw.Text(
                          nit,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(5),
                        height: 40,
                        child: pw.Text(
                          '',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 15),
              
              // Sección de lugar de comisión
              pw.Text(
                'Para realizar la comisión en la dependencia, municipio y departamento:',
                style: pw.TextStyle(
                  font: fontItalic,
                  fontSize: 11,
                ),
              ),
              pw.Container(
                width: double.infinity,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  dependencia,
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 10,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 15),
              
              // Sección de período
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Por el período comprendido del',
                    style: pw.TextStyle(
                      font: fontItalic,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Container(
                    width: 100,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      fechaInicioStr,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Text(
                    'al',
                    style: pw.TextStyle(
                      font: fontItalic,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Container(
                    width: 100,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 1)),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      fechaFinStr,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 15),
              
              // Sección de motivo
              pw.Text(
                'Motivo de la Comisión:',
                style: pw.TextStyle(
                  font: fontItalic,
                  fontSize: 11,
                ),
              ),
              pw.Container(
                width: double.infinity,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(
                  motivo,
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.Container(
                width: double.infinity,
                height: 20,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
              ),
              pw.Container(
                width: double.infinity,
                height: 20,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1)),
                ),
              ),
              
              pw.SizedBox(height: 15),
              
              // Sección de tipo de transporte
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Utilizará:',
                    style: pw.TextStyle(
                      font: fontItalic,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 15,
                        height: 15,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        child: vehiculoInstitucion
                            ? pw.Center(child: pw.Text('✓', style: pw.TextStyle(fontSize: 10)))
                            : pw.Container(),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Text(
                        'Vehículo de la Institución Placas',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Container(
                        width: 100,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1)),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          vehiculoInstitucion ? placas : '',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 30),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 15,
                        height: 15,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        child: vehiculoPropio
                            ? pw.Center(child: pw.Text('✓', style: pw.TextStyle(fontSize: 10)))
                            : pw.Container(),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Text(
                        'Vehículo propio',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 30),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 15,
                        height: 15,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 1),
                        ),
                        child: transporteExtraUrbano
                            ? pw.Center(child: pw.Text('✓', style: pw.TextStyle(fontSize: 10)))
                            : pw.Container(),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Text(
                        'Transporte Extra urbano',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 25),
              
              // Sección de lugar y fecha
              pw.Text(
                'Lugar y Fecha: Quetzaltenango, $fechaActual.',
                style: pw.TextStyle(
                  font: fontItalic,
                  fontSize: 11,
                ),
              ),
              
              pw.SizedBox(height: 50),
              
              // Sección de firma
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: 250,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 1)),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      firmante == "Coordinador II"
                      ? "(f). Ing. Julio Roberto Galicia Aldana"
                      : "(f). M.A Josue Roberto Velasquez Dionicio",
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                      ),
                    ),
                    pw.Text(
                      firmante,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                      ),
                    ),
                    pw.Text(
                      'Unidad Regional de Informática y Telecomunicaciones',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      'Centro Regional de Justicia, Quetzaltenango',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Notas al pie
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '1. La autoridad inmediata superior, debe planificar anticipadamente el desarrollo de la comisión previo a elaborar el presente nombramiento.',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 8,
                      ),
                    ),
                    pw.Text(
                      '2. Los viáticos y gastos derivados de la comisión serán realizados con cargo a la partida de esta dependencia.',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 8,
                      ),
                    ),
                    pw.Text(
                      '3. Para dar trámite a la presente solicitud, debe adjuntar fotocopia de carnet de NIT., y fotocopia de Cheque donde coincida el nombre y fotocopia de tarjeta de circulación cuando proceda.',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 8,
                      ),
                    ),
                    pw.Text(
                      '4. Los datos del presente nombramiento no deben contener borrones, tachaduras o enmiendas que constituyan alteración.',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 8,
                      ),
                    ),
                    pw.Text(
                      '5. Facturas a nombre de Organismo Judicial, NIT 337772-5, dirección 21 Calle 7-70 zona 1 Guatemala.',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 8,
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

    return pdf.save();
  }

  // Método para imprimir el PDF
  static Future<void> printNombramiento({
    required String numeroNombramiento,
    required String nombre,
    required String cargo,
    required String renglon,
    required String sueldo,
    required String nit,
    required String dependencia,
    required DateTime? fechaInicio,
    required DateTime? fechaFin,
    required String motivo,
    required String tipoTransporte,
    required String placas,
    required String firmante,
  }) async {
    try {
      final pdfBytes = await generateNombramientoPdf(
        numeroNombramiento: numeroNombramiento,
        nombre: nombre,
        cargo: cargo,
        renglon: renglon,
        sueldo: sueldo,
        nit: nit,
        dependencia: dependencia,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        motivo: motivo,
        tipoTransporte: tipoTransporte,
        placas: placas,
        firmante: firmante,
      );
      
      if (kIsWeb) {
        // Solución específica para web
        _downloadPdfInWeb(pdfBytes, 'nombramiento_$numeroNombramiento.pdf');
      } else {
        // Para plataformas móviles
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'nombramiento_$numeroNombramiento.pdf',
        );
      }
    } catch (e) {
      print('Error al generar o imprimir PDF: $e');
      rethrow;
    }
  }
  
  // Método para guardar el PDF (optimizado para web)
  static Future<void> saveNombramiento({
    required String numeroNombramiento,
    required String nombre,
    required String cargo,
    required String renglon,
    required String sueldo,
    required String nit,
    required String dependencia,
    required DateTime? fechaInicio,
    required DateTime? fechaFin,
    required String motivo,
    required String tipoTransporte,
    required String placas,
    required String firmante,
  }) async {
    try {
      final pdfBytes = await generateNombramientoPdf(
        numeroNombramiento: numeroNombramiento,
        nombre: nombre,
        cargo: cargo,
        renglon: renglon,
        sueldo: sueldo,
        nit: nit,
        dependencia: dependencia,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        motivo: motivo,
        tipoTransporte: tipoTransporte,
        placas: placas,
        firmante: firmante,
      );
      
      if (kIsWeb) {
        // Solución específica para web
        _downloadPdfInWeb(pdfBytes, 'nombramiento_$numeroNombramiento.pdf');
      } else {
        // Para plataformas móviles
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'nombramiento_$numeroNombramiento.pdf',
        );
      }
    } catch (e) {
      print('Error al guardar PDF: $e');
      rethrow;
    }
  }
  
  // Método específico para descargar PDF en web
  static void _downloadPdfInWeb(Uint8List bytes, String fileName) {
    // Crear un blob con los bytes del PDF
    final blob = html.Blob([bytes], 'application/pdf');
    
    // Crear una URL para el blob
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Crear un elemento <a> para la descarga
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    
    // Añadir el elemento al DOM
    html.document.body?.children.add(anchor);
    
    // Simular un clic para iniciar la descarga
    anchor.click();
    
    // Limpiar
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}

