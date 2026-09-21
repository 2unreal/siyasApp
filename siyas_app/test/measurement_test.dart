import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/core/config/app_environment.dart';
import 'package:siyas_app/data/repositories/measurement_repository.dart';
import 'package:siyas_app/domain/models/measurement_model.dart';
import 'package:siyas_app/presentation/providers/measurement_provider.dart';
import 'package:siyas_app/presentation/screens/measurements/measurement_entry_screen.dart';
import 'package:siyas_app/presentation/screens/measurements/measurement_history_screen.dart';

class MockMeasurementRepository implements MeasurementRepository {
  final List<MeasurementSet> _sets = [];
  final _setsStreamController = StreamController<List<MeasurementSet>>.broadcast();

  @override
  String get businessId => 'house_of_siyas';

  @override
  Stream<List<MeasurementTemplate>> streamTemplates() {
    return Stream.value(MeasurementRepository.standardTemplates);
  }

  @override
  Stream<List<MeasurementSet>> streamCustomerMeasurements(String customerId) async* {
    yield _sets.where((s) => s.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield* _setsStreamController.stream.map(
      (list) => list.where((s) => s.customerId == customerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<void> createMeasurementSet(MeasurementSet measurementSet) async {
    _sets.add(measurementSet);
    _setsStreamController.add(List.from(_sets));
  }

  @override
  Future<void> saveTemplate(MeasurementTemplate template) async {}
}

void main() {
  setUp(() {
    AppConfig.initialize(AppEnvironment.dev);
  });

  group('Milestone 5 — Unit Conversion & Template Definitions', () {
    test('Inches to Centimetres conversion (1 inch = 2.54 cm)', () {
      expect(MeasurementUnitConverter.inchesToCm(1.0), 2.5);
      expect(MeasurementUnitConverter.inchesToCm(10.0), 25.4);
      expect(MeasurementUnitConverter.inchesToCm(36.0), 91.4);
      expect(MeasurementUnitConverter.inchesToCm(14.5), 36.8);
    });

    test('Centimetres to Inches conversion', () {
      expect(MeasurementUnitConverter.cmToInches(25.4), 10.0);
      expect(MeasurementUnitConverter.cmToInches(91.44), 36.0);
    });

    test('Standard tailoring templates are populated with correct field counts', () {
      final templates = MeasurementRepository.standardTemplates;
      expect(templates.length, 4);

      final blouse = templates.firstWhere((t) => t.id == 'blouse');
      expect(blouse.garmentType, 'Blouse');
      expect(blouse.fields.length, 9);
      expect(blouse.fields.any((f) => f.id == 'bust_round'), isTrue);

      final bridal = templates.firstWhere((t) => t.id == 'bridal_blouse');
      expect(bridal.garmentType, 'Bridal Blouse');
      expect(bridal.fields.length, 12);
      expect(bridal.fields.any((f) => f.id == 'padding_point'), isTrue);

      final dress = templates.firstWhere((t) => t.id == 'dress');
      expect(dress.garmentType, 'Dress / Kurti');
      expect(dress.fields.length, 8);

      final churidar = templates.firstWhere((t) => t.id == 'churidar');
      expect(churidar.garmentType, 'Churidar / Pant');
      expect(churidar.fields.length, 6);
    });

    test('MeasurementSet retains canonical values and unit metadata', () {
      final mSet = MeasurementSet(
        id: 'm1',
        customerId: 'c1',
        templateId: 'blouse',
        garmentType: 'Blouse',
        values: const {
          'length': 14.5,
          'bust_round': 36.0,
          'waist_round': 30.0,
        },
        unit: 'inches',
        notes: 'Loose armhole required',
        createdAt: DateTime(2026, 9, 21),
        createdBy: 'u1',
      );

      final map = mSet.toMap();
      expect(map['unit'], 'inches');
      expect(map['values']['length'], 14.5);
      expect(map['notes'], 'Loose armhole required');

      final deserialized = MeasurementSet.fromMap(map, 'm1');
      expect(deserialized.garmentType, 'Blouse');
      expect(deserialized.values['bust_round'], 36.0);
    });
  });

  group('Milestone 5 — Measurement UI & Append-Only Workflow Tests', () {
    late MockMeasurementRepository mockRepo;

    setUp(() {
      mockRepo = MockMeasurementRepository();
    });

    testWidgets('MeasurementEntryScreen validates at least one numeric field is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MeasurementEntryScreen(customerId: 'c1', customerName: 'Deepika'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save without entering any values
      await tester.tap(find.text('Save Measurement Set'));
      await tester.pump();

      expect(find.text('Please enter at least one measurement value.'), findsOneWidget);
      expect(mockRepo._sets, isEmpty);
    });

    testWidgets('MeasurementEntryScreen converts units in-place on toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MeasurementEntryScreen(customerId: 'c1', customerName: 'Deepika'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 10 inches in first field (Blouse Length)
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '10');
      await tester.pump();

      // Toggle to CM
      await tester.tap(find.text('CM'));
      await tester.pumpAndSettle();

      // Verify value converted to 25.4 cm
      expect(find.text('25.4'), findsOneWidget);

      // Toggle back to Inches
      await tester.tap(find.text('Inches'));
      await tester.pumpAndSettle();

      // Verify converted back
      expect(find.text('10.0'), findsOneWidget);
    });

    testWidgets('MeasurementEntryScreen saves new measurement set append-only', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MeasurementEntryScreen(customerId: 'c1', customerName: 'Deepika'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter measurements
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '14.5'); // Length
      await tester.enterText(find.byType(TextField).last, 'Padded cups requested'); // Notes

      await tester.tap(find.text('Save Measurement Set'));
      await tester.pumpAndSettle();

      expect(mockRepo._sets.length, 1);
      expect(mockRepo._sets.first.customerId, 'c1');
      expect(mockRepo._sets.first.garmentType, 'Blouse');
      expect(mockRepo._sets.first.values['length'], 14.5);
      expect(mockRepo._sets.first.notes, 'Padded cups requested');
    });

    testWidgets('MeasurementEntryScreen pre-fills from baseline initialSet', (WidgetTester tester) async {
      final baseline = MeasurementSet(
        id: 'm_prev',
        customerId: 'c1',
        templateId: 'blouse',
        garmentType: 'Blouse',
        values: const {'length': 15.0, 'bust_round': 38.0},
        unit: 'inches',
        notes: 'Needs deep back',
        createdAt: DateTime(2026, 9, 1),
        createdBy: 'u1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: MeasurementEntryScreen(
              customerId: 'c1',
              customerName: 'Deepika',
              initialSet: baseline,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify baseline values and notes are pre-filled
      expect(find.text('15.0'), findsOneWidget);
      expect(find.text('38.0'), findsOneWidget);
      expect(find.text('Needs deep back'), findsOneWidget);
    });

    testWidgets('MeasurementHistoryScreen renders chronological history and LATEST badge', (WidgetTester tester) async {
      final set1 = MeasurementSet(
        id: 'm1',
        customerId: 'c1',
        templateId: 'blouse',
        garmentType: 'Blouse',
        values: const {'length': 14.0},
        unit: 'inches',
        createdAt: DateTime(2026, 8, 1),
        createdBy: 'u1',
      );
      final set2 = MeasurementSet(
        id: 'm2',
        customerId: 'c1',
        templateId: 'blouse',
        garmentType: 'Blouse',
        values: const {'length': 14.5},
        unit: 'inches',
        createdAt: DateTime(2026, 9, 15),
        createdBy: 'u1',
      );

      await mockRepo.createMeasurementSet(set1);
      await mockRepo.createMeasurementSet(set2);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MeasurementHistoryScreen(customerId: 'c1', customerName: 'Deepika'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Latest set (set2) should show LATEST badge
      expect(find.text('LATEST'), findsOneWidget);
      expect(find.text('Blouse'), findsWidgets);
    });
  });
}
