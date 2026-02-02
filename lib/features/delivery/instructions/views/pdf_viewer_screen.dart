import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../../core/themes/app_colors.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final String pdfUrl = Get.arguments as String;
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  int totalPages = 0;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPdf();
  }

  Future<void> _downloadAndLoadPdf() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Download PDF
      final response = await http.get(Uri.parse(pdfUrl));

      if (response.statusCode == 200) {
        // Get temporary directory
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_pdf.pdf');

        // Write PDF to file
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load PDF: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading PDF: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'PDF File',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.0),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.w,
                      color: AppColors.error,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: _downloadAndLoadPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Page indicator
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: Center(
                    child: Text(
                      'Page ${currentPage + 1} of $totalPages',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // PDF viewer
                Expanded(
                  child: PDFView(
                    filePath: localPath!,
                    autoSpacing: true,
                    enableSwipe: true,
                    pageSnap: true,
                    swipeHorizontal: false,
                    nightMode: false,
                    onRender: (pages) {
                      setState(() {
                        totalPages = pages ?? 0;
                      });
                    },
                    onPageChanged: (page, total) {
                      setState(() {
                        currentPage = page ?? 0;
                      });
                    },
                    onError: (error) {
                      setState(() {
                        errorMessage = error.toString();
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
