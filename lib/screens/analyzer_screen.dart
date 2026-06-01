import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:task_slider/models/scam_report.dart';
import 'package:task_slider/providers/truthlens_provider.dart';
import 'result_screen.dart';

const Color _kBg = Color(0xFF0D1028);
const Color _kCard = Color(0xFF171B3A);
const Color _kAccent2 = Color(0xFF3D8BFF);

class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({required this.scanType, super.key});

  final ScanType scanType;

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  String? _uploadedFileName;
  String? _uploadSource;
  bool _isExtracting = false;
  bool get _supportsMobileOcr =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDocumentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'md', 'csv', 'json'],
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.single;
      final extractedText = await _readPickedFile(file);
      if (!mounted) {
        return;
      }
      if (extractedText == null || extractedText.trim().isEmpty) {
        _showSnack('Unable to read this file. Try another format.');
        return;
      }
      setState(() {
        _uploadedFileName = file.name;
        _uploadSource = 'Document';
        _controller.text = extractedText;
      });
      _showSnack('Document text loaded for analysis.');
    } catch (_) {
      _showSnack('Document upload failed. Please retry.');
    }
  }

  Future<void> _pickImageAndExtract(ImageSource source) async {
    if (!_supportsMobileOcr) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (!mounted || result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.single;
      setState(() {
        _uploadedFileName = file.name;
        _uploadSource = 'Photo';
      });
      _showSnack(
        'Photo selected. OCR extraction works on Android/iOS. Paste text manually on desktop.',
      );
      return;
    }
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 90);
      if (!mounted || picked == null) {
        return;
      }
      setState(() => _isExtracting = true);
      final recognizer = TextRecognizer();
      final inputImage = InputImage.fromFilePath(picked.path);
      final recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();
      if (!mounted) {
        return;
      }
      setState(() {
        _isExtracting = false;
        _uploadedFileName = picked.name;
        _uploadSource = source == ImageSource.camera ? 'Camera Photo' : 'Gallery Photo';
        _controller.text = recognizedText.text.trim();
      });
      if (_controller.text.length < 8) {
        _showSnack('Text extraction is low. Try a clearer photo.');
      } else {
        _showSnack('Photo text extracted successfully.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isExtracting = false);
      _showSnack('Photo processing failed. Try a clear image or another file.');
    }
  }

  Future<String?> _readPickedFile(PlatformFile file) async {
    if (file.bytes != null) {
      return String.fromCharCodes(file.bytes!);
    }
    if (kIsWeb) {
      return null;
    }
    if (file.path == null) {
      return null;
    }
    final f = File(file.path!);
    if (!await f.exists()) {
      return null;
    }
    return f.readAsString();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openUploadOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF141938),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Colors.white),
                  title: const Text('Upload Document', style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                    'Supported: txt, md, csv, json',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickDocumentFile();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
                  title: const Text('Pick Photo from Gallery', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageAndExtract(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                  title: const Text('Capture Photo', style: TextStyle(color: Colors.white)),
                  enabled: _supportsMobileOcr,
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageAndExtract(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final provider = context.read<TrustShieldProvider>();
    final record = await provider.analyzeInput(
      scanType: widget.scanType,
      content: _controller.text.trim(),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ResultScreen(record: record)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        title: Text(widget.scanType.label, style: const TextStyle(color: Colors.white)),
      ),
      body: Consumer<TrustShieldProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Form(
                  key: _formKey,
                  child: _buildAnalyzerForm(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyzerForm(TrustShieldProvider provider) {
    final isDocument = widget.scanType == ScanType.document;
    final hint = switch (widget.scanType) {
      ScanType.message => 'Paste message here...',
      ScanType.url => 'Enter website link...',
      ScanType.news => 'Paste news content...',
      ScanType.document => 'Document content extracted from file...',
    };
    final buttonText = switch (widget.scanType) {
      ScanType.message => 'Analyze',
      ScanType.url => 'Check',
      ScanType.news => 'Verify News',
      ScanType.document => 'Analyze Document',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Accuracy Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Upload complete content and avoid cropped or blurred photos for better trust score accuracy.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (isDocument) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _kAccent2),
                  onPressed: _isExtracting ? null : _openUploadOptions,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_isExtracting ? 'Extracting...' : 'Upload Document or Photo'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _uploadedFileName == null
                            ? 'No file selected yet'
                            : '$_uploadSource: $_uploadedFileName',
                        style: const TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tip: clear image + readable text = better detection.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_isExtracting) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(12),
          child: TextFormField(
            controller: _controller,
            minLines: 5,
            maxLines: 9,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54),
              fillColor: Colors.white.withValues(alpha: 0.07),
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _kAccent2),
              ),
            ),
            validator: (value) =>
                (value == null || value.trim().length < 8)
                    ? 'Please provide more content'
                    : null,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _kAccent2),
            onPressed: provider.isBusy || _isExtracting ? null : _scan,
            icon: provider.isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.manage_search),
            label: Text(provider.isBusy ? 'Analyzing...' : buttonText),
          ),
        ),
      ],
    );
  }
}