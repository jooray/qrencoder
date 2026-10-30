import '../models/qr_template.dart';

class ImportUtils {
  /// Parses an arbitrary text string (from Share intent, clipboard, or command line)
  /// into a strongly typed [QrTemplateData].
  static QrTemplateData parsePayload(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return TextTemplateData();
    }

    // 1. Bitcoin
    if (text.toLowerCase().startsWith('bitcoin:')) {
      final uri = Uri.parse(text);
      final address = uri.path;
      final amount = uri.queryParameters['amount'] ?? '';
      final label = uri.queryParameters['label'] ?? '';
      final message = uri.queryParameters['message'] ?? '';
      return BitcoinTemplateData(
        address: address,
        amount: amount,
        label: label,
        message: message,
      );
    }

    // 2. Lightning
    if (text.toLowerCase().startsWith('lightning:') ||
        text.toLowerCase().startsWith('lnbc') ||
        text.toLowerCase().startsWith('lntb')) {
      final clean = text.toLowerCase().startsWith('lightning:') ? text.substring(10) : text;
      return LightningTemplateData(invoice: clean);
    }

    // 3. Monero
    if (text.toLowerCase().startsWith('monero:')) {
      final uri = Uri.parse(text);
      final address = uri.path;
      final amount = uri.queryParameters['tx_amount'] ?? uri.queryParameters['amount'] ?? '';
      final name = uri.queryParameters['recipient_name'] ?? '';
      final paymentId = uri.queryParameters['tx_payment_id'] ?? '';
      final desc = uri.queryParameters['tx_description'] ?? '';
      return MoneroTemplateData(
        address: address,
        amount: amount,
        recipientName: name,
        paymentId: paymentId,
        description: desc,
      );
    }

    // 4. Zcash
    if (text.toLowerCase().startsWith('zcash:')) {
      final uri = Uri.parse(text);
      final address = uri.path;
      final amount = uri.queryParameters['amount'] ?? '';
      final memo = uri.queryParameters['memo'] ?? '';
      final label = uri.queryParameters['label'] ?? '';
      return ZcashTemplateData(
        address: address,
        amount: amount,
        memo: memo,
        label: label,
      );
    }

    // 5. Ethereum
    if (text.toLowerCase().startsWith('ethereum:')) {
      final uri = Uri.parse(text);
      String addressPath = uri.path;
      String chainId = '';
      if (addressPath.contains('@')) {
        final parts = addressPath.split('@');
        addressPath = parts[0];
        chainId = parts[1];
      }
      final value = uri.queryParameters['value'] ?? uri.queryParameters['amount'] ?? '';
      return EthereumTemplateData(
        address: addressPath,
        amount: value,
        chainId: chainId,
      );
    }

    // 6. Wi-Fi: WIFI:S:<ssid>;T:<type>;P:<pass>;H:<hidden>;;
    if (text.startsWith('WIFI:') || text.startsWith('wifi:')) {
      String ssid = '';
      String password = '';
      String security = 'WPA/WPA2';
      bool hidden = false;

      // Extract key-value pairs
      final body = text.substring(5);
      final parts = _parseWifiFields(body);
      ssid = parts['S'] ?? '';
      final sec = parts['T'] ?? 'WPA';
      security = sec == 'nopass' ? 'nopass' : (sec == 'WEP' ? 'WEP' : 'WPA/WPA2');
      password = parts['P'] ?? '';
      hidden = parts['H']?.toLowerCase() == 'true';

      return WifiTemplateData(
        ssid: ssid,
        password: password,
        security: security,
        hidden: hidden,
      );
    }

    // 7. vCard Contact: BEGIN:VCARD ... END:VCARD
    if (text.toUpperCase().contains('BEGIN:VCARD')) {
      String name = '';
      String company = '';
      String phone = '';
      String email = '';
      String address = '';
      String address2 = '';
      String website = '';
      String memo = '';

      final lines = text.split(RegExp(r'\r?\n'));
      for (final line in lines) {
        final l = line.trim();
        if (l.toUpperCase().startsWith('FN:')) {
          name = l.substring(3).trim();
        } else if (l.toUpperCase().startsWith('ORG:')) {
          company = l.substring(4).trim();
        } else if (l.toUpperCase().startsWith('TEL')) {
          final idx = l.indexOf(':');
          if (idx != -1) phone = l.substring(idx + 1).trim();
        } else if (l.toUpperCase().startsWith('EMAIL')) {
          final idx = l.indexOf(':');
          if (idx != -1) email = l.substring(idx + 1).trim();
        } else if (l.toUpperCase().startsWith('URL')) {
          final idx = l.indexOf(':');
          if (idx != -1) website = l.substring(idx + 1).trim();
        } else if (l.toUpperCase().startsWith('NOTE:')) {
          memo = l.substring(5).trim();
        } else if (l.toUpperCase().startsWith('ADR')) {
          final idx = l.indexOf(':');
          if (idx != -1) {
            final adrBody = l.substring(idx + 1);
            final parts = adrBody.split(';');
            final nonFields = parts.where((p) => p.trim().isNotEmpty).toList();
            if (nonFields.isNotEmpty) address = nonFields.first.trim();
            if (nonFields.length > 1) address2 = nonFields.sublist(1).join(', ').trim();
          }
        }
      }

      return VCardTemplateData(
        name: name,
        company: company,
        phone: phone,
        email: email,
        address: address,
        address2: address2,
        website: website,
        memo: memo,
      );
    }

    // 8. iCalendar: BEGIN:VCALENDAR or BEGIN:VEVENT
    if (text.toUpperCase().contains('BEGIN:VEVENT') || text.toUpperCase().contains('BEGIN:VCALENDAR')) {
      String title = '';
      DateTime? start;
      DateTime? end;
      String location = '';
      String description = '';

      final lines = text.split(RegExp(r'\r?\n'));
      for (final line in lines) {
        final l = line.trim();
        if (l.toUpperCase().startsWith('SUMMARY:')) {
          title = l.substring(8).trim();
        } else if (l.toUpperCase().startsWith('LOCATION:')) {
          location = l.substring(9).trim();
        } else if (l.toUpperCase().startsWith('DESCRIPTION:')) {
          description = l.substring(12).trim();
        } else if (l.toUpperCase().startsWith('DTSTART:')) {
          start = _parseIcalDate(l.substring(8).trim());
        } else if (l.toUpperCase().startsWith('DTEND:')) {
          end = _parseIcalDate(l.substring(6).trim());
        }
      }

      return CalendarTemplateData(
        title: title,
        startDate: start,
        endDate: end,
        location: location,
        description: description,
      );
    }

    // 9. Email (mailto:)
    if (text.toLowerCase().startsWith('mailto:')) {
      final uri = Uri.parse(text);
      return EmailTemplateData(
        to: uri.path,
        subject: uri.queryParameters['subject'] ?? '',
        body: uri.queryParameters['body'] ?? '',
      );
    }

    // 10. Phone (tel:)
    if (text.toLowerCase().startsWith('tel:')) {
      return PhoneTemplateData(number: text.substring(4));
    }

    // 11. SMS (smsto: or sms:)
    if (text.toLowerCase().startsWith('smsto:') || text.toLowerCase().startsWith('sms:')) {
      final prefix = text.toLowerCase().startsWith('smsto:') ? 6 : 4;
      final body = text.substring(prefix);
      final colonIdx = body.indexOf(':');
      if (colonIdx != -1) {
        return SmsTemplateData(
          number: body.substring(0, colonIdx),
          message: body.substring(colonIdx + 1),
        );
      }
      return SmsTemplateData(number: body);
    }

    // 12. Geo location (geo:)
    if (text.toLowerCase().startsWith('geo:')) {
      final uri = Uri.parse(text);
      final coords = uri.path.split(',');
      final lat = coords.isNotEmpty ? coords[0] : '';
      final lng = coords.length > 1 ? coords[1] : '';
      final q = uri.queryParameters['q'] ?? '';
      return GeoTemplateData(latitude: lat, longitude: lng, query: q);
    }

    // 13. Web URL
    if (text.toLowerCase().startsWith('http://') || text.toLowerCase().startsWith('https://')) {
      return UrlTemplateData(url: text);
    }

    // Fallback: raw text
    return TextTemplateData(text: text);
  }

  static Map<String, String> _parseWifiFields(String input) {
    final result = <String, String>{};
    final sb = StringBuffer();
    String? currentKey;
    bool escaping = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (escaping) {
        sb.write(char);
        escaping = false;
        continue;
      }

      if (char == r'\') {
        escaping = true;
        continue;
      }

      if (char == ':' && currentKey == null) {
        currentKey = sb.toString();
        sb.clear();
        continue;
      }

      if (char == ';') {
        if (currentKey != null) {
          result[currentKey] = sb.toString();
          currentKey = null;
          sb.clear();
        }
        continue;
      }

      sb.write(char);
    }

    return result;
  }

  static DateTime? _parseIcalDate(String dateStr) {
    try {
      // YYYYMMDDTHHmmssZ or YYYYMMDDTHHmmss
      final clean = dateStr.replaceAll('Z', '');
      if (clean.length < 15) return null;
      final y = int.parse(clean.substring(0, 4));
      final m = int.parse(clean.substring(4, 6));
      final d = int.parse(clean.substring(6, 8));
      final h = int.parse(clean.substring(9, 11));
      final min = int.parse(clean.substring(11, 13));
      final s = int.parse(clean.substring(13, 15));
      return DateTime.utc(y, m, d, h, min, s);
    } catch (_) {
      return null;
    }
  }
}
