import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final String title;
  final String documentNumber;
  final Uint8List pdfBytes;

  const DocumentPreviewScreen({
    super.key,
    required this.title,
    required this.documentNumber,
    required this.pdfBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Document',
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: '$documentNumber.pdf',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Document',
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) async => pdfBytes,
                name: documentNumber,
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: '$documentNumber.pdf',
        previewPageMargin: const EdgeInsets.all(12),
        actionBarTheme: const PdfActionBarTheme(
          backgroundColor: AppColors.primaryWine,
          iconColor: Colors.white,
        ),
      ),
    );
  }
}
