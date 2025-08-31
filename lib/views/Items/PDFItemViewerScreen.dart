import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PDFViewerScreen extends StatefulWidget {
  final String url;
  const PDFViewerScreen({super.key, required this.url});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  bool _downloading = false;

  Future<void> _downloadFile() async {
    try {
      setState(() => _downloading = true);

      // Télécharge le fichier PDF
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        // Sauvegarde locale
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/datasheet.pdf");
        await file.writeAsBytes(response.bodyBytes);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("📂 PDF enregistré : ${file.path}"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("Erreur téléchargement (${response.statusCode})");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur téléchargement : $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Datasheet PDF",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEE6B33), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          _downloading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  onPressed: _downloadFile,
                  tooltip: "Télécharger",
                ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SfPdfViewer.network(widget.url),
        ),
      ),
    );
  }
}
