import 'package:flutter_test/flutter_test.dart';
import 'package:qrencoder/payloads.dart';

void main() {
  test('text passes through untouched', () {
    expect(composePayload(PayloadType.text, {'body': ' hello\nworld '}),
        ' hello\nworld ');
  });

  test('url gets a scheme when it has none', () {
    expect(composePayload(PayloadType.url, {'url': 'example.com/x'}),
        'https://example.com/x');
    expect(composePayload(PayloadType.url, {'url': 'mailto:a@b.c'}),
        'mailto:a@b.c');
    expect(composePayload(PayloadType.url, {'url': '  '}), '');
  });

  test('wi-fi escapes the separators ZXing reserves', () {
    expect(
      composePayload(PayloadType.wifi, {
        'ssid': 'Cafe;Werkstatt',
        'pass': 'a,b:c"d\\e',
        'security': 'WPA2',
      }),
      r'WIFI:T:WPA2;S:Cafe\;Werkstatt;P:a\,b\:c\"d\\e;;',
    );
  });

  test('an open network drops the password', () {
    expect(
      composePayload(PayloadType.wifi, {
        'ssid': 'Guest',
        'pass': 'ignored',
        'security': 'NONE',
        'hidden': 'YES',
      }),
      'WIFI:T:nopass;S:Guest;H:true;;',
    );
  });

  test('wi-fi without a network name encodes nothing', () {
    expect(composePayload(PayloadType.wifi, {'pass': 'x'}), '');
  });

  test('email encodes its subject and body', () {
    expect(
      composePayload(PayloadType.email, {
        'to': 'ada@example.com',
        'subject': 'Dinner & drinks',
        'body': 'see you at 8',
      }),
      'mailto:ada@example.com?subject=Dinner%20%26%20drinks&body=see%20you%20at%208',
    );
  });

  test('phone and sms strip punctuation from the number', () {
    expect(composePayload(PayloadType.phone, {'number': '+421 (900) 000-000'}),
        'tel:+421900000000');
    expect(
      composePayload(PayloadType.sms, {'number': '0900 000 000', 'message': 'hi'}),
      'SMSTO:0900000000:hi',
    );
  });

  test('geo needs both coordinates', () {
    expect(composePayload(PayloadType.geo, {'lat': '48.1'}), '');
    expect(composePayload(PayloadType.geo, {'lat': '48.1', 'lng': '17.1'}),
        'geo:48.1,17.1');
  });

  test('calendar stamps dates as iCalendar wants them', () {
    final payload = composePayload(PayloadType.calendar, {
      'summary': 'Dinner, with friends',
      'start': '2026-10-31 18:00',
      'end': '2026-10-31 20:30',
      'location': 'Cafe',
    });
    expect(payload, contains('SUMMARY:Dinner\\, with friends'));
    expect(payload, contains('DTSTART:20261031T180000'));
    expect(payload, contains('DTEND:20261031T203000'));
    expect(payload.startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0'), isTrue);
    expect(payload.endsWith('END:VEVENT\r\nEND:VCALENDAR'), isTrue);
  });

  test('contact builds a vCard 3.0', () {
    final payload = composePayload(PayloadType.contact, {
      'name': 'Ada Lovelace',
      'org': 'Analytical Engines',
      'phone': '+421 900 000 000',
      'email': 'ada@example.com',
    });
    expect(payload, contains('BEGIN:VCARD\r\nVERSION:3.0\r\nN:Ada Lovelace'));
    expect(payload, contains('ORG:Analytical Engines'));
    expect(payload, endsWith('END:VCARD'));
  });

  test('bitcoin follows BIP 21', () {
    expect(
      composePayload(PayloadType.bitcoin, {
        'address': 'bc1qexample',
        'amount': '0.0015',
        'label': 'Invoice 42',
      }),
      'bitcoin:bc1qexample?amount=0.0015&label=Invoice%2042',
    );
    expect(composePayload(PayloadType.bitcoin, {'amount': '1'}), '');
  });

  test('lightning keeps a BOLT 11 invoice and adds the scheme once', () {
    expect(composePayload(PayloadType.lightning, {'invoice': 'lnbc1xyz'}),
        'lightning:lnbc1xyz');
    expect(composePayload(PayloadType.lightning, {'invoice': 'lightning:lnbc1xyz'}),
        'lightning:lnbc1xyz');
  });

  test('monero and zcash use their own parameter names', () {
    expect(
      composePayload(PayloadType.monero, {
        'address': '4example',
        'amount': '0.25',
        'payment': 'abc123',
      }),
      'monero:4example?tx_amount=0.25&tx_payment_id=abc123',
    );
    expect(
      composePayload(PayloadType.zcash, {'address': 'zs1example', 'memo': 'hi'}),
      'zcash:zs1example?memo=aGk',
    );
  });

  test('evm carries the chain id and value only when given', () {
    expect(composePayload(PayloadType.evm, {'address': '0xabc'}),
        'ethereum:0xabc');
    expect(
      composePayload(PayloadType.evm, {
        'address': '0xabc',
        'chain': '137',
        'value': '1000000000000000',
      }),
      'ethereum:0xabc@137?value=1000000000000000',
    );
  });

  group('amount validation', () {
    String btc(String a) => composePayload(
        PayloadType.bitcoin, {'address': 'bc1qxyz', 'amount': a});
    test('accepts plain decimals', () {
      expect(btc('0.5'), 'bitcoin:bc1qxyz?amount=0.5');
      expect(btc('12'), 'bitcoin:bc1qxyz?amount=12');
    });
    test('drops NaN, Infinity, exponents, negatives and junk', () {
      for (final bad in ['NaN', 'Infinity', '1e400', '1e5', '-1', '+1', '.5', '1.', '1,5', '0x10']) {
        expect(btc(bad), 'bitcoin:bc1qxyz', reason: bad);
      }
    });
    test('monero, zcash and ethereum use the same rules', () {
      expect(composePayload(PayloadType.monero, {'address': 'a', 'amount': 'NaN'}), 'monero:a');
      expect(composePayload(PayloadType.zcash, {'address': 'a', 'amount': '-2'}), 'zcash:a');
      expect(composePayload(PayloadType.evm, {'address': '0x1', 'value': '1.5'}), 'ethereum:0x1');
      expect(composePayload(PayloadType.evm, {'address': '0x1', 'value': '1e18'}), 'ethereum:0x1');
      expect(composePayload(PayloadType.evm, {'address': '0x1', 'value': '1000'}), 'ethereum:0x1?value=1000');
    });
  });

  test('geo validates ranges and numbers', () {
    String geo(String a, String b) =>
        composePayload(PayloadType.geo, {'lat': a, 'lng': b});
    expect(geo('48.15', '17.1'), 'geo:48.15,17.1');
    expect(geo('-90', '180'), 'geo:-90,180');
    expect(geo('91', '0'), '');
    expect(geo('0', '181'), '');
    expect(geo('NaN', '0'), '');
    expect(geo('1e400', '0'), '');
  });

  test('vcard values cannot inject extra lines', () {
    final out = composePayload(PayloadType.contact, {
      'name': 'Ada\r\nTEL:666',
      'phone': '1\r\nURL:evil',
      'email': 'a@b.c\nNOTE:x',
      'url': 'https://x\rFN:y',
    });
    final lines = out.split('\r\n');
    expect(lines.length, 8);
    expect(lines.where((l) => l.startsWith('TEL:')).length, 1);
    expect(lines.where((l) => l.startsWith('FN:')).length, 1);
    expect(lines.where((l) => l.startsWith('NOTE:')).length, 0);
  });

  test('ical escapes bare carriage returns', () {
    final out = composePayload(PayloadType.calendar,
        {'summary': 'a\rEND:VEVENT', 'description': 'x\ny\r\nz'});
    expect(out.split('\r\n').where((l) => l == 'END:VEVENT').length, 1);
    expect(out, contains(r'SUMMARY:a\nEND:VEVENT'));
    expect(out, contains(r'DESCRIPTION:x\ny\nz'));
  });
}
