import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr/qr.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'payloads.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  final fromCli = args.where((a) => !a.startsWith('-')).join(' ').trim();
  runApp(QrEncoderApp(initialPayload: fromCli));
}

// ---------------------------------------------------------------- tokens ---

const _accent = Color(0xFFD8FF3E);

/// Text sitting on the accent is always this ink, in every theme.
const _accentInk = Color(0xFF111110);

const _clipboardChannel = MethodChannel('qrencoder/clipboard');
const _shareChannel = MethodChannel('qrencoder/share');
const _windowChannel = MethodChannel('qrencoder/window');

const _ecOrder = <QrErrorCorrectLevel>[
  QrErrorCorrectLevel.low,
  QrErrorCorrectLevel.medium,
  QrErrorCorrectLevel.quartile,
  QrErrorCorrectLevel.high,
];

const _levelNames = <QrErrorCorrectLevel, String>{
  QrErrorCorrectLevel.low: 'L',
  QrErrorCorrectLevel.medium: 'M',
  QrErrorCorrectLevel.quartile: 'Q',
  QrErrorCorrectLevel.high: 'H',
};

final class Palette {
  const Palette({
    required this.ground,
    required this.ink,
    required this.muted,
    required this.hair,
    required this.fill,
    required this.onFill,
  });

  final Color ground;
  final Color ink;
  final Color muted;
  final Color hair;
  final Color fill;
  final Color onFill;
}

const _light = Palette(
  ground: Color(0xFFF5F3EE),
  ink: Color(0xFF111110),
  muted: Color(0xFF6B6B62),
  hair: Color(0x40111110),
  fill: Color(0xFF111110),
  onFill: Color(0xFFF5F3EE),
);

const _dark = Palette(
  ground: Color(0xFF111110),
  ink: Color(0xFFF5F3EE),
  muted: Color(0xFF9C9C93),
  hair: Color(0x40F5F3EE),
  fill: Color(0xFFF5F3EE),
  onFill: Color(0xFF111110),
);

const _inks = <Color>[
  Color(0xFF111110),
  Color(0xFF16324F),
  Color(0xFF0E4B3A),
  Color(0xFF6B1F1A),
];

/// The symbol is always drawn ink-on-white, in every theme.
const _plate = Colors.white;

enum QrStyle { grid, standard, liquid }

const _styleNames = <QrStyle, String>{
  QrStyle.grid: 'DEFAULT',
  QrStyle.standard: 'STANDARD',
  QrStyle.liquid: 'LIQUID',
};

enum AppTheme { auto, light, dark }

const _themeNames = <AppTheme, String>{
  AppTheme.auto: 'AUTO',
  AppTheme.light: 'LIGHT',
  AppTheme.dark: 'DARK',
};

final class Type {
  const Type(this.p);
  final Palette p;

  TextStyle silk(double size, {Color? color, double spacing = 0.6}) => TextStyle(
    fontFamily: 'Silkscreen',
    fontSize: size,
    height: 1.05,
    letterSpacing: spacing,
    color: color ?? p.ink,
  );

  TextStyle label(double size, {Color? color}) => TextStyle(
    fontFamily: 'Barlow',
    fontSize: size,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.9,
    height: 1.2,
    color: color ?? p.ink,
  );

  TextStyle mono(double size, {Color? color}) => TextStyle(
    fontFamily: 'CourierPrime',
    fontSize: size,
    height: 1.35,
    color: color ?? p.ink,
  );

  TextStyle body(double size, {Color? color, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: 'Barlow',
        fontSize: size,
        height: 1.45,
        color: color ?? p.ink,
        fontWeight: weight,
      );
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

// ---------------------------------------------------------------- symbol ---

/// Paints a matrix of modules in one of the three symbol styles. Shared by the
/// on-screen plate, the style chips and the PNG export so they cannot drift.
void paintMatrix(
  Canvas canvas, {
  required bool Function(int row, int col) isDark,
  required int n,
  required double module,
  required Color ink,
  required QrStyle style,
  required Offset origin,
  bool finders = false,
}) {
  final paint = Paint()
    ..color = ink
    ..isAntiAlias = true;

  Rect cell(int r, int c) =>
      Rect.fromLTWH(origin.dx + c * module, origin.dy + r * module, module, module);

  bool darkAt(int r, int c) =>
      r >= 0 && c >= 0 && r < n && c < n && isDark(r, c);

  bool inFinder(int r, int c) =>
      (r < 7 && c < 7) || (r < 7 && c >= n - 7) || (r >= n - 7 && c < 7);

  switch (style) {
    case QrStyle.standard:
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (isDark(r, c)) canvas.drawRect(cell(r, c), paint);
        }
      }

    case QrStyle.grid:
      final gap = module >= 8 ? 1.0 : 0.0;
      final side = module - gap;
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (!isDark(r, c)) continue;
          final box = cell(r, c);
          canvas.drawRect(
            Rect.fromLTWH(box.left, box.top, side, side),
            paint,
          );
        }
      }

    case QrStyle.liquid:
      final rad = Radius.circular(module * 0.42);
      final path = Path();
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          if (!isDark(r, c)) continue;
          if (finders && inFinder(r, c)) continue;
          final up = darkAt(r - 1, c);
          final down = darkAt(r + 1, c);
          final left = darkAt(r, c - 1);
          final right = darkAt(r, c + 1);
          final box = cell(r, c);
          if (!up && !down && !left && !right) {
            path.addOval(box);
            continue;
          }
          path.addRRect(
            RRect.fromRectAndCorners(
              box,
              topLeft: (up || left) ? Radius.zero : rad,
              topRight: (up || right) ? Radius.zero : rad,
              bottomLeft: (down || left) ? Radius.zero : rad,
              bottomRight: (down || right) ? Radius.zero : rad,
            ),
          );
        }
      }
      canvas.drawPath(path, paint);

      if (finders) {
        final clear = Paint()..color = _plate;
        for (final o in [
          [0, 0],
          [0, n - 7],
          [n - 7, 0],
        ]) {
          final box = Rect.fromLTWH(
            origin.dx + o[1] * module,
            origin.dy + o[0] * module,
            7 * module,
            7 * module,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(box, Radius.circular(module * 1.5)),
            paint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              box.deflate(module),
              Radius.circular(module * 0.85),
            ),
            clear,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              box.deflate(module * 2),
              Radius.circular(module * 0.5),
            ),
            paint,
          );
        }
      }
  }
}

const _sampleN = 9;
const _sample = <String>[
  '###..#.#.',
  '#.#.#.#.#',
  '###.#...#',
  '...##.##.',
  '#.##.#..#',
  '.#..###..',
  '##.#..#.#',
  '..#.#.##.',
  '#...#.#..',
];

bool _sampleDark(int r, int c) =>
    r >= 0 && c >= 0 && r < _sampleN && c < _sampleN && _sample[r][c] == '#';

// ---------------------------------------------------------------- widget ---

class QrEncoderApp extends StatelessWidget {
  const QrEncoderApp({super.key, this.initialPayload = ''});

  final String initialPayload;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Palette p) => ThemeData(
      useMaterial3: false,
      brightness: p == _dark ? Brightness.dark : Brightness.light,
      fontFamily: 'Barlow',
      scaffoldBackgroundColor: p.ground,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.ink,
        selectionColor: _accent.withValues(alpha: 0.55),
        selectionHandleColor: p.ink,
      ),
    );

    return MaterialApp(
      title: 'QREncoder',
      debugShowCheckedModeBanner: false,
      theme: theme(_light),
      darkTheme: theme(_dark),
      themeMode: ThemeMode.system,
      home: EditorScreen(initialPayload: initialPayload),
    );
  }
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.initialPayload = ''});

  final String initialPayload;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  QrErrorCorrectLevel _ec = QrErrorCorrectLevel.quartile;
  AppTheme _theme = AppTheme.auto;
  PayloadType _type = PayloadType.text;
  int _scale = 8;
  int _inkIndex = 0;
  QrStyle _style = QrStyle.grid;

  /// Field values per template, keyed by template then field id. Kept for the
  /// session so switching templates back and forth does not lose typing; never
  /// written to disk.
  final _values = <PayloadType, Map<String, String>>{};
  final _controllers = <String, TextEditingController>{};
  final _fieldFocus = <String, FocusNode>{};

  final _typeLink = LayerLink();
  OverlayEntry? _pickerEntry;

  QrImage? _qr;
  String? _error;
  String _status = '';

  /// The file the last Save PNG produced, when there is one to point at.
  String? _savedPath;

  /// Android draws the app edge to edge, so the status and navigation bars
  /// have to be told which way round they are. Cached to avoid a platform
  /// round trip on every keystroke.
  Brightness? _barsFor;
  Timer? _statusTimer;

  Color get _foreground => _inks[_inkIndex];

  /// The exact characters that go into the symbol — composed from fields, or
  /// typed straight in for the Text template.
  String get _payload =>
      _type == PayloadType.text ? _text.text : composePayload(_type, _valuesFor(_type));

  Map<String, String> _valuesFor(PayloadType type) =>
      _values.putIfAbsent(type, () => <String, String>{});

  FocusNode _focusFor(PayloadType type, FieldSpec field) =>
      _fieldFocus.putIfAbsent('${type.index}/${field.id}', FocusNode.new);

  /// The caret always sits in the input that matters: the payload box for Text,
  /// the first field of any other template.
  void _focusInput() {
    if (_type == PayloadType.text) {
      _focus.requestFocus();
      return;
    }
    final first = fieldsFor(_type).first;
    if (first.kind == FieldKind.text) _focusFor(_type, first).requestFocus();
  }

  TextEditingController _controllerFor(PayloadType type, FieldSpec field) {
    final key = '${type.index}/${field.id}';
    return _controllers.putIfAbsent(key, () {
      final controller = TextEditingController(
        text: _valuesFor(type)[field.id] ?? '',
      );
      controller.addListener(() {
        _valuesFor(type)[field.id] = controller.text;
        _reencode();
      });
      return controller;
    });
  }

  String _choiceValue(FieldSpec field) {
    final raw = (_valuesFor(_type)[field.id] ?? '').trim();
    return raw.isEmpty ? field.defaultValue : raw;
  }

  void _setChoice(FieldSpec field, String option) {
    setState(() => _valuesFor(_type)[field.id] = option);
    _reencode();
  }

  @override
  void initState() {
    super.initState();
    _text.addListener(_reencode);
    if (widget.initialPayload.isNotEmpty) _text.text = widget.initialPayload;
    _restore();
    _listenForShares();
  }

  /// Android hands shared text to the activity as an Intent. Anything arriving
  /// that way goes straight into the payload, so the symbol is already on
  /// screen by the time the app is visible.
  void _listenForShares() {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'onText' && call.arguments is String) {
        _takeShared(call.arguments as String);
      }
      return null;
    });
    _shareChannel.invokeMethod<String>('consume').then((text) {
      if (!mounted || text == null || text.isEmpty) return;
      _takeShared(text);
    }).catchError((Object _) => null);
  }

  void _takeShared(String text) {
    setState(() {
      _type = PayloadType.text;
      _text.text = text;
      _savedPath = null;
    });
    _reencode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _pickerEntry?.remove();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _fieldFocus.values) {
      node.dispose();
    }
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------- settings ---

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ec = prefs.getInt('ec');
      final scale = prefs.getInt('scale');
      final ink = prefs.getInt('ink');
      final style = prefs.getInt('style');
      final theme = prefs.getInt('theme');
      if (!mounted) return;
      setState(() {
        if (ec != null && ec >= 0 && ec < _ecOrder.length) _ec = _ecOrder[ec];
        if (scale != null && scale > 0) _scale = math.min(scale, 64);
        if (ink != null && ink >= 0 && ink < _inks.length) _inkIndex = ink;
        if (style != null && style >= 0 && style < QrStyle.values.length) {
          _style = QrStyle.values[style];
        }
        if (theme != null && theme >= 0 && theme < AppTheme.values.length) {
          _theme = AppTheme.values[theme];
        }
      });
      _applyWindowAppearance();
      _reencode();
    } catch (_) {
      // Preferences are a convenience; the editor works without them.
    }
  }

  void _remember() {
    SharedPreferences.getInstance()
        .then((prefs) async {
          await prefs.setInt('ec', _ecOrder.indexOf(_ec));
          await prefs.setInt('scale', _scale);
          await prefs.setInt('ink', _inkIndex);
          await prefs.setInt('style', _style.index);
          await prefs.setInt('theme', _theme.index);
        })
        .catchError((_) {});
  }

  void _setTheme(AppTheme theme) {
    setState(() => _theme = theme);
    _remember();
    _applyWindowAppearance();
  }

  /// The macOS title bar is drawn by AppKit, so it has to be told separately
  /// which appearance the editor settled on. Auto hands it back to the system.
  void _applyWindowAppearance() {
    if (!Platform.isMacOS) return;
    final name = switch (_theme) {
      AppTheme.auto => 'auto',
      AppTheme.light => 'light',
      AppTheme.dark => 'dark',
    };
    _windowChannel.invokeMethod<void>('setAppearance', name).catchError((_) {});
  }

  void _setType(PayloadType type) {
    if (type == _type) return;
    setState(() => _type = type);
    _remember();
    _reencode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusInput();
    });
  }

  void _openTypePicker(Palette p, Type t, double size) {
    if (_pickerEntry != null) return;
    final entry = OverlayEntry(
      builder: (context) => _TypePicker(
        palette: p,
        type: t,
        current: _type,
        link: _typeLink,
        gap: size * 1.45,
        onPick: (picked) {
          _closeTypePicker();
          _setType(picked);
        },
        onDismiss: _closeTypePicker,
      ),
    );
    _pickerEntry = entry;
    Overlay.of(context).insert(entry);
  }

  void _closeTypePicker() {
    _pickerEntry?.remove();
    _pickerEntry = null;
  }

  void _reencode() {
    final data = _payload;
    if (data.isEmpty) {
      setState(() {
        _qr = null;
        _error = null;
      });
      return;
    }
    try {
      final code = QrCode(
        payload: QrPayload.fromString(data),
        errorCorrectLevel: _ec,
      );
      setState(() {
        _qr = QrImage(code);
        _error = null;
      });
    } on InputTooLongException {
      setState(() {
        _qr = null;
        _error =
            'Too long for ${_levelNames[_ec]} — lower the level or shorten the payload.';
      });
    } catch (e) {
      setState(() {
        _qr = null;
        _error = 'Cannot encode this payload. $e';
      });
    }
  }

  void _say(String message) {
    _statusTimer?.cancel();
    setState(() => _status = message);
    _statusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _status = '');
    });
  }

  /// Hard ceiling on the exported bitmap, per side, so a huge code at a large
  /// module scale cannot exhaust memory.
  static const int _maxExportSide = 4096;

  /// The scale actually used: the chosen one, reduced if the image would exceed
  /// [_maxExportSide] pixels per side.
  int get _effectiveScale {
    final n = (_qr?.moduleCount ?? 0) + 8;
    if (n <= 8) return _scale;
    return math.max(1, math.min(_scale, _maxExportSide ~/ n));
  }

  bool get _capped => _effectiveScale < _scale;

  int get _exportSide => ((_qr?.moduleCount ?? 0) + 8) * _effectiveScale;

  bool get _hasCode => _qr != null;

  @override
  Widget build(BuildContext context) {
    final systemBrightness =
        MediaQuery.maybePlatformBrightnessOf(context) ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = switch (_theme) {
      AppTheme.auto => systemBrightness,
      AppTheme.light => Brightness.light,
      AppTheme.dark => Brightness.dark,
    };
    final p = brightness == Brightness.dark ? _dark : _light;
    final t = Type(p);

    if (_barsFor != brightness) {
      _barsFor = brightness;
      final icons = brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark;
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: icons,
          statusBarBrightness: brightness,
          systemNavigationBarColor: p.ground,
          systemNavigationBarIconBrightness: icons,
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.ground,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _savePng,
          const SingleActivator(LogicalKeyboardKey.keyC, meta: true, shift: true):
              _copyImage,
        },
        child: Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: p.ink,
              selectionColor: _accent.withValues(alpha: 0.55),
              selectionHandleColor: p.ink,
            ),
          ),
          // Desktop has no insets; Android does, and draws under both bars.
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 900
                  ? _desktop(p, t)
                  : _phone(p, t),
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktop(Palette p, Type t) {
    return Column(
      children: [
        _topBar(p, t),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 100, child: _controls(p, t)),
              Expanded(flex: 135, child: _rightPane(p, t)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _phone(Palette p, Type t) {
    return Column(
      children: [
        _topBar(p, t, compact: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _typeLine(p, t, 21),
                const SizedBox(height: 18),
                _payloadSection(p, t, minLines: 3),
                const SizedBox(height: 18),
                _phonePlate(p),
                const SizedBox(height: 18),
                _ecSection(p, t, wide: true),
                const SizedBox(height: 20),
                _inkSection(p, t, wide: true),
                const SizedBox(height: 22),
                _ladder(p, t, rightPad: 14),
                const SizedBox(height: 22),
                _styleSection(p, t, wide: true),
                const SizedBox(height: 20),
                _phoneApparatus(p, t),
              ],
            ),
          ),
        ),
        _footer(p, t, compact: true),
      ],
    );
  }

  // ------------------------------------------------------------- chrome ---

  Widget _topBar(Palette p, Type t, {bool compact = false}) {
    return Container(
      height: compact ? 58 : 66,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.ink, width: 2)),
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 24),
      child: Row(
        children: [
          Text('QRENCODER', style: t.silk(compact ? 16 : 20)),
          const SizedBox(width: 10),
          Container(width: 7, height: 7, color: _accent),
          const Spacer(),
          _themeKeys(p, t, compact: compact),
        ],
      ),
    );
  }

  /// Three keys for the same choice the EC level uses: quiet, adjacent,
  /// visible at a glance, and always reachable from the top bar.
  Widget _themeKeys(Palette p, Type t, {bool compact = false}) {
    return Row(
      children: [
        for (final theme in AppTheme.values)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _setTheme(theme),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  height: compact ? 26 : 30,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme == _theme ? _accent : Colors.transparent,
                    border: Border.all(
                      color: theme == _theme ? p.ink : p.hair,
                      width: theme == _theme ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _themeNames[theme]!,
                    style: t.label(
                      8,
                      color: theme == _theme ? _accentInk : p.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The payload type at the top of the controls — the app's one big word,
  /// because it is the one choice everything below it depends on. It is also
  /// the way into the template picker.
  Widget _typeLine(Palette p, Type t, double size) {
    return CompositedTransformTarget(
      link: _typeLink,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openTypePicker(p, t, size),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(payloadTypeNames[_type]!, style: t.silk(size)),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: size * 0.3),
                  child: Text(
                    payloadTypeFormats[_type]!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.mono(math.max(9, size * 0.4), color: p.muted),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: p.ink, width: 1),
                ),
                child: Text('CHANGE', style: t.label(8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------- controls ---

  Widget _controls(Palette p, Type t) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: p.ink, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(26, 22, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _typeLine(p, t, 29),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _payloadSection(p, t),
                  const SizedBox(height: 24),
                  _ecSection(p, t),
                  const SizedBox(height: 24),
                  _inkSection(p, t),
                  const SizedBox(height: 26),
                  _ladder(p, t),
                  const SizedBox(height: 26),
                  _styleSection(p, t),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? get _payloadTrailing {
    final n = _payload.characters.length;
    return n == 0 ? null : '$n CHARS';
  }

  /// Text is one free-form box; every other template is a short form whose
  /// result is shown beneath it, so the encoded string is always readable.
  Widget _payloadSection(Palette p, Type t, {int minLines = 6}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(p, t, 'PAYLOAD', trailing: _payloadTrailing),
        const SizedBox(height: 10),
        if (_type == PayloadType.text)
          _payloadBox(p, t, minLines: minLines)
        else ...[
          for (final field in fieldsFor(_type))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _field(p, t, field),
            ),
          _rawPayload(p, t),
        ],
      ],
    );
  }

  Widget _field(Palette p, Type t, FieldSpec field) {
    if (field.kind == FieldKind.choice) {
      final current = _choiceValue(field);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: t.label(8, color: p.muted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in field.options!)
                _optionKey(p, t, option, option == current, () {
                  _setChoice(field, option);
                }),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: t.label(8, color: p.muted)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(border: Border.all(color: p.ink, width: 1)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: TextField(
            controller: _controllerFor(_type, field),
            focusNode: _focusFor(_type, field),
            maxLines: field.lines,
            minLines: 1,
            cursorWidth: 1.6,
            cursorColor: p.ink,
            style: t.body(14),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: field.hint.isEmpty ? null : field.hint,
              hintStyle: t.body(14, color: p.muted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionKey(
    Palette p,
    Type t,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            border: Border.all(
              color: selected ? p.ink : p.hair,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: t.label(8, color: selected ? _accentInk : p.ink),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rawPayload(Palette p, Type t) {
    final payload = _payload;
    if (payload.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(border: Border.all(color: p.hair, width: 1)),
      child: Text(
        payload,
        style: t.mono(11, color: p.muted),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _sectionHeader(Palette p, Type t, String title, {String? trailing}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.ink, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: t.label(9)),
          if (trailing != null) Text(trailing, style: t.mono(10, color: p.muted)),
        ],
      ),
    );
  }

  Widget _payloadBox(Palette p, Type t, {int minLines = 6}) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: p.ink, width: 2)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: TextField(
        controller: _text,
        focusNode: _focus,
        autofocus: true,
        maxLines: null,
        minLines: minLines,
        cursorWidth: 1.6,
        cursorColor: p.ink,
        style: t.body(15),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Type or paste',
          hintStyle: t.body(15, color: p.muted),
        ),
      ),
    );
  }

  Widget _ecSection(Palette p, Type t, {bool wide = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(p, t, 'ERROR CORRECTION',
            trailing: '${_levelNames[_ec]} · ${_ec.recoveryRate}%'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final level in _ecOrder)
              wide
                  ? Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: _ecKey(p, t, level, height: 44),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: _ecKey(p, t, level),
                    ),
          ],
        ),
      ],
    );
  }

  Widget _ecKey(Palette p, Type t, QrErrorCorrectLevel level,
      {double height = 38}) {
    final on = level == _ec;
    return GestureDetector(
      onTap: () {
        setState(() => _ec = level);
        _remember();
        _reencode();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 44,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? _accent : Colors.transparent,
            border: Border.all(color: p.ink, width: on ? 2 : 1),
          ),
          child: Text(
            _levelNames[level]!,
            style: t.silk(15, color: on ? _accentInk : p.ink),
          ),
        ),
      ),
    );
  }

  Widget _inkSection(Palette p, Type t, {bool wide = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(p, t, 'INK'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _inks.length; i++)
              wide
                  ? Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _inkSwatch(p, i, width: null, height: 30),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _inkSwatch(p, i),
                    ),
          ],
        ),
      ],
    );
  }

  Widget _inkSwatch(Palette p, int index, {double? width = 46, double height = 26}) {
    final selected = index == _inkIndex;
    return GestureDetector(
      onTap: () {
        setState(() => _inkIndex = index);
        _remember();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? _accent : p.hair,
              width: selected ? 3 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _inks[index],
              border: Border.all(
                color: p.ink.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ladder(Palette p, Type t, {double rightPad = 20}) {
    const options = <int>[8, 16, 32, 64];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(p, t, 'MODULE SCALE', trailing: '$_scale PX'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final px in options)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _scale = px);
                  _remember();
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: EdgeInsets.only(right: rightPad),
                    child: SizedBox(
                      width: math.max(48, px.toDouble()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 68,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                width: px.toDouble(),
                                height: px.toDouble(),
                                decoration: BoxDecoration(
                                  color: px == _scale ? p.ink : p.hair,
                                  border: px == _scale
                                      ? Border.all(color: _accent, width: 2)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text('${px ~/ 8}×', style: t.silk(10)),
                          Text('$px', style: t.mono(9, color: p.muted)),
                          const SizedBox(height: 5),
                          Container(
                            width: math.max(48, px.toDouble()),
                            height: 3,
                            color: px == _scale ? _accent : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _styleSection(Palette p, Type t, {bool wide = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(p, t, 'STYLE'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final style in QrStyle.values)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _styleChip(p, t, style, wide: wide),
              ),
          ],
        ),
      ],
    );
  }

  Widget _styleChip(Palette p, Type t, QrStyle style, {bool wide = false}) {
    final selected = style == _style;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _style = style);
        _remember();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: wide ? null : 96,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? _accent : p.hair,
              width: selected ? 3 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: _plate,
                padding: const EdgeInsets.all(6),
                child: CustomPaint(
                  size: const Size(48, 48),
                  painter: _SamplePainter(style: style, ink: _foreground),
                ),
              ),
              const SizedBox(height: 6),
              Text(_styleNames[style]!, style: t.label(8)),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- right ---

  Widget _rightPane(Palette p, Type t) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _plateArea(p)),
              _apparatus(p, t),
            ],
          ),
        ),
        _footer(p, t),
      ],
    );
  }

  Widget _plateArea(Palette p) {
    return Container(
      color: _plate,
      padding: const EdgeInsets.all(26),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxSide = math.min(constraints.maxWidth, constraints.maxHeight);
          if (_error != null) return _errorState(p, maxSide);
          final qr = _qr;
          if (qr == null) return _emptyState(p, maxSide);

          final module =
              math.max(2.0, (maxSide / (qr.moduleCount + 8)).floorToDouble());
          final side = module * (qr.moduleCount + 8);
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: CustomPaint(
                painter: _SymbolPainter(
                  qr: qr,
                  module: module,
                  ink: _foreground,
                  style: _style,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _wantsHint => _type == PayloadType.text;

  Widget _phonePlate(Palette p) {
    return Container(
      color: _plate,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final avail = constraints.maxWidth;
          if (_error != null) return _errorState(p, avail, cap: 300);
          final qr = _qr;
          if (qr == null) return _emptyState(p, avail, cap: 300);

          final module =
              math.max(2.0, (avail / (qr.moduleCount + 8)).floorToDouble());
          final side = module * (qr.moduleCount + 8);
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: CustomPaint(
                painter: _SymbolPainter(
                  qr: qr,
                  module: module,
                  ink: _foreground,
                  style: _style,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(Palette p, double maxSide, {double cap = 430}) {
    final side = math.max(180.0, math.min(maxSide - 40, cap));
    return Center(
      child: SizedBox(
        width: side,
        height: side,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: p.hair, width: 1)),
          child: Stack(
            children: [
              _CornerTicks(color: p.hair),
              if (_wantsHint)
                Center(
                  child: Text(
                    'start typing',
                    style: Type(_light).mono(12, color: const Color(0xFF8A8A80)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(Palette p, double maxSide, {double cap = 430}) {
    final side = math.max(180.0, math.min(maxSide - 40, cap));
    return Center(
      child: SizedBox(
        width: side,
        height: side,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(border: Border.all(color: p.ink, width: 2)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('CANNOT ENCODE', style: Type(_light).label(10)),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Type(_light).body(13, color: const Color(0xFF6B6B62)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _apparatus(Palette p, Type t) {
    final rows = _apparatusRows();
    final ratio = rows['CONTRAST']!;
    return Container(
      width: 232,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: p.ink, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in rows.entries)
            _measure(p, t, entry.key, entry.value),
          const Spacer(),
          if (_qr != null && ratio != '—' && _ratio < 4.0)
            _contrastWarning(p, t),
        ],
      ),
    );
  }

  double get _ratio => _contrast(_foreground, _plate);

  Map<String, String> _apparatusRows() {
    final qr = _qr;
    final modules = qr?.moduleCount ?? 0;
    return {
      'MODULES': modules == 0 ? '—' : '$modules × $modules',
      'CONTRAST': modules == 0 ? '—' : '${_ratio.toStringAsFixed(1)}:1',
      'EXPORT': modules == 0 ? '—' : '$_exportSide PX${_capped ? ' (CAPPED)' : ''}',
      'SCALE': '$_scale PX',
    };
  }

  Widget _measure(Palette p, Type t, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.hair, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.label(8, color: p.muted)),
          const SizedBox(height: 4),
          Text(value, style: t.silk(11)),
        ],
      ),
    );
  }

  Widget _phoneApparatus(Palette p, Type t) {
    final rows = _apparatusRows().entries.toList();
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.ink, width: 2)),
      ),
      padding: const EdgeInsets.only(top: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = (constraints.maxWidth - 18) / 2;
          return Wrap(
            spacing: 18,
            children: [
              for (final entry in rows)
                SizedBox(
                  width: w,
                  child: _measure(p, t, entry.key, entry.value),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _contrastWarning(Palette p, Type t) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _accent,
        border: Border.all(color: p.ink, width: 2),
      ),
      child: Text('CONTRAST UNDER 4:1', style: t.label(8, color: _accentInk)),
    );
  }

  Widget _footer(Palette p, Type t, {bool compact = false}) {
    final copy = _button(
      p,
      t,
      _copiesImages ? 'COPY IMAGE' : 'COPY TEXT',
      _copyImage,
      filled: true,
    );
    final save = _button(p, t, 'SAVE PNG', _savePng);

    if (compact) {
      return Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.ink, width: 2)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_status.isNotEmpty || (_savedPath != null && _canReveal))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _status.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.label(9, color: p.muted),
                      ),
                    ),
                    if (_savedPath != null && _canReveal)
                      _revealKey(p, t),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 8),
                Expanded(child: save),
                const SizedBox(width: 12),
                _reset(p, t),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.ink, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _status.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.label(9, color: p.muted),
            ),
          ),
          if (_savedPath != null && _canReveal) ...[
            _revealKey(p, t),
            const SizedBox(width: 14),
          ],
          copy,
          const SizedBox(width: 8),
          save,
          const SizedBox(width: 14),
          _reset(p, t),
        ],
      ),
    );
  }

  /// Only appears once a file exists to reveal, and only where there is a
  /// Finder to reveal it in.
  Widget _revealKey(Palette p, Type t) {
    return GestureDetector(
      onTap: _revealSaved,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(border: Border.all(color: p.hair, width: 1)),
          child: Text('SHOW IN FINDER', style: t.label(8, color: p.muted)),
        ),
      ),
    );
  }

  Widget _reset(Palette p, Type t) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = PayloadType.text;
          _values.clear();
          _savedPath = null;
        });
        for (final controller in _controllers.values) {
          controller.clear();
        }
        _text.clear();
        _remember();
        _reencode();
        _focus.requestFocus();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text('RESET', style: t.label(9, color: p.muted)),
      ),
    );
  }

  Widget _button(Palette p, Type t, String text, VoidCallback onTap,
      {bool filled = false}) {
    final enabled = _hasCode;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: !enabled
                ? Colors.transparent
                : (filled ? p.fill : Colors.transparent),
            border: Border.all(
              color: enabled ? p.ink : p.hair,
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: t.label(
              9,
              color: !enabled
                  ? p.muted
                  : (filled ? p.onFill : p.ink),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- export ---

  Future<Uint8List?> _renderPng() async {
    final qr = _qr;
    if (qr == null) return null;
    final n = qr.moduleCount + 8;
    final scale = _effectiveScale;
    final size = n * scale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..color = _plate,
    );
    paintMatrix(
      canvas,
      isDark: qr.isDark,
      n: qr.moduleCount,
      module: scale.toDouble(),
      ink: _foreground,
      style: _style,
      origin: Offset(4.0 * scale, 4.0 * scale),
      finders: true,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  /// macOS and Android both have a native channel for this: NSPasteboard takes
  /// the image directly, Android takes a FileProvider URI. Anywhere else the
  /// button says COPY TEXT and puts the payload on the clipboard, which is
  /// what it can actually do.
  bool get _copiesImages =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.android;

  Future<void> _copyImage() async {
    if (_qr == null) return;
    if (!_copiesImages) {
      await Clipboard.setData(ClipboardData(text: _payload));
      _say('copied as text');
      return;
    }
    final bytes = await _renderPng();
    if (bytes == null) return;
    try {
      await _clipboardChannel.invokeMethod<void>('setPng', bytes);
      _say('copied · $_exportSide px${_capped ? ' · capped at $_maxExportSide' : ''}');
    } on PlatformException {
      _say('clipboard unavailable');
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: _payload));
      _say('copied as text');
    }
  }

  bool get _canReveal => defaultTargetPlatform == TargetPlatform.macOS;

  void _revealSaved() {
    final path = _savedPath;
    if (path == null) return;
    _windowChannel.invokeMethod<void>('revealPath', path).catchError((Object _) {
      _say('cannot reveal');
    });
  }

  Future<void> _savePng() async {
    if (_qr == null) return;
    final bytes = await _renderPng();
    if (bytes == null) return;
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);
    // The plugin writes the bytes itself on every platform that has a save
    // dialog, so there is nothing to write here — only a result to report.
    final Uri? saved;
    try {
      saved = await FilePicker.saveFile(
        dialogTitle: 'Save QR code',
        fileName: 'qrencoder-$stamp.png',
        mimeType: 'image/png',
        bytes: bytes,
      );
    } on PlatformException catch (error) {
      _say('cannot save · ${error.code.toLowerCase().replaceAll('_', ' ')}');
      return;
    }
    if (saved == null) return;
    final path = saved.isScheme('file') ? saved.toFilePath() : null;
    setState(() => _savedPath = path);
    _say('saved · $_exportSide px${_capped ? ' · capped at $_maxExportSide' : ''}');
  }
}

// --------------------------------------------------------------- painter ---

class _SymbolPainter extends CustomPainter {
  _SymbolPainter({
    required this.qr,
    required this.module,
    required this.ink,
    required this.style,
  });

  final QrImage qr;
  final double module;
  final Color ink;
  final QrStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _plate);
    paintMatrix(
      canvas,
      isDark: qr.isDark,
      n: qr.moduleCount,
      module: module,
      ink: ink,
      style: style,
      origin: Offset(4 * module, 4 * module),
      finders: true,
    );
  }

  @override
  bool shouldRepaint(_SymbolPainter old) =>
      old.qr != qr || old.module != module || old.ink != ink || old.style != style;
}

class _SamplePainter extends CustomPainter {
  const _SamplePainter({required this.style, required this.ink});

  final QrStyle style;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _plate);
    paintMatrix(
      canvas,
      isDark: _sampleDark,
      n: _sampleN,
      module: size.width / _sampleN,
      ink: ink,
      style: style,
      origin: Offset.zero,
    );
  }

  @override
  bool shouldRepaint(_SamplePainter old) =>
      old.style != style || old.ink != ink;
}

class _CornerTicks extends StatelessWidget {
  const _CornerTicks({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TickPainter(color), size: Size.infinite);
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const len = 14.0;
    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(dx * len, 0), paint);
      canvas.drawLine(o, o.translate(0, dy * len), paint);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);
    corner(Offset(size.width, size.height), -1, -1);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color;
}

// ----------------------------------------------------------- type picker ---

/// The template list, drawn over the editor instead of in a Material dialog:
/// a numbered specimen panel anchored to the type line it belongs to.
class _TypePicker extends StatefulWidget {
  const _TypePicker({
    required this.palette,
    required this.type,
    required this.current,
    required this.link,
    required this.gap,
    required this.onPick,
    required this.onDismiss,
  });

  final Palette palette;
  final Type type;
  final PayloadType current;
  final LayerLink link;
  final double gap;
  final ValueChanged<PayloadType> onPick;
  final VoidCallback onDismiss;

  @override
  State<_TypePicker> createState() => _TypePickerState();
}

class _TypePickerState extends State<_TypePicker> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final t = widget.type;
    final size = MediaQuery.sizeOf(context);
    final width = math.min(400.0, size.width - 36);

    return KeyboardListener(
      focusNode: _focus,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss();
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDismiss,
              child: ColoredBox(color: p.ink.withValues(alpha: 0.10)),
            ),
          ),
          CompositedTransformFollower(
            link: widget.link,
            showWhenUnlinked: false,
            offset: Offset(0, widget.gap),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: width,
                decoration: BoxDecoration(
                  color: p.ground,
                  border: Border.all(color: p.ink, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 4, color: _accent),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.min(568, size.height * 0.72),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final type in PayloadType.values)
                              _row(p, t, type),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Palette p, Type t, PayloadType type) {
    final selected = type == widget.current;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onPick(type),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            border: Border(bottom: BorderSide(color: p.hair, width: 1)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                child: Text(
                  payloadTypeNames[type]!,
                  style: t.body(
                    12,
                    weight: FontWeight.w600,
                    color: selected ? _accentInk : p.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  payloadTypeFormats[type]!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: t.mono(10, color: selected ? _accentInk : p.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
