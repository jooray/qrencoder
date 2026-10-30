import 'package:flutter/material.dart';
import '../../models/qr_template.dart';

typedef OnTemplateChanged = void Function(QrTemplateData data);

class TemplateFormWidget extends StatelessWidget {
  final QrTemplateData data;
  final OnTemplateChanged onChanged;
  final FocusNode? primaryFocusNode;

  const TemplateFormWidget({
    super.key,
    required this.data,
    required this.onChanged,
    this.primaryFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final type = data.type;
    switch (type) {
      case QrTemplateType.text:
        final t = data as TextTemplateData;
        return _buildTextField(
          label: 'Content / Text',
          value: t.text,
          maxLines: 6,
          focusNode: primaryFocusNode,
          onChanged: (val) => onChanged(TextTemplateData(text: val)),
        );

      case QrTemplateType.url:
        final u = data as UrlTemplateData;
        return _buildTextField(
          label: 'URL',
          value: u.url,
          hint: 'https://example.com',
          focusNode: primaryFocusNode,
          keyboardType: TextInputType.url,
          onChanged: (val) => onChanged(UrlTemplateData(url: val)),
        );

      case QrTemplateType.wifi:
        final w = data as WifiTemplateData;
        return Column(
          children: [
            _buildTextField(
              label: 'SSID / Network Name',
              value: w.ssid,
              focusNode: primaryFocusNode,
              onChanged: (val) => onChanged(WifiTemplateData(
                ssid: val,
                password: w.password,
                security: w.security,
                hidden: w.hidden,
              )),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Password',
              value: w.password,
              obscureText: true,
              onChanged: (val) => onChanged(WifiTemplateData(
                ssid: w.ssid,
                password: val,
                security: w.security,
                hidden: w.hidden,
              )),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: w.security,
                    decoration: const InputDecoration(
                      labelText: 'Network type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'WPA/WPA2', child: Text('WPA / WPA2 / WPA3')),
                      DropdownMenuItem(value: 'WEP', child: Text('WEP')),
                      DropdownMenuItem(value: 'nopass', child: Text('No Password')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        onChanged(WifiTemplateData(
                          ssid: w.ssid,
                          password: w.password,
                          security: val,
                          hidden: w.hidden,
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: w.hidden,
                      onChanged: (val) => onChanged(WifiTemplateData(
                        ssid: w.ssid,
                        password: w.password,
                        security: w.security,
                        hidden: val ?? false,
                      )),
                    ),
                    const Text('Hidden'),
                  ],
                ),
              ],
            ),
          ],
        );

      case QrTemplateType.calendar:
        final c = data as CalendarTemplateData;
        return Column(
          children: [
            _buildTextField(
              label: 'Event title',
              value: c.title,
              focusNode: primaryFocusNode,
              onChanged: (val) => onChanged(CalendarTemplateData(
                title: val,
                startDate: c.startDate,
                endDate: c.endDate,
                location: c.location,
                description: c.description,
              )),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Location',
              value: c.location,
              onChanged: (val) => onChanged(CalendarTemplateData(
                title: c.title,
                startDate: c.startDate,
                endDate: c.endDate,
                location: val,
                description: c.description,
              )),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Description',
              value: c.description,
              maxLines: 3,
              onChanged: (val) => onChanged(CalendarTemplateData(
                title: c.title,
                startDate: c.startDate,
                endDate: c.endDate,
                location: c.location,
                description: val,
              )),
            ),
          ],
        );

      case QrTemplateType.vcard:
        final v = data as VCardTemplateData;
        return Column(
          children: [
            _buildTextField(
              label: 'Full Name',
              value: v.name,
              focusNode: primaryFocusNode,
              onChanged: (val) => onChanged(VCardTemplateData(
                name: val,
                company: v.company,
                phone: v.phone,
                email: v.email,
                address: v.address,
                address2: v.address2,
                website: v.website,
                memo: v.memo,
              )),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Company',
                    value: v.company,
                    onChanged: (val) => onChanged(VCardTemplateData(
                      name: v.name,
                      company: val,
                      phone: v.phone,
                      email: v.email,
                      address: v.address,
                      address2: v.address2,
                      website: v.website,
                      memo: v.memo,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Phone number',
                    value: v.phone,
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => onChanged(VCardTemplateData(
                      name: v.name,
                      company: v.company,
                      phone: val,
                      email: v.email,
                      address: v.address,
                      address2: v.address2,
                      website: v.website,
                      memo: v.memo,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Email',
              value: v.email,
              keyboardType: TextInputType.emailAddress,
              onChanged: (val) => onChanged(VCardTemplateData(
                name: v.name,
                company: v.company,
                phone: v.phone,
                email: val,
                address: v.address,
                address2: v.address2,
                website: v.website,
                memo: v.memo,
              )),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Address',
              value: v.address,
              onChanged: (val) => onChanged(VCardTemplateData(
                name: v.name,
                company: v.company,
                phone: v.phone,
                email: v.email,
                address: val,
                address2: v.address2,
                website: v.website,
                memo: v.memo,
              )),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Website',
              value: v.website,
              keyboardType: TextInputType.url,
              onChanged: (val) => onChanged(VCardTemplateData(
                name: v.name,
                company: v.company,
                phone: v.phone,
                email: v.email,
                address: v.address,
                address2: v.address2,
                website: val,
                memo: v.memo,
              )),
            ),
          ],
        );

      case QrTemplateType.bitcoin:
        final b = data as BitcoinTemplateData;
        return Column(
          children: [
            _buildTextField(
              label: 'Bitcoin address',
              value: b.address,
              focusNode: primaryFocusNode,
              hint: 'bc1q...',
              onChanged: (val) => onChanged(BitcoinTemplateData(
                address: val,
                amount: b.amount,
                label: b.label,
                message: b.message,
              )),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Amount (BTC)',
                    value: b.amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hint: '0.001',
                    onChanged: (val) => onChanged(BitcoinTemplateData(
                      address: b.address,
                      amount: val,
                      label: b.label,
                      message: b.message,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Label',
                    value: b.label,
                    hint: 'Merchant Name',
                    onChanged: (val) => onChanged(BitcoinTemplateData(
                      address: b.address,
                      amount: b.amount,
                      label: val,
                      message: b.message,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Message',
              value: b.message,
              hint: 'Order #1234',
              onChanged: (val) => onChanged(BitcoinTemplateData(
                address: b.address,
                amount: b.amount,
                label: b.label,
                message: val,
              )),
            ),
          ],
        );

      case QrTemplateType.lightning:
        final l = data as LightningTemplateData;
        return _buildTextField(
          label: 'Lightning invoice',
          value: l.invoice,
          focusNode: primaryFocusNode,
          maxLines: 4,
          hint: 'lnbc...',
          onChanged: (val) => onChanged(LightningTemplateData(invoice: val)),
        );

      case QrTemplateType.monero:
        final m = data as MoneroTemplateData;
        return Column(
          children: [
            _buildTextField(
              label: 'Monero address',
              value: m.address,
              focusNode: primaryFocusNode,
              hint: '4...',
              onChanged: (val) => onChanged(MoneroTemplateData(
                address: val,
                amount: m.amount,
                recipientName: m.recipientName,
                paymentId: m.paymentId,
                description: m.description,
              )),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Amount (XMR)',
                    value: m.amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hint: '1.0',
                    onChanged: (val) => onChanged(MoneroTemplateData(
                      address: m.address,
                      amount: val,
                      recipientName: m.recipientName,
                      paymentId: m.paymentId,
                      description: m.description,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Recipient name',
                    value: m.recipientName,
                    onChanged: (val) => onChanged(MoneroTemplateData(
                      address: m.address,
                      amount: m.amount,
                      recipientName: val,
                      paymentId: m.paymentId,
                      description: m.description,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Payment ID',
              value: m.paymentId,
              onChanged: (val) => onChanged(MoneroTemplateData(
                address: m.address,
                amount: m.amount,
                recipientName: m.recipientName,
                paymentId: val,
                description: m.description,
              )),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Description',
              value: m.description,
              onChanged: (val) => onChanged(MoneroTemplateData(
                address: m.address,
                amount: m.amount,
                recipientName: m.recipientName,
                paymentId: m.paymentId,
                description: val,
              )),
            ),
          ],
        );

      case QrTemplateType.zcash:
        final z = data as ZcashTemplateData;
        return Column(
          children: [
            _buildTextField(
              label: 'Zcash address',
              value: z.address,
              focusNode: primaryFocusNode,
              hint: 'zs1...',
              onChanged: (val) => onChanged(ZcashTemplateData(
                address: val,
                amount: z.amount,
                memo: z.memo,
                label: z.label,
              )),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Amount (ZEC)',
                    value: z.amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hint: '0.1',
                    onChanged: (val) => onChanged(ZcashTemplateData(
                      address: z.address,
                      amount: val,
                      memo: z.memo,
                      label: z.label,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Label',
                    value: z.label,
                    onChanged: (val) => onChanged(ZcashTemplateData(
                      address: z.address,
                      amount: z.amount,
                      memo: z.memo,
                      label: val,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Memo',
              value: z.memo,
              onChanged: (val) => onChanged(ZcashTemplateData(
                address: z.address,
                amount: z.amount,
                memo: val,
                label: z.label,
              )),
            ),
          ],
        );

      case QrTemplateType.ethereum:
        final e = data as EthereumTemplateData;
        return Column(
          children: [
            _buildTextField(
              label: 'Ethereum address',
              value: e.address,
              focusNode: primaryFocusNode,
              hint: '0x...',
              onChanged: (val) => onChanged(EthereumTemplateData(
                address: val,
                amount: e.amount,
                chainId: e.chainId,
              )),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Amount (ETH)',
                    value: e.amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hint: '0.5',
                    onChanged: (val) => onChanged(EthereumTemplateData(
                      address: e.address,
                      amount: val,
                      chainId: e.chainId,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Chain ID',
                    value: e.chainId,
                    keyboardType: TextInputType.number,
                    hint: '1 (Mainnet)',
                    onChanged: (val) => onChanged(EthereumTemplateData(
                      address: e.address,
                      amount: e.amount,
                      chainId: val,
                    )),
                  ),
                ),
              ],
            ),
          ],
        );

      case QrTemplateType.email:
        final em = data as EmailTemplateData;
        return Column(
          children: [
            _buildTextField(
              label: 'To Email',
              value: em.to,
              focusNode: primaryFocusNode,
              keyboardType: TextInputType.emailAddress,
              onChanged: (val) => onChanged(EmailTemplateData(
                to: val,
                subject: em.subject,
                body: em.body,
              )),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Subject',
              value: em.subject,
              onChanged: (val) => onChanged(EmailTemplateData(
                to: em.to,
                subject: val,
                body: em.body,
              )),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Body',
              value: em.body,
              maxLines: 3,
              onChanged: (val) => onChanged(EmailTemplateData(
                to: em.to,
                subject: em.subject,
                body: val,
              )),
            ),
          ],
        );

      case QrTemplateType.phone:
        final p = data as PhoneTemplateData;
        return _buildTextField(
          label: 'Phone number',
          value: p.number,
          focusNode: primaryFocusNode,
          keyboardType: TextInputType.phone,
          onChanged: (val) => onChanged(PhoneTemplateData(number: val)),
        );

      case QrTemplateType.sms:
        final s = data as SmsTemplateData;
        return Column(
          children: [
            _buildTextField(
              label: 'Phone number',
              value: s.number,
              focusNode: primaryFocusNode,
              keyboardType: TextInputType.phone,
              onChanged: (val) => onChanged(SmsTemplateData(
                number: val,
                message: s.message,
              )),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Message',
              value: s.message,
              maxLines: 3,
              onChanged: (val) => onChanged(SmsTemplateData(
                number: s.number,
                message: val,
              )),
            ),
          ],
        );

      case QrTemplateType.geo:
        final g = data as GeoTemplateData;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Latitude',
                    value: g.latitude,
                    focusNode: primaryFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: (val) => onChanged(GeoTemplateData(
                      latitude: val,
                      longitude: g.longitude,
                      query: g.query,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Longitude',
                    value: g.longitude,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: (val) => onChanged(GeoTemplateData(
                      latitude: g.latitude,
                      longitude: val,
                      query: g.query,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Query / Label (optional)',
              value: g.query,
              onChanged: (val) => onChanged(GeoTemplateData(
                latitude: g.latitude,
                longitude: g.longitude,
                query: val,
              )),
            ),
          ],
        );
    }
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    FocusNode? focusNode,
    String? hint,
    int maxLines = 1,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return _ControlledTextField(
      label: label,
      value: value,
      onChanged: onChanged,
      focusNode: focusNode,
      hint: hint,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }
}

class _ControlledTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final String? hint;
  final int maxLines;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _ControlledTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.hint,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  State<_ControlledTextField> createState() => _ControlledTextFieldState();
}

class _ControlledTextFieldState extends State<_ControlledTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ControlledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      maxLines: widget.maxLines,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}
