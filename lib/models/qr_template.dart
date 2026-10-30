

enum QrTemplateType {
  text('Text', 'Plain text or custom code'),
  url('URL', 'Web link'),
  wifi('Wi-Fi network', 'Wireless network credentials'),
  calendar('Calendar event', 'iCalendar VEVENT entry'),
  vcard('Contact information (vCard)', 'vCard 3.0 contact details'),
  email('Email address', 'mailto link'),
  phone('Phone number', 'tel link'),
  sms('SMS text message', 'SMSTO link'),
  geo('Geo location', 'GPS coordinates'),
  bitcoin('Bitcoin', 'BIP-21 Bitcoin URI'),
  lightning('Lightning invoice', 'BOLT-11 Lightning payment'),
  monero('Monero', 'Monero URI with tx parameters'),
  zcash('Zcash', 'ZIP-321 Zcash URI'),
  ethereum('Ethereum / EVM', 'EIP-681 Ethereum transfer');

  final String label;
  final String description;
  const QrTemplateType(this.label, this.description);
}

/// Abstract state representation for any template
abstract class QrTemplateData {
  QrTemplateType get type;
  String buildPayload();
  Map<String, String> toMap();
}

/// Raw text template
class TextTemplateData implements QrTemplateData {
  final String text;
  TextTemplateData({this.text = ''});

  @override
  QrTemplateType get type => QrTemplateType.text;

  @override
  String buildPayload() => text;

  @override
  Map<String, String> toMap() => {'text': text};
}

/// URL template
class UrlTemplateData implements QrTemplateData {
  final String url;
  UrlTemplateData({this.url = ''});

  @override
  QrTemplateType get type => QrTemplateType.url;

  @override
  String buildPayload() {
    if (url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (!trimmed.contains('://') && !trimmed.startsWith('mailto:') && !trimmed.startsWith('tel:')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  @override
  Map<String, String> toMap() => {'url': url};
}

/// Wi-Fi template
class WifiTemplateData implements QrTemplateData {
  final String ssid;
  final String password;
  final String security; // WPA/WPA2, WEP, nopass
  final bool hidden;

  WifiTemplateData({
    this.ssid = '',
    this.password = '',
    this.security = 'WPA/WPA2',
    this.hidden = false,
  });

  @override
  QrTemplateType get type => QrTemplateType.wifi;

  static String escapeWifiString(String s) {
    // Escape \ ; , : " with backslash
    return s
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:')
        .replaceAll('"', r'\"');
  }

  @override
  String buildPayload() {
    if (ssid.isEmpty) return '';
    final secType = security == 'nopass' || security == 'None'
        ? 'nopass'
        : (security == 'WEP' ? 'WEP' : 'WPA');
    final escapedSsid = escapeWifiString(ssid);
    final escapedPass = escapeWifiString(password);
    final hiddenStr = hidden ? 'H:true;' : '';
    final passStr = secType == 'nopass' ? '' : 'P:$escapedPass;';
    return 'WIFI:S:$escapedSsid;T:$secType;$passStr$hiddenStr;';
  }

  @override
  Map<String, String> toMap() => {
        'ssid': ssid,
        'password': password,
        'security': security,
        'hidden': hidden ? 'true' : 'false',
      };
}

/// Calendar event template
class CalendarTemplateData implements QrTemplateData {
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final String location;
  final String description;

  CalendarTemplateData({
    this.title = '',
    this.startDate,
    this.endDate,
    this.location = '',
    this.description = '',
  });

  @override
  QrTemplateType get type => QrTemplateType.calendar;

  static String _formatIcalDate(DateTime dt) {
    final utc = dt.toUtc();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}${twoDigits(utc.month)}${twoDigits(utc.day)}T'
        '${twoDigits(utc.hour)}${twoDigits(utc.minute)}${twoDigits(utc.second)}Z';
  }

  @override
  String buildPayload() {
    if (title.trim().isEmpty) return '';
    final now = DateTime.now();
    final st = startDate ?? now;
    final et = endDate ?? st.add(const Duration(hours: 1));

    final sb = StringBuffer();
    sb.writeln('BEGIN:VCALENDAR');
    sb.writeln('VERSION:2.0');
    sb.writeln('BEGIN:VEVENT');
    sb.writeln('SUMMARY:$title');
    sb.writeln('DTSTART:${_formatIcalDate(st)}');
    sb.writeln('DTEND:${_formatIcalDate(et)}');
    if (location.isNotEmpty) sb.writeln('LOCATION:$location');
    if (description.isNotEmpty) sb.writeln('DESCRIPTION:$description');
    sb.writeln('END:VEVENT');
    sb.write('END:VCALENDAR');
    return sb.toString();
  }

  @override
  Map<String, String> toMap() => {
        'title': title,
        'startDate': startDate?.toIso8601String() ?? '',
        'endDate': endDate?.toIso8601String() ?? '',
        'location': location,
        'description': description,
      };
}

/// vCard Contact template
class VCardTemplateData implements QrTemplateData {
  final String name;
  final String company;
  final String phone;
  final String email;
  final String address;
  final String address2;
  final String website;
  final String memo;

  VCardTemplateData({
    this.name = '',
    this.company = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.address2 = '',
    this.website = '',
    this.memo = '',
  });

  @override
  QrTemplateType get type => QrTemplateType.vcard;

  @override
  String buildPayload() {
    if (name.trim().isEmpty && company.trim().isEmpty && phone.trim().isEmpty) return '';
    final sb = StringBuffer();
    sb.writeln('BEGIN:VCARD');
    sb.writeln('VERSION:3.0');
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      final lastName = parts.length > 1 ? parts.last : '';
      final firstName = parts.length > 1 ? parts.sublist(0, parts.length - 1).join(' ') : parts.first;
      sb.writeln('N:$lastName;$firstName;;;');
      sb.writeln('FN:$name');
    }
    if (company.isNotEmpty) sb.writeln('ORG:$company');
    if (phone.isNotEmpty) sb.writeln('TEL;TYPE=CELL:$phone');
    if (email.isNotEmpty) sb.writeln('EMAIL;TYPE=INTERNET:$email');
    if (address.isNotEmpty || address2.isNotEmpty) {
      final fullAddr = [address, address2].where((s) => s.isNotEmpty).join(', ');
      sb.writeln('ADR;TYPE=WORK:;;$fullAddr;;;;');
    }
    if (website.isNotEmpty) sb.writeln('URL:$website');
    if (memo.isNotEmpty) sb.writeln('NOTE:$memo');
    sb.write('END:VCARD');
    return sb.toString();
  }

  @override
  Map<String, String> toMap() => {
        'name': name,
        'company': company,
        'phone': phone,
        'email': email,
        'address': address,
        'address2': address2,
        'website': website,
        'memo': memo,
      };
}

/// Email template
class EmailTemplateData implements QrTemplateData {
  final String to;
  final String subject;
  final String body;

  EmailTemplateData({
    this.to = '',
    this.subject = '',
    this.body = '',
  });

  @override
  QrTemplateType get type => QrTemplateType.email;

  @override
  String buildPayload() {
    if (to.trim().isEmpty) return '';
    final queryParams = <String>[];
    if (subject.isNotEmpty) queryParams.add('subject=${Uri.encodeComponent(subject)}');
    if (body.isNotEmpty) queryParams.add('body=${Uri.encodeComponent(body)}');
    final query = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    return 'mailto:${to.trim()}$query';
  }

  @override
  Map<String, String> toMap() => {
        'to': to,
        'subject': subject,
        'body': body,
      };
}

/// Phone template
class PhoneTemplateData implements QrTemplateData {
  final String number;

  PhoneTemplateData({this.number = ''});

  @override
  QrTemplateType get type => QrTemplateType.phone;

  @override
  String buildPayload() {
    if (number.trim().isEmpty) return '';
    return 'tel:${number.trim()}';
  }

  @override
  Map<String, String> toMap() => {'number': number};
}

/// SMS template
class SmsTemplateData implements QrTemplateData {
  final String number;
  final String message;

  SmsTemplateData({this.number = '', this.message = ''});

  @override
  QrTemplateType get type => QrTemplateType.sms;

  @override
  String buildPayload() {
    if (number.trim().isEmpty) return '';
    if (message.isEmpty) return 'SMSTO:${number.trim()}';
    return 'SMSTO:${number.trim()}:$message';
  }

  @override
  Map<String, String> toMap() => {
        'number': number,
        'message': message,
      };
}

/// Geo location template
class GeoTemplateData implements QrTemplateData {
  final String latitude;
  final String longitude;
  final String query;

  GeoTemplateData({this.latitude = '', this.longitude = '', this.query = ''});

  @override
  QrTemplateType get type => QrTemplateType.geo;

  @override
  String buildPayload() {
    final lat = latitude.trim();
    final lng = longitude.trim();
    if (lat.isEmpty && lng.isEmpty && query.isEmpty) return '';
    final coords = (lat.isNotEmpty && lng.isNotEmpty) ? '$lat,$lng' : '0,0';
    if (query.isNotEmpty) {
      return 'geo:$coords?q=${Uri.encodeComponent(query)}';
    }
    return 'geo:$coords';
  }

  @override
  Map<String, String> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'query': query,
      };
}

/// Bitcoin (BIP-21) template
class BitcoinTemplateData implements QrTemplateData {
  final String address;
  final String amount;
  final String label;
  final String message;

  BitcoinTemplateData({
    this.address = '',
    this.amount = '',
    this.label = '',
    this.message = '',
  });

  @override
  QrTemplateType get type => QrTemplateType.bitcoin;

  @override
  String buildPayload() {
    final addr = address.trim();
    if (addr.isEmpty) return '';
    // Strip bitcoin: prefix if user accidentally typed it in address field
    final cleanAddr = addr.toLowerCase().startsWith('bitcoin:') ? addr.substring(8) : addr;
    final queryParams = <String>[];
    if (amount.trim().isNotEmpty) queryParams.add('amount=${amount.trim()}');
    if (label.trim().isNotEmpty) queryParams.add('label=${Uri.encodeComponent(label.trim())}');
    if (message.trim().isNotEmpty) queryParams.add('message=${Uri.encodeComponent(message.trim())}');

    final query = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    return 'bitcoin:$cleanAddr$query';
  }

  @override
  Map<String, String> toMap() => {
        'address': address,
        'amount': amount,
        'label': label,
        'message': message,
      };
}

/// Lightning invoice template
class LightningTemplateData implements QrTemplateData {
  final String invoice;

  LightningTemplateData({this.invoice = ''});

  @override
  QrTemplateType get type => QrTemplateType.lightning;

  @override
  String buildPayload() {
    final inv = invoice.trim();
    if (inv.isEmpty) return '';
    if (inv.toLowerCase().startsWith('lightning:')) return inv;
    return 'lightning:$inv';
  }

  @override
  Map<String, String> toMap() => {'invoice': invoice};
}

/// Monero template
class MoneroTemplateData implements QrTemplateData {
  final String address;
  final String amount;
  final String recipientName;
  final String paymentId;
  final String description;

  MoneroTemplateData({
    this.address = '',
    this.amount = '',
    this.recipientName = '',
    this.paymentId = '',
    this.description = '',
  });

  @override
  QrTemplateType get type => QrTemplateType.monero;

  @override
  String buildPayload() {
    final addr = address.trim();
    if (addr.isEmpty) return '';
    final cleanAddr = addr.toLowerCase().startsWith('monero:') ? addr.substring(7) : addr;
    final queryParams = <String>[];
    if (amount.trim().isNotEmpty) queryParams.add('tx_amount=${amount.trim()}');
    if (recipientName.trim().isNotEmpty) {
      queryParams.add('recipient_name=${Uri.encodeComponent(recipientName.trim())}');
    }
    if (paymentId.trim().isNotEmpty) queryParams.add('tx_payment_id=${paymentId.trim()}');
    if (description.trim().isNotEmpty) {
      queryParams.add('tx_description=${Uri.encodeComponent(description.trim())}');
    }

    final query = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    return 'monero:$cleanAddr$query';
  }

  @override
  Map<String, String> toMap() => {
        'address': address,
        'amount': amount,
        'recipientName': recipientName,
        'paymentId': paymentId,
        'description': description,
      };
}

/// Zcash (ZIP-321) template
class ZcashTemplateData implements QrTemplateData {
  final String address;
  final String amount;
  final String memo;
  final String label;

  ZcashTemplateData({
    this.address = '',
    this.amount = '',
    this.memo = '',
    this.label = '',
  });

  @override
  QrTemplateType get type => QrTemplateType.zcash;

  @override
  String buildPayload() {
    final addr = address.trim();
    if (addr.isEmpty) return '';
    final cleanAddr = addr.toLowerCase().startsWith('zcash:') ? addr.substring(6) : addr;
    final queryParams = <String>[];
    if (amount.trim().isNotEmpty) queryParams.add('amount=${amount.trim()}');
    if (memo.trim().isNotEmpty) queryParams.add('memo=${Uri.encodeComponent(memo.trim())}');
    if (label.trim().isNotEmpty) queryParams.add('label=${Uri.encodeComponent(label.trim())}');

    final query = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    return 'zcash:$cleanAddr$query';
  }

  @override
  Map<String, String> toMap() => {
        'address': address,
        'amount': amount,
        'memo': memo,
        'label': label,
      };
}

/// Ethereum / EVM (EIP-681) template
class EthereumTemplateData implements QrTemplateData {
  final String address;
  final String amount;
  final String chainId;

  EthereumTemplateData({
    this.address = '',
    this.amount = '',
    this.chainId = '',
  });

  @override
  QrTemplateType get type => QrTemplateType.ethereum;

  @override
  String buildPayload() {
    final addr = address.trim();
    if (addr.isEmpty) return '';
    final cleanAddr = addr.toLowerCase().startsWith('ethereum:') ? addr.substring(9) : addr;
    final chainSuffix = chainId.trim().isNotEmpty ? '@${chainId.trim()}' : '';
    final query = amount.trim().isNotEmpty ? '?value=${amount.trim()}' : '';
    return 'ethereum:$cleanAddr$chainSuffix$query';
  }

  @override
  Map<String, String> toMap() => {
        'address': address,
        'amount': amount,
        'chainId': chainId,
      };
}
