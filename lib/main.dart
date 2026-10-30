import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/qr_template.dart';
import 'utils/import_utils.dart';
import 'widgets/color_picker_dialog.dart';
import 'widgets/export_actions.dart';
import 'widgets/qr_preview.dart';
import 'widgets/template_forms/template_forms.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initialPayload;
  if (args.isNotEmpty) {
    initialPayload = args.join(' ');
  }

  runApp(QrEncoderApp(initialPayload: initialPayload));
}

class QrEncoderApp extends StatefulWidget {
  final String? initialPayload;

  const QrEncoderApp({super.key, this.initialPayload});

  @override
  State<QrEncoderApp> createState() => _QrEncoderAppState();
}

class _QrEncoderAppState extends State<QrEncoderApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('theme_mode');
      if (modeStr != null && mounted) {
        setState(() {
          _themeMode = ThemeMode.values.firstWhere(
            (e) => e.name == modeStr,
            orElse: () => ThemeMode.system,
          );
        });
      }
    } catch (_) {}
  }

  void _updateThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode.name);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QREncoder',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF1E293B),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF38BDF8),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1E293B),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: QrHomeScreen(
        initialPayload: widget.initialPayload,
        themeMode: _themeMode,
        onThemeModeChanged: _updateThemeMode,
      ),
    );
  }
}

class QrHomeScreen extends StatefulWidget {
  final String? initialPayload;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const QrHomeScreen({
    super.key,
    this.initialPayload,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<QrHomeScreen> createState() => _QrHomeScreenState();
}

class _QrHomeScreenState extends State<QrHomeScreen> {
  final FocusNode _primaryFocusNode = FocusNode();
  StreamSubscription? _intentSub;

  QrTemplateData _templateData = TextTemplateData();
  bool _isRawMode = false;
  String _rawPayload = '';

  int _ecLevel = QrErrorCorrectLevel.Q; // Default Q per spec
  Color _fgColor = Colors.black;
  Color _bgColor = Colors.white;
  double _moduleScale = 8.0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _handleInitialImport();
    _initSharingIntent();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primaryFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _primaryFocusNode.dispose();
    _intentSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _ecLevel = prefs.getInt('ec_level') ?? QrErrorCorrectLevel.Q;
        _moduleScale = prefs.getDouble('module_scale') ?? 8.0;
        final fgVal = prefs.getInt('fg_color');
        if (fgVal != null) _fgColor = Color(fgVal);
        final bgVal = prefs.getInt('bg_color');
        if (bgVal != null) _bgColor = Color(bgVal);
      });
    } catch (_) {}
  }

  Future<void> _savePreference(String key, dynamic val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (val is int) await prefs.setInt(key, val);
      if (val is double) await prefs.setDouble(key, val);
      if (val is String) await prefs.setString(key, val);
    } catch (_) {}
  }

  void _handleInitialImport() {
    if (widget.initialPayload != null && widget.initialPayload!.isNotEmpty) {
      _applyImportedText(widget.initialPayload!);
    }
  }

  void _initSharingIntent() {
    // 1. For sharing while app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((media) {
      if (media.isNotEmpty) {
        final item = media.first;
        if (item.path.isNotEmpty) {
          _applyImportedText(item.path);
        }
      }
    }).catchError((_) {});

    // 2. For sharing while app is open / paused in background
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((media) {
      if (media.isNotEmpty) {
        final item = media.first;
        if (item.path.isNotEmpty) {
          _applyImportedText(item.path);
        }
      }
    }, onError: (_) {});
  }

  void _applyImportedText(String text) {
    final parsed = ImportUtils.parsePayload(text);
    setState(() {
      _templateData = parsed;
      _rawPayload = parsed.buildPayload();
      _isRawMode = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primaryFocusNode.requestFocus();
    });
  }

  String get _currentPayload => _isRawMode ? _rawPayload : _templateData.buildPayload();

  void _onTemplateTypeSelected(QrTemplateType type) {
    if (_templateData.type == type) return;

    QrTemplateData newData;
    switch (type) {
      case QrTemplateType.text:
        newData = TextTemplateData(text: _currentPayload);
        break;
      case QrTemplateType.url:
        newData = UrlTemplateData(url: _currentPayload);
        break;
      case QrTemplateType.wifi:
        newData = WifiTemplateData();
        break;
      case QrTemplateType.calendar:
        newData = CalendarTemplateData();
        break;
      case QrTemplateType.vcard:
        newData = VCardTemplateData();
        break;
      case QrTemplateType.email:
        newData = EmailTemplateData();
        break;
      case QrTemplateType.phone:
        newData = PhoneTemplateData();
        break;
      case QrTemplateType.sms:
        newData = SmsTemplateData();
        break;
      case QrTemplateType.geo:
        newData = GeoTemplateData();
        break;
      case QrTemplateType.bitcoin:
        newData = BitcoinTemplateData();
        break;
      case QrTemplateType.lightning:
        newData = LightningTemplateData();
        break;
      case QrTemplateType.monero:
        newData = MoneroTemplateData();
        break;
      case QrTemplateType.zcash:
        newData = ZcashTemplateData();
        break;
      case QrTemplateType.ethereum:
        newData = EthereumTemplateData();
        break;
    }

    setState(() {
      _templateData = newData;
      _rawPayload = newData.buildPayload();
      _isRawMode = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primaryFocusNode.requestFocus();
    });
  }

  void _reset() {
    setState(() {
      _templateData = TextTemplateData();
      _rawPayload = '';
      _isRawMode = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primaryFocusNode.requestFocus();
    });
  }

  void _toggleRawMode() {
    setState(() {
      if (!_isRawMode) {
        _rawPayload = _templateData.buildPayload();
      } else {
        _templateData = ImportUtils.parsePayload(_rawPayload);
      }
      _isRawMode = !_isRawMode;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primaryFocusNode.requestFocus();
    });
  }

  void _openFullscreenScanView() {
    final payload = _currentPayload;
    if (payload.trim().isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenScanView(
          payload: payload,
          errorCorrectionLevel: _ecLevel,
          fgColor: _fgColor,
          bgColor: _bgColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QREncoder',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
        elevation: 0,
        actions: [
          ExportActions(
            payload: _currentPayload,
            errorCorrectionLevel: _ecLevel,
            fgColor: _fgColor,
            bgColor: _bgColor,
            moduleScale: _moduleScale,
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : (widget.themeMode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.brightness_auto_rounded),
            ),
            onPressed: () {
              final next = widget.themeMode == ThemeMode.system
                  ? ThemeMode.light
                  : (widget.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.system);
              widget.onThemeModeChanged(next);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left controls pane (40%)
        SizedBox(
          width: 380,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildControlsPane(),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right preview pane (60%)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildPreviewPane(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 320,
            child: _buildPreviewPane(),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildControlsPane(),
        ],
      ),
    );
  }

  Widget _buildControlsPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Content header & Edit raw toggle
        Row(
          children: [
            const Text(
              'Content:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _toggleRawMode,
              icon: Icon(_isRawMode ? Icons.view_list_rounded : Icons.code_rounded, size: 16),
              label: Text(_isRawMode ? 'Template mode' : 'Edit raw'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Content type dropdown
        DropdownButtonFormField<QrTemplateType>(
          value: _templateData.type,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: QrTemplateType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: SizedBox(
                width: 200,
                child: Text(t.label, overflow: TextOverflow.ellipsis),
              ),
            );
          }).toList(),
          onChanged: _isRawMode ? null : (t) => t != null ? _onTemplateTypeSelected(t) : null,
        ),
        const SizedBox(height: 16),
        // Form fields or Raw text box
        if (_isRawMode)
          TextFormField(
            initialValue: _rawPayload,
            focusNode: _primaryFocusNode,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Raw QR Payload',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() => _rawPayload = val);
            },
          )
        else
          TemplateFormWidget(
            data: _templateData,
            primaryFocusNode: _primaryFocusNode,
            onChanged: (newData) {
              setState(() {
                _templateData = newData;
                _rawPayload = newData.buildPayload();
              });
            },
          ),
        const SizedBox(height: 20),
        // Printing scale & Error correction level row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scale (px/module):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<double>(
                    isExpanded: true,
                    value: _moduleScale,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: 4.0, child: Text('4 px')),
                      DropdownMenuItem(value: 8.0, child: Text('8 px (Standard)')),
                      DropdownMenuItem(value: 12.0, child: Text('12 px (High)')),
                      DropdownMenuItem(value: 16.0, child: Text('16 px (Print)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _moduleScale = val);
                        _savePreference('module_scale', val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Error correction:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _ecLevel,
                    decoration: const InputDecoration(isDense: true),
                    items: const [
                      DropdownMenuItem(value: QrErrorCorrectLevel.L, child: Text('Level L (7%)')),
                      DropdownMenuItem(value: QrErrorCorrectLevel.M, child: Text('Level M (15%)')),
                      DropdownMenuItem(value: QrErrorCorrectLevel.Q, child: Text('Level Q (25%)')),
                      DropdownMenuItem(value: QrErrorCorrectLevel.H, child: Text('Level H (30%)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _ecLevel = val);
                        _savePreference('ec_level', val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Colors & Contrast
        ColorPickersWidget(
          fgColor: _fgColor,
          bgColor: _bgColor,
          onFgChanged: (c) {
            setState(() => _fgColor = c);
            _savePreference('fg_color', c.value);
          },
          onBgChanged: (c) {
            setState(() => _bgColor = c);
            _savePreference('bg_color', c.value);
          },
        ),
        const SizedBox(height: 20),
        // Reset button
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildPreviewPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Preview:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            Text(
              '${_currentPayload.length} chars',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: QrPreviewWidget(
            payload: _currentPayload,
            errorCorrectionLevel: _ecLevel,
            fgColor: _fgColor,
            bgColor: _bgColor,
            onTapFullscreen: _openFullscreenScanView,
          ),
        ),
      ],
    );
  }
}
