import 'package:flutter/material.dart' show BuildContext;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'constants.dart';
import 'order_services.dart';

/// Locale-specific labels for the invoice PDF.
class _InvoiceLabels {
  final String title;
  final String numberPrefix;
  final String seller;
  final String buyer;
  final String issueDate;
  final String serviceDate;
  final String description;
  final String qty;
  final String netPrice;
  final String vatPct;
  final String vatAmount;
  final String grossPrice;
  final String netTotal;
  final String vatLine;
  final String totalDue;
  final String fillCompany;
  final String issuedBy;
  final String primaryIdLabel;
  final String secondaryIdLabel;

  const _InvoiceLabels({
    required this.title,
    required this.numberPrefix,
    required this.seller,
    required this.buyer,
    required this.issueDate,
    required this.serviceDate,
    required this.description,
    required this.qty,
    required this.netPrice,
    required this.vatPct,
    required this.vatAmount,
    required this.grossPrice,
    required this.netTotal,
    required this.vatLine,
    required this.totalDue,
    required this.fillCompany,
    required this.issuedBy,
    required this.primaryIdLabel,
    required this.secondaryIdLabel,
  });

  factory _InvoiceLabels.forLocale(String locale, double vatRate) {
    final vatStr = '${vatRate.toStringAsFixed(0)}%';
    switch (locale) {
      case 'pl':
        return _InvoiceLabels(
          title: 'FAKTURA VAT',
          numberPrefix: 'FV',
          seller: 'SPRZEDAWCA',
          buyer: 'NABYWCA',
          issueDate: 'Data wystawienia',
          serviceDate: 'Data sprzedazy',
          description: 'Nazwa uslugi / towaru',
          qty: 'Ilosc',
          netPrice: 'Cena netto',
          vatPct: 'VAT %',
          vatAmount: 'Kwota VAT',
          grossPrice: 'Cena brutto',
          netTotal: 'Razem netto:',
          vatLine: 'VAT $vatStr:',
          totalDue: 'DO ZAPLATY:',
          fillCompany: 'Uzupelnij dane firmy',
          issuedBy: 'Faktura wystawiona przez',
          primaryIdLabel: 'NIP',
          secondaryIdLabel: 'REGON',
        );
      case 'de':
        return _InvoiceLabels(
          title: 'RECHNUNG',
          numberPrefix: 'RE',
          seller: 'VERKÄUFER',
          buyer: 'KÄUFER',
          issueDate: 'Ausstellungsdatum',
          serviceDate: 'Leistungsdatum',
          description: 'Beschreibung',
          qty: 'Menge',
          netPrice: 'Nettopreis',
          vatPct: 'MwSt. %',
          vatAmount: 'MwSt. Betrag',
          grossPrice: 'Bruttopreis',
          netTotal: 'Netto gesamt:',
          vatLine: 'MwSt. $vatStr:',
          totalDue: 'GESAMT:',
          fillCompany: 'Firmendaten ausfüllen',
          issuedBy: 'Rechnung ausgestellt von',
          primaryIdLabel: 'USt-IdNr.',
          secondaryIdLabel: 'Handelsregisternr.',
        );
      case 'it':
        return _InvoiceLabels(
          title: 'FATTURA',
          numberPrefix: 'FT',
          seller: 'VENDITORE',
          buyer: 'ACQUIRENTE',
          issueDate: 'Data di emissione',
          serviceDate: 'Data del servizio',
          description: 'Descrizione',
          qty: 'Qtà',
          netPrice: 'Prezzo netto',
          vatPct: 'IVA %',
          vatAmount: 'Importo IVA',
          grossPrice: 'Prezzo lordo',
          netTotal: 'Totale netto:',
          vatLine: 'IVA $vatStr:',
          totalDue: 'DA PAGARE:',
          fillCompany: 'Compilare i dati aziendali',
          issuedBy: 'Fattura emessa da',
          primaryIdLabel: 'Partita IVA',
          secondaryIdLabel: 'Codice fiscale',
        );
      case 'es':
        return _InvoiceLabels(
          title: 'FACTURA',
          numberPrefix: 'FC',
          seller: 'VENDEDOR',
          buyer: 'COMPRADOR',
          issueDate: 'Fecha de emisión',
          serviceDate: 'Fecha del servicio',
          description: 'Descripción',
          qty: 'Cant.',
          netPrice: 'Precio neto',
          vatPct: 'IVA %',
          vatAmount: 'Importe IVA',
          grossPrice: 'Precio bruto',
          netTotal: 'Total neto:',
          vatLine: 'IVA $vatStr:',
          totalDue: 'TOTAL A PAGAR:',
          fillCompany: 'Completar datos de empresa',
          issuedBy: 'Factura emitida por',
          primaryIdLabel: 'NIF/CIF',
          secondaryIdLabel: 'Registro mercantil',
        );
      case 'pt':
        return _InvoiceLabels(
          title: 'FATURA',
          numberPrefix: 'FT',
          seller: 'VENDEDOR',
          buyer: 'COMPRADOR',
          issueDate: 'Data de emissão',
          serviceDate: 'Data do serviço',
          description: 'Descrição',
          qty: 'Qtd.',
          netPrice: 'Preço líquido',
          vatPct: 'IVA %',
          vatAmount: 'Valor IVA',
          grossPrice: 'Preço bruto',
          netTotal: 'Total líquido:',
          vatLine: 'IVA $vatStr:',
          totalDue: 'A PAGAR:',
          fillCompany: 'Preencher dados da empresa',
          issuedBy: 'Fatura emitida por',
          primaryIdLabel: 'NIF',
          secondaryIdLabel: 'Registo comercial',
        );
      case 'tr':
        return _InvoiceLabels(
          title: 'FATURA',
          numberPrefix: 'FT',
          seller: 'SATICI',
          buyer: 'ALICI',
          issueDate: 'Düzenleme tarihi',
          serviceDate: 'Hizmet tarihi',
          description: 'Açıklama',
          qty: 'Adet',
          netPrice: 'Net fiyat',
          vatPct: 'KDV %',
          vatAmount: 'KDV tutarı',
          grossPrice: 'Brüt fiyat',
          netTotal: 'Net toplam:',
          vatLine: 'KDV $vatStr:',
          totalDue: 'ÖDENECEK:',
          fillCompany: 'Şirket bilgilerini doldurun',
          issuedBy: 'Tarafından düzenlendi',
          primaryIdLabel: 'Vergi No',
          secondaryIdLabel: 'Şirket sicil no',
        );
      case 'zh':
        return _InvoiceLabels(
          title: '发票',
          numberPrefix: 'INV',
          seller: '销售方',
          buyer: '买方',
          issueDate: '开票日期',
          serviceDate: '服务日期',
          description: '项目描述',
          qty: '数量',
          netPrice: '净价',
          vatPct: '税率%',
          vatAmount: '税额',
          grossPrice: '含税价',
          netTotal: '净额合计:',
          vatLine: '税额 $vatStr:',
          totalDue: '应付总额:',
          fillCompany: '请填写公司信息',
          issuedBy: '开票方',
          primaryIdLabel: '税号',
          secondaryIdLabel: '工商注册号',
        );
      case 'ru':
        return _InvoiceLabels(
          title: 'СЧЁТ-ФАКТУРА',
          numberPrefix: 'СФ',
          seller: 'ПРОДАВЕЦ',
          buyer: 'ПОКУПАТЕЛЬ',
          issueDate: 'Дата выставления',
          serviceDate: 'Дата услуги',
          description: 'Наименование услуги',
          qty: 'Кол-во',
          netPrice: 'Цена без НДС',
          vatPct: 'НДС %',
          vatAmount: 'Сумма НДС',
          grossPrice: 'Цена с НДС',
          netTotal: 'Итого без НДС:',
          vatLine: 'НДС $vatStr:',
          totalDue: 'К ОПЛАТЕ:',
          fillCompany: 'Заполните данные компании',
          issuedBy: 'Счёт выставлен',
          primaryIdLabel: 'ИНН',
          secondaryIdLabel: 'ОГРН',
        );
      // en + fallback
      default:
        return _InvoiceLabels(
          title: 'INVOICE',
          numberPrefix: 'INV',
          seller: 'SELLER',
          buyer: 'BUYER',
          issueDate: 'Issue date',
          serviceDate: 'Service date',
          description: 'Description',
          qty: 'Qty',
          netPrice: 'Net price',
          vatPct: 'VAT %',
          vatAmount: 'VAT amount',
          grossPrice: 'Gross price',
          netTotal: 'Net total:',
          vatLine: 'VAT $vatStr:',
          totalDue: 'TOTAL DUE:',
          fillCompany: 'Fill in company data',
          issuedBy: 'Invoice issued by',
          primaryIdLabel: 'Tax ID',
          secondaryIdLabel: 'Business ID',
        );
    }
  }
}

/// Generates and prints a VAT invoice for an order in the app's current language.
class InvoiceService {
  /// Returns next invoice number and increments the counter.
  static String _nextInvoiceNumber(Box settingsBox, String prefix) {
    final year = DateTime.now().year;
    final key = 'invoiceCounter_$year';
    final current = (settingsBox.get(key) as int?) ?? 0;
    final next = current + 1;
    settingsBox.put(key, next);
    return '$prefix/$year/${next.toString().padLeft(3, '0')}';
  }

  static Future<void> generateAndPrint({
    required BuildContext context,
    required Map orderData,
    required String currency,
  }) async {
    final settingsBox = Hive.box(HiveBoxes.settings);

    // Locale & VAT rate
    final locale =
        settingsBox.get('locale', defaultValue: 'en')?.toString() ?? 'en';
    final vatRate =
        (settingsBox.get('companyVatRate') as num?)?.toDouble() ?? 23.0;
    final labels = _InvoiceLabels.forLocale(locale, vatRate);

    // Company data
    final companyName =
        settingsBox.get('companyName', defaultValue: '')?.toString() ?? '';
    final companyNip =
        settingsBox.get('companyNip', defaultValue: '')?.toString() ?? '';
    final companyRegon =
        settingsBox.get('companyRegon', defaultValue: '')?.toString() ?? '';
    final companyAddress =
        settingsBox.get('companyAddress', defaultValue: '')?.toString() ?? '';
    final companyCity =
        settingsBox.get('companyCity', defaultValue: '')?.toString() ?? '';
    final companyPostalCode =
        settingsBox.get('companyPostalCode', defaultValue: '')?.toString() ??
        '';

    // Order data
    final clientName = orderData['client']?.toString() ?? '-';
    final serviceItems = orderServiceList(orderData);
    final serviceName = serviceItems.isEmpty
        ? '-'
        : (serviceItems.length == 1
              ? serviceItems.first
              : serviceItems.map((item) => '• $item').join('\n'));
    final grossPrice = (orderData['price'] as num?)?.toDouble() ?? 0.0;
    final netPrice = grossPrice / (1 + vatRate / 100);
    final vatAmount = grossPrice - netPrice;

    final invoiceNumber = _nextInvoiceNumber(settingsBox, labels.numberPrefix);
    final issueDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
    final serviceDate = _formatOrderDate(orderData);

    // Noto Sans supports all the locales (Latin, Cyrillic, Chinese, Arabic-adjacent)
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    labels.title,
                    style: pw.TextStyle(font: fontBold, fontSize: 22),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        invoiceNumber,
                        style: pw.TextStyle(font: fontBold, fontSize: 14),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${labels.issueDate}: $issueDate',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                      pw.Text(
                        '${labels.serviceDate}: $serviceDate',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // ── Seller / Buyer ───────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _partyBox(
                      title: labels.seller,
                      name: companyName.isEmpty
                          ? labels.fillCompany
                          : companyName,
                      lines: [
                        if (companyAddress.isNotEmpty) companyAddress,
                        if (companyPostalCode.isNotEmpty ||
                            companyCity.isNotEmpty)
                          '$companyPostalCode $companyCity'.trim(),
                        if (companyNip.isNotEmpty)
                          '${labels.primaryIdLabel}: $companyNip',
                        if (companyRegon.isNotEmpty)
                          '${labels.secondaryIdLabel}: $companyRegon',
                      ],
                      fontBold: fontBold,
                      fontRegular: fontRegular,
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: _partyBox(
                      title: labels.buyer,
                      name: clientName,
                      lines: const [],
                      fontBold: fontBold,
                      fontRegular: fontRegular,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 28),

              // ── Items table ──────────────────────────────
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FixedColumnWidth(30),
                  2: const pw.FixedColumnWidth(70),
                  3: const pw.FixedColumnWidth(35),
                  4: const pw.FixedColumnWidth(60),
                  5: const pw.FixedColumnWidth(70),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _cell(labels.description, fontBold, isHeader: true),
                      _cell(labels.qty, fontBold, isHeader: true),
                      _cell(labels.netPrice, fontBold, isHeader: true),
                      _cell(labels.vatPct, fontBold, isHeader: true),
                      _cell(labels.vatAmount, fontBold, isHeader: true),
                      _cell(labels.grossPrice, fontBold, isHeader: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _cell(serviceName, fontRegular),
                      _cell('1', fontRegular),
                      _cell('${_fmt(netPrice)} $currency', fontRegular),
                      _cell('${vatRate.toStringAsFixed(0)}%', fontRegular),
                      _cell('${_fmt(vatAmount)} $currency', fontRegular),
                      _cell('${_fmt(grossPrice)} $currency', fontRegular),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── Totals ───────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 240,
                  child: pw.Column(
                    children: [
                      _totalRow(
                        labels.netTotal,
                        '${_fmt(netPrice)} $currency',
                        fontRegular,
                        fontBold,
                      ),
                      _totalRow(
                        labels.vatLine,
                        '${_fmt(vatAmount)} $currency',
                        fontRegular,
                        fontBold,
                      ),
                      pw.SizedBox(height: 4),
                      _totalRow(
                        labels.totalDue,
                        '${_fmt(grossPrice)} $currency',
                        fontBold,
                        fontBold,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),

              // ── Footer ───────────────────────────────────
              pw.Divider(color: PdfColors.grey400),
              pw.Text(
                '${labels.issuedBy}: $companyName',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: '$invoiceNumber.pdf',
    );
  }

  static pw.Widget _partyBox({
    required String title,
    required String name,
    required List<String> lines,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(name, style: pw.TextStyle(font: fontBold, fontSize: 11)),
          ...lines.map(
            (l) => pw.Text(
              l,
              style: pw.TextStyle(font: fontRegular, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: isHeader ? 9 : 10),
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value,
    pw.Font labelFont,
    pw.Font valueFont, {
    bool isTotal = false,
  }) {
    return pw.Container(
      decoration: isTotal
          ? const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            )
          : null,
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: labelFont, fontSize: isTotal ? 11 : 10),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: valueFont, fontSize: isTotal ? 11 : 10),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) => v.toStringAsFixed(2);

  static String _formatOrderDate(Map orderData) {
    final date = orderData['scheduledDate'];
    if (date is num) {
      final d = DateTime.fromMillisecondsSinceEpoch(date.toInt());
      return DateFormat('dd.MM.yyyy').format(d);
    }
    return DateFormat('dd.MM.yyyy').format(DateTime.now());
  }
}
