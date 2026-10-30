import 'package:flutter_test/flutter_test.dart';
import 'package:qrencoder/models/qr_template.dart';
import 'package:qrencoder/utils/import_utils.dart';

void main() {
  group('QR Template Encoders', () {
    test('Wi-Fi escaping and payload construction', () {
      final wifi = WifiTemplateData(
        ssid: 'Home;Network:1',
        password: 'pass;word\\123',
        security: 'WPA/WPA2',
        hidden: true,
      );
      expect(
        wifi.buildPayload(),
        r'WIFI:S:Home\;Network\:1;T:WPA;P:pass\;word\\123;H:true;;',
      );
    });

    test('Bitcoin BIP21 payload construction', () {
      final btc = BitcoinTemplateData(
        address: 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
        amount: '0.005',
        label: 'Coffee Shop',
        message: 'Order #42',
      );
      expect(
        btc.buildPayload(),
        'bitcoin:bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh?amount=0.005&label=Coffee%20Shop&message=Order%20%2342',
      );
    });

    test('Monero payload construction', () {
      final xmr = MoneroTemplateData(
        address: '44AFFq5kSiGBoA4NMDwYtN18obc8AemS33DBLWs3H7otXFT3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A',
        amount: '1.25',
        recipientName: 'Juraj',
        description: 'Monthly sub',
      );
      expect(
        xmr.buildPayload(),
        'monero:44AFFq5kSiGBoA4NMDwYtN18obc8AemS33DBLWs3H7otXFT3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A?tx_amount=1.25&recipient_name=Juraj&tx_description=Monthly%20sub',
      );
    });

    test('Zcash ZIP-321 payload construction', () {
      final zec = ZcashTemplateData(
        address: 'zs1z7rejlps4my823rgwm9vl2pp82239332sn83k4fcmagsv3e8392ldmwecm328902',
        amount: '0.1',
        memo: 'Thanks for dinner',
      );
      expect(
        zec.buildPayload(),
        'zcash:zs1z7rejlps4my823rgwm9vl2pp82239332sn83k4fcmagsv3e8392ldmwecm328902?amount=0.1&memo=Thanks%20for%20dinner',
      );
    });

    test('Ethereum EIP-681 payload construction', () {
      final eth = EthereumTemplateData(
        address: '0x1234567890123456789012345678901234567890',
        amount: '1.5',
        chainId: '1',
      );
      expect(
        eth.buildPayload(),
        'ethereum:0x1234567890123456789012345678901234567890@1?value=1.5',
      );
    });

    test('vCard 3.0 construction', () {
      final vcard = VCardTemplateData(
        name: 'Juraj Bednar',
        company: 'Parallel Polis',
        phone: '+421900000000',
        email: 'juraj@bednar.io',
      );
      final payload = vcard.buildPayload();
      expect(payload, contains('BEGIN:VCARD'));
      expect(payload, contains('N:Bednar;Juraj;;;'));
      expect(payload, contains('FN:Juraj Bednar'));
      expect(payload, contains('ORG:Parallel Polis'));
      expect(payload, contains('TEL;TYPE=CELL:+421900000000'));
      expect(payload, contains('EMAIL;TYPE=INTERNET:juraj@bednar.io'));
      expect(payload, contains('END:VCARD'));
    });
  });

  group('Import Utils Parsers', () {
    test('Parses Bitcoin URI', () {
      final res = ImportUtils.parsePayload('bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.01&label=Satoshi');
      expect(res, isA<BitcoinTemplateData>());
      final btc = res as BitcoinTemplateData;
      expect(btc.address, '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa');
      expect(btc.amount, '0.01');
      expect(btc.label, 'Satoshi');
    });

    test('Parses Monero URI', () {
      final res = ImportUtils.parsePayload('monero:44AFFq5kSiGBoA4NMDwYtN18obc8AemS33DBLWs3H7otXFT3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A?tx_amount=2.5');
      expect(res, isA<MoneroTemplateData>());
      final xmr = res as MoneroTemplateData;
      expect(xmr.address, '44AFFq5kSiGBoA4NMDwYtN18obc8AemS33DBLWs3H7otXFT3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A');
      expect(xmr.amount, '2.5');
    });

    test('Parses Wi-Fi QR string', () {
      final res = ImportUtils.parsePayload(r'WIFI:S:MyNet\;Work;T:WPA;P:secret123;H:true;;');
      expect(res, isA<WifiTemplateData>());
      final wifi = res as WifiTemplateData;
      expect(wifi.ssid, 'MyNet;Work');
      expect(wifi.password, 'secret123');
      expect(wifi.hidden, true);
    });
  });
}
