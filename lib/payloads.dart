import 'dart:convert';

/// Payload types, their fields, and the strings they compose.
///
/// Everything here is pure: the editor holds the field values, this file turns
/// them into the exact characters that get encoded, and the QR encoder takes it
/// from there. No widgets, no I/O, no platform code.
enum PayloadType {
  text,
  url,
  wifi,
  email,
  phone,
  sms,
  geo,
  calendar,
  contact,
  bitcoin,
  lightning,
  monero,
  zcash,
  evm,
}

const payloadTypeNames = <PayloadType, String>{
  PayloadType.text: 'TEXT',
  PayloadType.url: 'URL',
  PayloadType.wifi: 'WI-FI',
  PayloadType.email: 'EMAIL',
  PayloadType.phone: 'PHONE',
  PayloadType.sms: 'SMS',
  PayloadType.geo: 'GEO',
  PayloadType.calendar: 'CALENDAR',
  PayloadType.contact: 'CONTACT',
  PayloadType.bitcoin: 'BITCOIN',
  PayloadType.lightning: 'LIGHTNING',
  PayloadType.monero: 'MONERO',
  PayloadType.zcash: 'ZCASH',
  PayloadType.evm: 'ETHEREUM',
};

const payloadTypeFormats = <PayloadType, String>{
  PayloadType.text: 'PLAIN UTF-8',
  PayloadType.url: 'HTTPS://…',
  PayloadType.wifi: 'WIFI:T:…;S:…;P:…;;',
  PayloadType.email: 'MAILTO:…',
  PayloadType.phone: 'TEL:…',
  PayloadType.sms: 'SMSTO:…',
  PayloadType.geo: 'GEO:LAT,LNG',
  PayloadType.calendar: 'ICALENDAR VEVENT',
  PayloadType.contact: 'VCARD 3.0',
  PayloadType.bitcoin: 'BIP 21',
  PayloadType.lightning: 'BOLT 11',
  PayloadType.monero: 'MONERO:…',
  PayloadType.zcash: 'ZIP 321',
  PayloadType.evm: 'EIP-681',
};

enum FieldKind { text, choice }

/// One input in a template. `choice` fields are drawn as a row of keys rather
/// than a text box, and always hold one of [options].
class FieldSpec {
  const FieldSpec.text(
    this.id,
    this.label, {
    this.hint = '',
    this.lines = 1,
  }) : kind = FieldKind.text,
       options = null,
       fallback = '';

  const FieldSpec.choice(
    this.id,
    this.label,
    this.options, {
    this.fallback = '',
  }) : kind = FieldKind.choice,
       hint = '',
       lines = 1;

  final String id;
  final String label;
  final FieldKind kind;
  final String hint;
  final int lines;
  final List<String>? options;
  final String fallback;

  String get defaultValue =>
      kind == FieldKind.choice ? (fallback.isEmpty ? options!.first : fallback) : fallback;
}

const _textFields = <FieldSpec>[
  FieldSpec.text('body', 'PAYLOAD', hint: 'Type or paste', lines: 6),
];

const _fields = <PayloadType, List<FieldSpec>>{
  PayloadType.text: _textFields,
  PayloadType.url: [
    FieldSpec.text('url', 'URL', hint: 'https://example.com'),
  ],
  PayloadType.wifi: [
    FieldSpec.text('ssid', 'NETWORK NAME', hint: 'Cafe-Werkstatt-5G'),
    FieldSpec.text('pass', 'PASSWORD', hint: 'Correct horse battery staple'),
    FieldSpec.choice('security', 'SECURITY', ['WPA2', 'WPA', 'WEP', 'NONE']),
    FieldSpec.choice('hidden', 'HIDDEN NETWORK', ['NO', 'YES']),
  ],
  PayloadType.email: [
    FieldSpec.text('to', 'TO', hint: 'name@example.com'),
    FieldSpec.text('subject', 'SUBJECT'),
    FieldSpec.text('body', 'MESSAGE', lines: 3),
  ],
  PayloadType.phone: [
    FieldSpec.text('number', 'PHONE NUMBER', hint: '+421 900 000 000'),
  ],
  PayloadType.sms: [
    FieldSpec.text('number', 'PHONE NUMBER', hint: '+421 900 000 000'),
    FieldSpec.text('message', 'MESSAGE', lines: 3),
  ],
  PayloadType.geo: [
    FieldSpec.text('lat', 'LATITUDE', hint: '48.1486'),
    FieldSpec.text('lng', 'LONGITUDE', hint: '17.1077'),
  ],
  PayloadType.calendar: [
    FieldSpec.text('summary', 'TITLE', hint: 'Dinner'),
    FieldSpec.text('location', 'LOCATION', hint: 'Cafe Werkstatt'),
    FieldSpec.text('start', 'STARTS', hint: '2026-10-31 18:00'),
    FieldSpec.text('end', 'ENDS', hint: '2026-10-31 20:00'),
    FieldSpec.text('description', 'NOTES', lines: 2),
  ],
  PayloadType.contact: [
    FieldSpec.text('name', 'NAME', hint: 'Ada Lovelace'),
    FieldSpec.text('org', 'ORGANISATION'),
    FieldSpec.text('phone', 'PHONE', hint: '+421 900 000 000'),
    FieldSpec.text('email', 'EMAIL', hint: 'ada@example.com'),
    FieldSpec.text('url', 'WEBSITE', hint: 'https://example.com'),
  ],
  PayloadType.bitcoin: [
    FieldSpec.text('address', 'ADDRESS', hint: 'bc1q…'),
    FieldSpec.text('amount', 'AMOUNT', hint: '0.0015'),
    FieldSpec.text('label', 'LABEL', hint: 'Invoice 42'),
    FieldSpec.text('message', 'MESSAGE'),
  ],
  PayloadType.lightning: [
    FieldSpec.text('invoice', 'INVOICE', hint: 'lnbc…', lines: 2),
  ],
  PayloadType.monero: [
    FieldSpec.text('address', 'ADDRESS', hint: '4… or 8…', lines: 2),
    FieldSpec.text('amount', 'AMOUNT', hint: '0.25'),
    FieldSpec.text('payment', 'PAYMENT ID'),
    FieldSpec.text('name', 'RECIPIENT'),
  ],
  PayloadType.zcash: [
    FieldSpec.text('address', 'ADDRESS', hint: 'zs1… or t1…', lines: 2),
    FieldSpec.text('amount', 'AMOUNT', hint: '0.5'),
    FieldSpec.text('memo', 'MEMO', lines: 2),
  ],
  PayloadType.evm: [
    FieldSpec.text('address', 'ADDRESS', hint: '0x…'),
    FieldSpec.text('chain', 'CHAIN ID', hint: '1'),
    FieldSpec.text('value', 'VALUE IN WEI', hint: '1000000000000000'),
  ],
};

List<FieldSpec> fieldsFor(PayloadType type) => _fields[type] ?? _textFields;

/// Builds the string a template encodes. Returns an empty string when the
/// template's essential field is still blank, which the editor reads as "no
/// symbol yet" rather than as an error.
String composePayload(PayloadType type, Map<String, String> values) {
  String at(String id) => (values[id] ?? '').trim();
  String pick(String id) {
    final spec = fieldsFor(type).firstWhere((f) => f.id == id);
    final raw = (values[id] ?? '').trim();
    return raw.isEmpty ? spec.defaultValue : raw;
  }

  switch (type) {
    case PayloadType.text:
      return values['body'] ?? '';

    case PayloadType.url:
      final raw = at('url');
      if (raw.isEmpty) return '';
      return RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(raw) ? raw : 'https://$raw';

    case PayloadType.wifi:
      final ssid = at('ssid');
      if (ssid.isEmpty) return '';
      final security = pick('security');
      final pass = at('pass');
      final hidden = pick('hidden') == 'YES';
      final out = StringBuffer('WIFI:');
      out.write('T:${security == 'NONE' ? 'nopass' : security};');
      out.write('S:${_wifi(ssid)};');
      if (security != 'NONE' && pass.isNotEmpty) out.write('P:${_wifi(pass)};');
      if (hidden) out.write('H:true;');
      out.write(';');
      return out.toString();

    case PayloadType.email:
      final to = at('to');
      if (to.isEmpty) return '';
      final query = <String>[
        if (at('subject').isNotEmpty) 'subject=${Uri.encodeComponent(at('subject'))}',
        if (at('body').isNotEmpty) 'body=${Uri.encodeComponent(at('body'))}',
      ];
      return query.isEmpty ? 'mailto:$to' : 'mailto:$to?${query.join('&')}';

    case PayloadType.phone:
      final digits = _dial(at('number'));
      return digits.isEmpty ? '' : 'tel:$digits';

    case PayloadType.sms:
      final number = _dial(at('number'));
      if (number.isEmpty) return '';
      final message = at('message');
      return message.isEmpty ? 'SMSTO:$number' : 'SMSTO:$number:$message';

    case PayloadType.geo:
      final lat = at('lat');
      final lng = at('lng');
      if (!_inRange(lat, 90) || !_inRange(lng, 180)) return '';
      return 'geo:$lat,$lng';

    case PayloadType.calendar:
      final summary = at('summary');
      if (summary.isEmpty) return '';
      final start = _icalDate(at('start'));
      final end = _icalDate(at('end'));
      return [
        'BEGIN:VCALENDAR',
        'VERSION:2.0',
        'BEGIN:VEVENT',
        'SUMMARY:${_icalEscape(summary)}',
        if (start.isNotEmpty) 'DTSTART:$start',
        if (end.isNotEmpty) 'DTEND:$end',
        if (at('location').isNotEmpty) 'LOCATION:${_icalEscape(at('location'))}',
        if (at('description').isNotEmpty)
          'DESCRIPTION:${_icalEscape(at('description'))}',
        'END:VEVENT',
        'END:VCALENDAR',
      ].join('\r\n');

    case PayloadType.contact:
      final name = at('name');
      if (name.isEmpty) return '';
      return [
        'BEGIN:VCARD',
        'VERSION:3.0',
        'N:${_vcardEscape(name)}',
        'FN:${_vcardEscape(name)}',
        if (at('org').isNotEmpty) 'ORG:${_vcardEscape(at('org'))}',
        if (at('phone').isNotEmpty) 'TEL:${_vcardLine(at('phone'))}',
        if (at('email').isNotEmpty) 'EMAIL:${_vcardLine(at('email'))}',
        if (at('url').isNotEmpty) 'URL:${_vcardLine(at('url'))}',
        'END:VCARD',
      ].join('\r\n');

    case PayloadType.bitcoin:
      final address = at('address');
      if (address.isEmpty) return '';
      final query = <String>[
        if (_numeric(at('amount'))) 'amount=${at('amount')}',
        if (at('label').isNotEmpty) 'label=${Uri.encodeComponent(at('label'))}',
        if (at('message').isNotEmpty) 'message=${Uri.encodeComponent(at('message'))}',
      ];
      return query.isEmpty
          ? 'bitcoin:$address'
          : 'bitcoin:$address?${query.join('&')}';

    case PayloadType.lightning:
      final invoice = at('invoice').replaceAll(RegExp(r'\s'), '');
      if (invoice.isEmpty) return '';
      return invoice.startsWith('lightning:') ? invoice : 'lightning:$invoice';

    case PayloadType.monero:
      final address = at('address');
      if (address.isEmpty) return '';
      final query = <String>[
        if (_numeric(at('amount'))) 'tx_amount=${at('amount')}',
        if (at('payment').isNotEmpty) 'tx_payment_id=${at('payment')}',
        if (at('name').isNotEmpty) 'recipient_name=${Uri.encodeComponent(at('name'))}',
      ];
      return query.isEmpty
          ? 'monero:$address'
          : 'monero:$address?${query.join('&')}';

    case PayloadType.zcash:
      final address = at('address');
      if (address.isEmpty) return '';
      final memo = at('memo');
      final query = <String>[
        if (_numeric(at('amount'))) 'amount=${at('amount')}',
        if (memo.isNotEmpty)
          'memo=${base64Url.encode(utf8.encode(memo)).replaceAll('=', '')}',
      ];
      return query.isEmpty ? 'zcash:$address' : 'zcash:$address?${query.join('&')}';

    case PayloadType.evm:
      final address = at('address');
      if (address.isEmpty) return '';
      final chain = at('chain');
      final base = chain.isEmpty ? 'ethereum:$address' : 'ethereum:$address@$chain';
      return _wei(at('value')) ? '$base?value=${at('value')}' : base;
  }
}

/// Plain non-negative decimal: digits, optionally one fractional part. No
/// signs, exponents, NaN or Infinity.
bool _numeric(String value) => RegExp(r'^\d+(\.\d+)?$').hasMatch(value);

/// Whole number (wei).
bool _wei(String value) => RegExp(r'^\d+$').hasMatch(value);

bool _inRange(String value, double max) {
  if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(value)) return false;
  return double.parse(value).abs() <= max;
}

String _dial(String raw) => raw.replaceAll(RegExp(r'[^0-9+]'), '');

/// ZXing's WIFI: escaping — backslash, semicolon, comma, colon and double quote.
String _wifi(String value) =>
    value.replaceAllMapped(RegExp(r'([\\;,:"])'), (m) => '\\${m[1]}');

String _icalEscape(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll(RegExp(r'\r\n|\r|\n'), '\\n');

String _vcardEscape(String value) => value
    .replaceAll('\\', '\\\\')
    .replaceAll(';', '\\;')
    .replaceAll(',', '\\,')
    .replaceAll(RegExp(r'\r\n|\r|\n'), '\\n');

/// Values that must stay on one line (TEL, EMAIL, URL): line breaks would let
/// input inject extra vCard properties, so they are stripped.
String _vcardLine(String value) => value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();

/// "2026-10-31 18:00" → "20261031T180000". Anything already stamped passes
/// through; a bare date gets midnight.
String _icalDate(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  if (digits.length >= 14) return digits.substring(0, 14);
  final date = digits.padRight(8, '0').substring(0, 8);
  final clock = digits.length > 8
      ? digits.substring(8).padRight(6, '0').substring(0, 6)
      : '000000';
  return '${date}T$clock';
}
