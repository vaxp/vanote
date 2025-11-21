import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/diagram_node.dart';
import '../../domain/entities/diagram_connection.dart';

class ExportService {
  // Export canvas as PNG
  static Future<void> exportAsPng(
    ScreenshotController screenshotController,
    BuildContext context,
  ) async {
    try {
      // Capture the screenshot
      final image = await screenshotController.capture();
      if (image == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture diagram')),
          );
        }
        return;
      }

      // Get save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PNG Image',
        fileName: 'diagram.png',
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (result != null) {
        // Ensure .png extension is added
        String filePath = result;
        if (!filePath.toLowerCase().endsWith('.png')) {
          filePath = '$filePath.png';
        }
        
        final file = File(filePath);
        await file.writeAsBytes(image);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Diagram exported as PNG successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // Export canvas as PDF
  static Future<void> exportAsPdf(
    ScreenshotController screenshotController,
    BuildContext context,
    List<DiagramNode> nodes,
    List<DiagramConnection> connections,
    double canvasWidth,
    double canvasHeight,
  ) async {
    try {
      // Capture the screenshot first
      final imageBytes = await screenshotController.capture();
      if (imageBytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture diagram')),
          );
        }
        return;
      }

      // Create PDF document
      final pdf = pw.Document();
      
      // Add page with the image
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            canvasWidth > 0 ? canvasWidth : 794,
            canvasHeight > 0 ? canvasHeight : 1123,
          ),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      // Get save location first
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF Document',
        fileName: 'diagram.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        // Ensure .pdf extension is added
        String filePath = result;
        if (!filePath.toLowerCase().endsWith('.pdf')) {
          filePath = '$filePath.pdf';
        }
        
        final pdfBytes = await pdf.save();
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF exported successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    }
  }
}

