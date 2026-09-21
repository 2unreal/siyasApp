import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/services/numbering_service.dart';
import '../../data/services/pdf_generator_service.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/payment_model.dart';
import 'auth_provider.dart';

final numberingServiceProvider = Provider<NumberingService>((ref) {
  return NumberingService();
});

final pdfGeneratorServiceProvider = Provider<PdfGeneratorService>((ref) {
  return const PdfGeneratorService();
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository();
});

final ownerDocumentsProvider = StreamProvider<List<DocumentRecord>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.streamDocuments();
});

final entityDocumentsProvider =
    StreamProvider.family<List<DocumentRecord>, String>((ref, entityId) {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.streamDocuments(entityId: entityId);
});

class GeneratedDocumentResult {
  final DocumentRecord record;
  final Uint8List pdfBytes;

  const GeneratedDocumentResult({required this.record, required this.pdfBytes});
}

class DocumentController extends StateNotifier<AsyncValue<GeneratedDocumentResult?>> {
  final DocumentRepository repo;
  final NumberingService numbering;
  final PdfGeneratorService pdfGen;
  final Ref ref;

  DocumentController({
    required this.repo,
    required this.numbering,
    required this.pdfGen,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  /// Generates and records an Invoice PDF. Strictly OWNER ONLY.
  Future<GeneratedDocumentResult> generateOrderInvoice({
    required Order order,
    Customer? customer,
    required double totalPaid,
    required double balanceAmount,
  }) async {
    final auth = ref.read(authProvider);
    if (!auth.isOwner) {
      throw Exception('Permission denied: Only the Business Owner can generate Invoices.');
    }

    state = const AsyncValue.loading();
    try {
      final docNumber = await numbering.consumeNextDocumentNumber(
        docType: DocumentType.invoice,
        isOnline: true,
      );

      final isPending = docNumber.startsWith('PENDING-');
      final docId = DateTime.now().millisecondsSinceEpoch.toString();

      final record = DocumentRecord(
        id: docId,
        documentType: DocumentType.invoice,
        documentNumber: docNumber,
        entityType: 'order',
        entityId: order.id,
        customerId: order.customerId,
        customerName: customer?.name,
        customerMobile: customer?.mobile,
        totalAmount: order.totalAmount,
        paidAmount: totalPaid,
        balanceAmount: balanceAmount,
        generatedBy: auth.uid ?? 'owner',
        generatedAt: DateTime.now(),
        isPendingSync: isPending,
      );

      final bytes = await pdfGen.generateOrderInvoicePdf(
        documentRecord: record,
        order: order,
        customer: customer,
        totalPaid: totalPaid,
        balanceAmount: balanceAmount,
      );

      // Save metadata to Firestore documents collection
      await repo.saveDocumentRecord(record);

      final result = GeneratedDocumentResult(record: record, pdfBytes: bytes);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Generates and records a Payment Receipt PDF. Strictly OWNER ONLY.
  Future<GeneratedDocumentResult> generatePaymentReceipt({
    required Payment payment,
    Customer? customer,
    required double orderTotal,
    required double resultingBalance,
    double creditAmount = 0.0,
  }) async {
    final auth = ref.read(authProvider);
    if (!auth.isOwner) {
      throw Exception('Permission denied: Only the Business Owner can generate Payment Receipts.');
    }

    state = const AsyncValue.loading();
    try {
      final docNumber = await numbering.consumeNextDocumentNumber(
        docType: DocumentType.paymentReceipt,
        isOnline: true,
      );

      final isPending = docNumber.startsWith('PENDING-');
      final docId = DateTime.now().millisecondsSinceEpoch.toString();

      final record = DocumentRecord(
        id: docId,
        documentType: DocumentType.paymentReceipt,
        documentNumber: docNumber,
        entityType: payment.entityType,
        entityId: payment.entityId,
        customerId: customer?.id ?? payment.customerId,
        customerName: customer?.name,
        customerMobile: customer?.mobile,
        totalAmount: orderTotal,
        paidAmount: payment.amount,
        balanceAmount: resultingBalance,
        generatedBy: auth.uid ?? 'owner',
        generatedAt: DateTime.now(),
        isPendingSync: isPending,
      );

      final bytes = await pdfGen.generatePaymentReceiptPdf(
        documentRecord: record,
        payment: payment,
        customer: customer,
        orderTotal: orderTotal,
        resultingBalance: resultingBalance,
        creditAmount: creditAmount,
      );

      await repo.saveDocumentRecord(record);

      final result = GeneratedDocumentResult(record: record, pdfBytes: bytes);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final documentControllerProvider =
    StateNotifierProvider<DocumentController, AsyncValue<GeneratedDocumentResult?>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  final numbering = ref.watch(numberingServiceProvider);
  final pdfGen = ref.watch(pdfGeneratorServiceProvider);
  return DocumentController(
    repo: repo,
    numbering: numbering,
    pdfGen: pdfGen,
    ref: ref,
  );
});
