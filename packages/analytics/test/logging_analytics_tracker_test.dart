import 'package:analytics/analytics.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _CapturingOutput extends LogOutput {
  final List<OutputEvent> events = <OutputEvent>[];

  @override
  void output(OutputEvent event) {
    events.add(event);
  }
}

void main() {
  group('LoggingAnalyticsTracker', () {
    late _CapturingOutput output;
    late LoggingAnalyticsTracker sut;

    setUp(() {
      output = _CapturingOutput();
      final logger = Logger(
        printer: SimplePrinter(colors: false),
        output: output,
        filter: ProductionFilter()..level = Level.trace,
      );
      sut = LoggingAnalyticsTracker(
        logger: AppLogger(tag: 'test', logger: logger),
      );
    });

    test('logs an event with its properties', () {
      sut.track('demo.button.tapped', props: const {'variant': 'primary'});

      expect(output.events, isNotEmpty);
      final lines = output.events.expand((e) => e.lines).join('\n');
      expect(lines, contains('demo.button.tapped'));
      expect(lines, contains('variant'));
      expect(lines, contains('primary'));
    });

    test('logs an event with no properties', () {
      sut.track('demo.opened');

      final lines = output.events.expand((e) => e.lines).join('\n');
      expect(lines, contains('demo.opened'));
      expect(lines, contains('{}'));
    });

    test('stores user properties and logs them', () {
      sut.setUserProperty('tier', 'gold');

      expect(sut.userPropertiesSnapshot, equals({'tier': 'gold'}));
      final lines = output.events.expand((e) => e.lines).join('\n');
      expect(lines, contains('tier'));
      expect(lines, contains('gold'));
    });

    test('removes user property when value is null', () {
      sut
        ..setUserProperty('tier', 'gold')
        ..setUserProperty('tier', null);

      expect(sut.userPropertiesSnapshot, isEmpty);
    });

    test('userPropertiesSnapshot is unmodifiable', () {
      sut.setUserProperty('tier', 'gold');

      expect(
        () => sut.userPropertiesSnapshot['tier'] = 'silver',
        throwsUnsupportedError,
      );
    });

    test('flush is a no-op that completes', () async {
      await expectLater(sut.flush(), completes);
    });
  });
}
