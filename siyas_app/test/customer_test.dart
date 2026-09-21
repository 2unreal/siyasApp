import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/core/config/app_environment.dart';
import 'package:siyas_app/data/repositories/customer_repository.dart';
import 'package:siyas_app/domain/models/customer_model.dart';
import 'package:siyas_app/domain/models/user_model.dart';
import 'package:siyas_app/presentation/providers/auth_provider.dart';
import 'package:siyas_app/presentation/providers/customer_provider.dart';
import 'package:siyas_app/presentation/screens/customers/customer_detail_screen.dart';
import 'package:siyas_app/presentation/screens/customers/customer_form_screen.dart';
import 'package:siyas_app/presentation/screens/customers/customer_list_screen.dart';

class MockCustomerRepository implements CustomerRepository {
  final List<Customer> _customers = [];
  final Map<String, List<CustomerNote>> _notes = {};
  final _customerStreamController = StreamController<List<Customer>>.broadcast();

  @override
  String get businessId => 'house_of_siyas';

  @override
  Stream<List<Customer>> streamCustomers({required String status}) {
    return _customerStreamController.stream.map(
      (list) => list.where((c) => c.status == status).toList(),
    );
  }

  @override
  Stream<Customer?> streamCustomer(String id) {
    return _customerStreamController.stream.map(
      (list) => list.cast<Customer?>().firstWhere((c) => c?.id == id, orElse: () => null),
    );
  }

  @override
  Future<List<Customer>> findCustomersByMobile(String mobile) async {
    return _customers.where((c) => c.mobile == mobile && c.status == 'active').toList();
  }

  @override
  Future<String> generateNextCustomerId() async {
    final count = _customers.length + 1;
    return 'CUS-${count.toString().padLeft(4, '0')}';
  }

  @override
  Future<void> createCustomer(Customer customer) async {
    _customers.add(customer);
    _customerStreamController.add(List.from(_customers));
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      _customers[idx] = customer;
      _customerStreamController.add(List.from(_customers));
    }
  }

  @override
  Future<void> archiveCustomer(String id, String userId) async {
    final idx = _customers.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final old = _customers[idx];
      _customers[idx] = Customer(
        id: old.id,
        customerId: old.customerId,
        name: old.name,
        mobile: old.mobile,
        whatsappMobile: old.whatsappMobile,
        whatsappSameAsMobile: old.whatsappSameAsMobile,
        address: old.address,
        generalNote: old.generalNote,
        photoUrl: old.photoUrl,
        status: 'archived',
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
        createdBy: old.createdBy,
        updatedBy: userId,
      );
      _customerStreamController.add(List.from(_customers));
    }
  }

  @override
  Future<void> restoreCustomer(String id, String userId) async {
    final idx = _customers.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final old = _customers[idx];
      _customers[idx] = Customer(
        id: old.id,
        customerId: old.customerId,
        name: old.name,
        mobile: old.mobile,
        whatsappMobile: old.whatsappMobile,
        whatsappSameAsMobile: old.whatsappSameAsMobile,
        address: old.address,
        generalNote: old.generalNote,
        photoUrl: old.photoUrl,
        status: 'active',
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
        createdBy: old.createdBy,
        updatedBy: userId,
      );
      _customerStreamController.add(List.from(_customers));
    }
  }

  @override
  Stream<List<CustomerNote>> streamNotesHistory(String customerId) {
    return Stream.value(_notes[customerId] ?? []);
  }

  @override
  Future<void> addCustomerNote({
    required String customerId,
    required String note,
    required String authorId,
    required String authorName,
  }) async {
    _notes.putIfAbsent(customerId, () => []);
    _notes[customerId]!.add(CustomerNote(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      note: note,
      createdAt: DateTime.now(),
      authorId: authorId,
      authorName: authorName,
    ));
  }
}

void main() {
  setUp(() {
    AppConfig.initialize(AppEnvironment.dev);
  });

  group('Milestone 4 — Customer Data & Repository Logic', () {
    late MockCustomerRepository repo;

    setUp(() {
      repo = MockCustomerRepository();
    });

    test('Sequential Customer ID generation format (CUS-0001)', () async {
      final id1 = await repo.generateNextCustomerId();
      expect(id1, 'CUS-0001');

      await repo.createCustomer(Customer(
        id: '1',
        customerId: id1,
        name: 'Lakshmi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
        updatedBy: 'u1',
      ));

      final id2 = await repo.generateNextCustomerId();
      expect(id2, 'CUS-0002');
    });

    test('Duplicate mobile detection allows non-unique mobile records', () async {
      final customer1 = Customer(
        id: 'c1',
        customerId: 'CUS-0001',
        name: 'Kavitha S',
        mobile: '9876543210',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
        updatedBy: 'u1',
      );
      await repo.createCustomer(customer1);

      // Check duplicate mobile
      final duplicates = await repo.findCustomersByMobile('9876543210');
      expect(duplicates.length, 1);
      expect(duplicates.first.name, 'Kavitha S');

      // Creation of duplicate is permitted (mobile is not globally unique)
      final customer2 = Customer(
        id: 'c2',
        customerId: 'CUS-0002',
        name: 'Kavitha Sister',
        mobile: '9876543210',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
        updatedBy: 'u1',
      );
      await repo.createCustomer(customer2);

      final duplicatesAfter = await repo.findCustomersByMobile('9876543210');
      expect(duplicatesAfter.length, 2);
    });

    test('Archive and Restore updates customer status without permanent deletion', () async {
      final customer = Customer(
        id: 'c1',
        customerId: 'CUS-0001',
        name: 'Pooja',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
        updatedBy: 'u1',
      );
      await repo.createCustomer(customer);

      // Archive customer
      await repo.archiveCustomer('c1', 'owner_1');
      expect(repo._customers.first.status, 'archived');
      expect(repo._customers.first.isArchived, isTrue);

      // Restore customer
      await repo.restoreCustomer('c1', 'owner_1');
      expect(repo._customers.first.status, 'active');
      expect(repo._customers.first.isArchived, isFalse);
    });

    test('Customer notes history maintains dated entries and author', () async {
      await repo.addCustomerNote(
        customerId: 'c1',
        note: 'Prefers boat neck with elbow sleeves',
        authorId: 'u1',
        authorName: 'Owner',
      );

      final notesStream = repo.streamNotesHistory('c1');
      final notes = await notesStream.first;
      expect(notes.length, 1);
      expect(notes.first.note, 'Prefers boat neck with elbow sleeves');
      expect(notes.first.authorName, 'Owner');
    });
  });

  group('Milestone 4 — Customer UI, Forms & RBAC Tests', () {
    late MockCustomerRepository mockRepo;

    setUp(() {
      mockRepo = MockCustomerRepository();
    });

    testWidgets('CustomerFormScreen validates mandatory name', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CustomerFormScreen(),
          ),
        ),
      );

      // Attempt submit with empty fields
      await tester.tap(find.text('Create Customer'));
      await tester.pump();

      expect(find.text('Customer name is mandatory'), findsOneWidget);
    });

    testWidgets('CustomerFormScreen warns on duplicate mobile and allows intentional override', (WidgetTester tester) async {
      await mockRepo.createCustomer(Customer(
        id: 'c1',
        customerId: 'CUS-0001',
        name: 'Anitha',
        mobile: '9840123456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
        updatedBy: 'u1',
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CustomerFormScreen(),
          ),
        ),
      );

      // Enter name and duplicate phone number
      await tester.enterText(find.byType(TextFormField).at(0), 'Anitha Sister');
      await tester.enterText(find.byType(TextFormField).at(1), '9840123456');

      await tester.tap(find.text('Create Customer'));
      await tester.pumpAndSettle();

      // Duplicate warning dialog should appear
      expect(find.text('Existing Customer Found'), findsOneWidget);
      expect(find.text('Create Duplicate Anyway'), findsOneWidget);

      // Tap override
      await tester.tap(find.text('Create Duplicate Anyway'));
      await tester.pumpAndSettle();

      // Verify second customer is created with same phone
      expect(mockRepo._customers.length, 2);
      expect(mockRepo._customers.last.name, 'Anitha Sister');
      expect(mockRepo._customers.last.mobile, '9840123456');
    });

    testWidgets('CustomerListScreen hides Archived tab from Managers', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerRepositoryProvider.overrideWithValue(mockRepo),
            filteredCustomersProvider.overrideWith((ref) => Stream.value([])),
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setRole(UserRole.manager);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: CustomerListScreen(),
          ),
        ),
      );
      await tester.pump();

      // Manager should not see the SegmentedButton with Archived
      expect(find.text('Archived'), findsNothing);
      expect(find.text('Active Customers'), findsNothing);
    });

    testWidgets('CustomerListScreen displays Archived tab for Owners', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerRepositoryProvider.overrideWithValue(mockRepo),
            filteredCustomersProvider.overrideWith((ref) => Stream.value([])),
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setRole(UserRole.owner);
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: CustomerListScreen(),
          ),
        ),
      );
      await tester.pump();

      // Owner should see Archived tab
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Active Customers'), findsOneWidget);
    });

    testWidgets('CustomerDetailScreen displays details, notes, and Owner-only archive', (WidgetTester tester) async {
      final customer = Customer(
        id: 'c1',
        customerId: 'CUS-0001',
        name: 'Meenakshi',
        mobile: '9840001111',
        generalNote: 'Prefers silk lining',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
        updatedBy: 'u1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerRepositoryProvider.overrideWithValue(mockRepo),
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setRole(UserRole.owner);
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: CustomerDetailScreen(customerId: 'c1', initialCustomer: customer),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Meenakshi'), findsWidgets);
      expect(find.text('CUS-0001'), findsOneWidget);
      expect(find.text('Prefers silk lining'), findsOneWidget);
      expect(find.text('Notes History'), findsOneWidget);

      // Verify Archive option is accessible to Owner via popup menu
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      // Verify NO Hard Delete button exists anywhere
      expect(find.text('Delete'), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.delete_forever), findsNothing);
    });
  });
}
