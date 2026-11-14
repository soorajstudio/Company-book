import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';

class PdfService {
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static Future<Uint8List> generateCompanyReport({
    required String companyName,
    required DateTime fromDate,
    required DateTime toDate,
    required List<TransactionModel> transactions,
    String? soleMemberName,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.robotoRegular(),
        bold: await PdfGoogleFonts.robotoBold(),
        italic: await PdfGoogleFonts.robotoItalic(),
      ),
    );

    // Calculations
    double totalRevenue = 0;
    double totalExpense = 0;
    final Map<String, double> categoryTotals = {};

    for (final t in transactions) {
      if (t.isIncome) {
        totalRevenue += t.amount;
      } else {
        totalExpense += t.amount;
        final cat = t.displayCategory;
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
      }
    }
    final netProfit = totalRevenue - totalExpense;

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedTxns = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(companyName, fromDate, toDate, soleMemberName),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          _summarySection(totalRevenue, totalExpense, netProfit),
          pw.SizedBox(height: 20),
          if (sortedCategories.isNotEmpty) ...[
            _categorySection(sortedCategories, totalExpense),
            pw.SizedBox(height: 20),
          ],
          _transactionsSection(sortedTxns),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    String companyName,
    DateTime fromDate,
    DateTime toDate,
    String? soleMemberName,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.indigo900, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'COMPANY BOOK',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                companyName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              if (soleMemberName != null && soleMemberName.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Sole Controller: $soleMemberName',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'FINANCIAL STATEMENT',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '${_dateFormat.format(fromDate)} – ${_dateFormat.format(toDate)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _summarySection(
      double revenue, double expense, double netProfit) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _statBox('TOTAL REVENUE', _currency.format(revenue), PdfColors.green800),
          _divider(),
          _statBox('TOTAL EXPENSES', _currency.format(expense), PdfColors.red800),
          _divider(),
          _statBox(
            netProfit >= 0 ? 'NET PROFIT' : 'NET LOSS',
            _currency.format(netProfit),
            netProfit >= 0 ? PdfColors.green900 : PdfColors.red900,
          ),
        ],
      ),
    );
  }

  static pw.Widget _divider() {
    return pw.Container(height: 36, width: 1, color: PdfColors.grey300);
  }

  static pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _categorySection(
      List<MapEntry<String, double>> categories, double totalExpense) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Breakdown by Category',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(1),
          },
          border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Category', bold: true),
                _tableCell('Amount', bold: true, align: pw.TextAlign.right),
                _tableCell('Share %', bold: true, align: pw.TextAlign.right),
              ],
            ),
            ...categories.map((entry) {
              final pct = totalExpense > 0
                  ? (entry.value / totalExpense * 100).toStringAsFixed(1)
                  : '0.0';
              return pw.TableRow(
                children: [
                  _tableCell(entry.key),
                  _tableCell(_currency.format(entry.value),
                      align: pw.TextAlign.right),
                  _tableCell('$pct%', align: pw.TextAlign.right),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _transactionsSection(List<TransactionModel> txns) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Company Entries Ledger (${txns.length})',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (txns.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text('No entries recorded in this period.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          )
        else
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.4),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(3.0),
              3: pw.FlexColumnWidth(1.8),
            },
            border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableCell('Date', bold: true),
                  _tableCell('Category', bold: true),
                  _tableCell('Description / Ref', bold: true),
                  _tableCell('Amount', bold: true, align: pw.TextAlign.right),
                ],
              ),
              ...txns.map((t) {
                final isInc = t.isIncome;
                final sign = isInc ? '+' : '-';
                return pw.TableRow(
                  children: [
                    _tableCell(_dateFormat.format(t.date)),
                    _tableCell(t.displayCategory),
                    _tableCell(t.description?.isNotEmpty == true
                        ? t.description!
                        : '-'),
                    _tableCell(
                      '$sign ${_currency.format(t.amount)}',
                      align: pw.TextAlign.right,
                      color: isInc ? PdfColors.green800 : PdfColors.red800,
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.grey900,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Company Book Ledger • Single Member Exclusive Entry',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
