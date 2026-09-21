import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/models/customer_model.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/payment_model.dart';

class PdfGeneratorService {
  final DocumentBrandingConfig branding;

  const PdfGeneratorService({
    this.branding = const DocumentBrandingConfig(),
  });

  /// Generates a professional Order Invoice PDF on device.
  Future<Uint8List> generateOrderInvoicePdf({
    required DocumentRecord documentRecord,
    required Order order,
    Customer? customer,
    double totalPaid = 0.0,
    double balanceAmount = 0.0,
  }) async {
    final pdf = pw.Document();

    final wineColor = PdfColor.fromInt(branding.primaryColorHex);
    final goldColor = PdfColor.fromInt(branding.accentColorHex);
    const ivoryColor = PdfColor(1.0, 0.99, 0.97);
    const darkTextColor = PdfColor(0.13, 0.13, 0.13);
    const greyTextColor = PdfColors.grey600;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(wineColor, goldColor, darkTextColor, greyTextColor),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1.5, color: goldColor),
              pw.SizedBox(height: 12),

              // Title and Meta
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TAX INVOICE / BILL',
                        style: pw.TextStyle(
                          color: wineColor,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (documentRecord.isPendingSync) ...[
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: goldColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'OFFLINE PENDING SYNC',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #: ${documentRecord.documentNumber}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: darkTextColor)),
                      pw.SizedBox(height: 2),
                      pw.Text('Date: ${_formatDate(documentRecord.generatedAt)}',
                          style: pw.TextStyle(color: greyTextColor, fontSize: 11)),
                      pw.Text('Order Ref: ${order.orderNumber}',
                          style: pw.TextStyle(color: greyTextColor, fontSize: 11)),
                      pw.Text('Due Delivery: ${_formatDate(order.deliveryDate)}',
                          style: pw.TextStyle(color: wineColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Customer Details Box
              _buildCustomerBox(customer, documentRecord, wineColor, ivoryColor, darkTextColor, greyTextColor),
              pw.SizedBox(height: 20),

              // Order Line Items Table
              _buildLineItemsTable(order.items, wineColor, ivoryColor, darkTextColor),
              pw.SizedBox(height: 16),

              // Summary Calculations Block
              _buildFinancialSummary(
                subtotal: order.subtotal,
                discount: order.discount,
                totalAmount: order.totalAmount,
                totalPaid: totalPaid,
                balanceAmount: balanceAmount,
                wineColor: wineColor,
                goldColor: goldColor,
                darkTextColor: darkTextColor,
              ),
              pw.Spacer(),

              // Terms & Conditions + Footer
              _buildFooter(wineColor, goldColor, greyTextColor),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates an official Payment Receipt PDF on device.
  Future<Uint8List> generatePaymentReceiptPdf({
    required DocumentRecord documentRecord,
    required Payment payment,
    Customer? customer,
    required double orderTotal,
    required double resultingBalance,
    double creditAmount = 0.0,
  }) async {
    final pdf = pw.Document();

    final wineColor = PdfColor.fromInt(branding.primaryColorHex);
    final goldColor = PdfColor.fromInt(branding.accentColorHex);
    const ivoryColor = PdfColor(1.0, 0.99, 0.97);
    const darkTextColor = PdfColor(0.13, 0.13, 0.13);
    const greyTextColor = PdfColors.grey600;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(wineColor, goldColor, darkTextColor, greyTextColor),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1.5, color: goldColor),
              pw.SizedBox(height: 12),

              // Title and Meta
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'OFFICIAL PAYMENT RECEIPT',
                        style: pw.TextStyle(
                          color: wineColor,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (documentRecord.isPendingSync) ...[
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: goldColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'OFFLINE PENDING SYNC',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Receipt #: ${documentRecord.documentNumber}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: darkTextColor)),
                      pw.SizedBox(height: 2),
                      pw.Text('Date: ${_formatDate(payment.paymentDate)}',
                          style: const pw.TextStyle(color: greyTextColor, fontSize: 11)),
                      pw.Text('Payment Mode: ${payment.method.toUpperCase()}',
                          style: pw.TextStyle(color: wineColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Customer Details Box
              _buildCustomerBox(customer, documentRecord, wineColor, ivoryColor, darkTextColor, greyTextColor),
              pw.SizedBox(height: 24),

              // Payment Details Card
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Amount Received:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          'Rs. ${payment.amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800,
                          ),
                        ),
                      ],
                    ),
                    pw.Divider(color: PdfColors.grey200, height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Payment For:', style: pw.TextStyle(fontSize: 12, color: greyTextColor)),
                        pw.Text('${payment.entityType.toUpperCase()} - ${payment.entityId}',
                            style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Remarks / Transaction Ref:', style: pw.TextStyle(fontSize: 12, color: greyTextColor)),
                          pw.Text(payment.notes!, style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                    pw.Divider(color: PdfColors.grey200, height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Order Total Amount:', style: pw.TextStyle(fontSize: 12, color: greyTextColor)),
                        pw.Text('Rs. ${orderTotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Remaining Balance:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          'Rs. ${resultingBalance.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: resultingBalance > 0 ? wineColor : PdfColors.green800,
                          ),
                        ),
                      ],
                    ),
                    if (creditAmount > 0) ...[
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Overpayment Credit Available:',
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: goldColor)),
                          pw.Text('Rs. ${creditAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: goldColor)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              pw.Spacer(),

              // Terms & Signature
              _buildFooter(wineColor, goldColor, greyTextColor),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    PdfColor wineColor,
    PdfColor goldColor,
    PdfColor darkTextColor,
    PdfColor greyTextColor,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          children: [
            // Monogram Badge
            pw.Container(
              width: 48,
              height: 48,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: wineColor,
                border: pw.Border.all(color: goldColor, width: 2),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'HS',
                style: pw.TextStyle(color: goldColor, fontWeight: pw.FontWeight.bold, fontSize: 18),
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  branding.businessName.toUpperCase(),
                  style: pw.TextStyle(
                    color: wineColor,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Bridal Studio | Designer Blouses | Couture & Draping',
                  style: pw.TextStyle(color: goldColor, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(branding.fullAddress, style: pw.TextStyle(color: greyTextColor, fontSize: 8.5)),
            pw.Text('Phone: ${branding.phone} | WhatsApp: ${branding.whatsapp}',
                style: pw.TextStyle(color: greyTextColor, fontSize: 8.5)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerBox(
    Customer? customer,
    DocumentRecord doc,
    PdfColor wineColor,
    PdfColor ivoryColor,
    PdfColor darkTextColor,
    PdfColor greyTextColor,
  ) {
    final name = customer?.name ?? doc.customerName ?? 'Valued Customer';
    final mobile = customer?.mobile ?? doc.customerMobile ?? 'N/A';
    final address = customer?.address ?? 'Store Client';

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: ivoryColor,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BILL TO / CUSTOMER:', style: pw.TextStyle(color: wineColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(name, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: darkTextColor)),
              pw.Text('Mobile: $mobile', style: pw.TextStyle(color: greyTextColor, fontSize: 11)),
              pw.Text('Address: $address', style: pw.TextStyle(color: greyTextColor, fontSize: 10)),
            ],
          ),
          if (customer != null)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Customer ID:', style: pw.TextStyle(color: greyTextColor, fontSize: 10)),
                pw.Text(customer.customerId, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: wineColor)),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildLineItemsTable(
    List<OrderItem> items,
    PdfColor wineColor,
    PdfColor ivoryColor,
    PdfColor darkTextColor,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: wineColor),
          children: [
            _tableHeaderCell('#', PdfColors.white, align: pw.TextAlign.center),
            _tableHeaderCell('Item & Service Description', PdfColors.white),
            _tableHeaderCell('Rate (Rs.)', PdfColors.white, align: pw.TextAlign.right),
            _tableHeaderCell('Qty', PdfColors.white, align: pw.TextAlign.center),
            _tableHeaderCell('Amount (Rs.)', PdfColors.white, align: pw.TextAlign.right),
          ],
        ),
        // Table Rows
        ...items.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final item = entry.value;
          final isEven = idx % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? ivoryColor : PdfColors.white),
            children: [
              _tableCell('$idx', align: pw.TextAlign.center),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.serviceName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    if (item.description.isNotEmpty)
                      pw.Text(item.description, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9)),
                  ],
                ),
              ),
              _tableCell(item.unitRate.toStringAsFixed(0), align: pw.TextAlign.right),
              _tableCell('${item.quantity}', align: pw.TextAlign.center),
              _tableCell(item.lineTotal.toStringAsFixed(0), align: pw.TextAlign.right, isBold: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildFinancialSummary({
    required double subtotal,
    required double discount,
    required double totalAmount,
    required double totalPaid,
    required double balanceAmount,
    required PdfColor wineColor,
    required PdfColor goldColor,
    required PdfColor darkTextColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 220,
          child: pw.Column(
            children: [
              _summaryRow('Subtotal:', 'Rs. ${subtotal.toStringAsFixed(2)}'),
              if (discount > 0) _summaryRow('Discount:', '-Rs. ${discount.toStringAsFixed(2)}', valueColor: PdfColors.green800),
              pw.Divider(color: PdfColors.grey300, height: 12),
              _summaryRow('Net Total Amount:', 'Rs. ${totalAmount.toStringAsFixed(2)}', isBold: true, valueColor: wineColor, fontSize: 13),
              pw.SizedBox(height: 4),
              _summaryRow('Total Paid / Advance:', 'Rs. ${totalPaid.toStringAsFixed(2)}', valueColor: PdfColors.green800),
              pw.SizedBox(height: 4),
              _summaryRow('Balance Due:', 'Rs. ${balanceAmount.toStringAsFixed(2)}',
                  isBold: true, valueColor: balanceAmount > 0 ? wineColor : PdfColors.green800, fontSize: 13),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? valueColor,
    double fontSize = 10.5,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valueColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(PdfColor wineColor, PdfColor goldColor, PdfColor greyTextColor) {
    return pw.Column(
      children: [
        pw.Divider(color: goldColor, thickness: 1),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: wineColor)),
                  pw.SizedBox(height: 2),
                  pw.Text(branding.termsAndConditions, style: pw.TextStyle(color: greyTextColor, fontSize: 7.5)),
                  pw.SizedBox(height: 6),
                  pw.Text(branding.thankYouNote, style: pw.TextStyle(color: wineColor, fontSize: 9, fontStyle: pw.FontStyle.italic)),
                ],
              ),
            ),
            pw.SizedBox(width: 24),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(width: 120, height: 40),
                pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 4),
                pw.Text('Authorized Signatory', style: pw.TextStyle(color: greyTextColor, fontSize: 8.5)),
                pw.Text('House of SIYA\'s', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: wineColor)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableHeaderCell(String text, PdfColor textColor, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(color: textColor, fontWeight: pw.FontWeight.bold, fontSize: 9.5),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 9.5, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
