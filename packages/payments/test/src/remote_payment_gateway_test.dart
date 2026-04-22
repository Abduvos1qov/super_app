import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payments/payments.dart';

class _MockNetworkGateway extends Mock implements NetworkGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
  });

  group('RemotePaymentGateway', () {
    late _MockNetworkGateway gateway;
    late RemotePaymentGateway sut;

    setUp(() {
      gateway = _MockNetworkGateway();
      sut = RemotePaymentGateway(
        gateway: gateway,
        walletPollInterval: const Duration(milliseconds: 10),
      );
    });

    CheckoutRequest sampleRequest({PaymentMethodToken? method}) =>
        CheckoutRequest(
          miniAppId: 'com.superapp.taxi',
          amount: Money.uzs(12500),
          description: 'Taxi trip',
          preferredMethod: method,
          idempotencyKey: 'idem-1',
          metadata: const {'tripId': 't_42'},
        );

    group('checkout', () {
      test('returns Ok with the decoded receipt on success', () async {
        when(
          () => gateway.post<PaymentReceipt>(
            any(),
            body: any(named: 'body'),
            decode: any(named: 'decode'),
          ),
        ).thenAnswer(
          (_) async => Ok<PaymentReceipt, AppError>(
            PaymentReceipt(
              id: 'rcpt_remote_1',
              amount: Money.uzs(12500),
              method: const PaymentMethodToken('card_tok'),
              completedAt: DateTime.utc(2026, 4, 21, 10, 30),
            ),
          ),
        );

        final result = await sut.checkout(sampleRequest());

        expect(result, isA<Ok<PaymentReceipt, AppError>>());
        final receipt = (result as Ok<PaymentReceipt, AppError>).value;
        expect(receipt.id, 'rcpt_remote_1');
        expect(receipt.amount, Money.uzs(12500));
      });

      test('posts to the configured checkoutPath with the serialised body',
          () async {
        final customSut = RemotePaymentGateway(
          gateway: gateway,
          checkoutPath: '/v2/checkout',
        );
        when(
          () => gateway.post<PaymentReceipt>(
            any(),
            body: any(named: 'body'),
            decode: any(named: 'decode'),
          ),
        ).thenAnswer(
          (_) async => Ok<PaymentReceipt, AppError>(
            PaymentReceipt(
              id: 'r',
              amount: Money.uzs(12500),
              method: const PaymentMethodToken('m'),
              completedAt: DateTime.utc(2026),
            ),
          ),
        );

        await customSut.checkout(
          sampleRequest(method: const PaymentMethodToken('pm_tok')),
        );

        final captured = verify(
          () => gateway.post<PaymentReceipt>(
            captureAny(),
            body: captureAny(named: 'body'),
            decode: any(named: 'decode'),
          ),
        ).captured;

        expect(captured[0], '/v2/checkout');
        final body = captured[1]! as Map<String, Object?>;
        expect(body['miniAppId'], 'com.superapp.taxi');
        expect(body['description'], 'Taxi trip');
        expect(body['idempotencyKey'], 'idem-1');
        expect(body['preferredMethod'], 'pm_tok');
        expect(body['metadata'], {'tripId': 't_42'});
        expect(
          body['amount'],
          {'amountMinor': 12500, 'currency': 'UZS'},
        );
      });

      test('propagates NetworkError from the transport', () async {
        when(
          () => gateway.post<PaymentReceipt>(
            any(),
            body: any(named: 'body'),
            decode: any(named: 'decode'),
          ),
        ).thenAnswer(
          (_) async => const Err<PaymentReceipt, AppError>(
            NetworkError(message: 'offline'),
          ),
        );

        final result = await sut.checkout(sampleRequest());

        expect(result, isA<Err<PaymentReceipt, AppError>>());
        expect(
          (result as Err<PaymentReceipt, AppError>).error,
          isA<NetworkError>(),
        );
      });

      test('propagates ValidationError from the transport (4xx)', () async {
        when(
          () => gateway.post<PaymentReceipt>(
            any(),
            body: any(named: 'body'),
            decode: any(named: 'decode'),
          ),
        ).thenAnswer(
          (_) async => const Err<PaymentReceipt, AppError>(
            ValidationError(message: 'bad request'),
          ),
        );

        final result = await sut.checkout(sampleRequest());

        expect(
          (result as Err<PaymentReceipt, AppError>).error,
          isA<ValidationError>(),
        );
      });

      test('decoder produces a PaymentReceipt from the wire map', () async {
        when(
          () => gateway.post<PaymentReceipt>(
            any(),
            body: any(named: 'body'),
            decode: any(named: 'decode'),
          ),
        ).thenAnswer((invocation) async {
          final decode = invocation.namedArguments[#decode]
              as PaymentReceipt Function(Object?);
          final receipt = decode(<String, Object?>{
            'id': 'rcpt_1',
            'amount': <String, Object?>{
              'amountMinor': 12500,
              'currency': 'UZS',
            },
            'method': 'card_tok_123',
            'completedAt': '2026-04-21T10:30:00Z',
          });
          return Ok<PaymentReceipt, AppError>(receipt);
        });

        final result = await sut.checkout(sampleRequest());

        final receipt = (result as Ok<PaymentReceipt, AppError>).value;
        expect(receipt.id, 'rcpt_1');
        expect(receipt.amount, Money.uzs(12500));
        expect(receipt.method.value, 'card_tok_123');
        expect(receipt.completedAt.isUtc, isTrue);
      });
    });

    group('watchWallet', () {
      test('emits successive snapshots from repeated GETs', () async {
        var call = 0;
        when(
          () => gateway.get<WalletBalance>(
            any(),
            decode: any(named: 'decode'),
          ),
        ).thenAnswer((_) async {
          call += 1;
          return Ok<WalletBalance, AppError>(
            WalletBalance(
              available: Money.uzs(50000 - call * 1000),
              updatedAt: DateTime.utc(2026, 4, 21, 10, call),
            ),
          );
        });

        final snapshots = <WalletBalance>[];
        final subscription = sut.watchWallet().listen(snapshots.add);
        addTearDown(subscription.cancel);

        // Wait long enough for three polls at 10ms interval.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        expect(snapshots.length, greaterThanOrEqualTo(2));
        expect(snapshots[0].available, Money.uzs(49000));
        expect(snapshots[1].available, Money.uzs(48000));
      });

      test('hits the configured walletPath', () async {
        final customSut = RemotePaymentGateway(
          gateway: gateway,
          walletPath: '/v2/wallet',
          walletPollInterval: const Duration(milliseconds: 10),
        );
        when(
          () => gateway.get<WalletBalance>(
            any(),
            decode: any(named: 'decode'),
          ),
        ).thenAnswer(
          (_) async => Ok<WalletBalance, AppError>(
            WalletBalance(
              available: Money.uzs(1),
              updatedAt: DateTime.utc(2026),
            ),
          ),
        );

        final subscription = customSut.watchWallet().listen((_) {});
        addTearDown(subscription.cancel);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        await subscription.cancel();

        verify(
          () => gateway.get<WalletBalance>(
            '/v2/wallet',
            decode: any(named: 'decode'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      test('swallows transport failures and keeps polling', () async {
        final responses = <Result<WalletBalance, AppError>>[
          const Err(NetworkError(message: 'offline')),
          Ok(
            WalletBalance(
              available: Money.uzs(42),
              updatedAt: DateTime.utc(2026),
            ),
          ),
        ];
        var idx = 0;
        when(
          () => gateway.get<WalletBalance>(
            any(),
            decode: any(named: 'decode'),
          ),
        ).thenAnswer((_) async {
          final r = responses[idx.clamp(0, responses.length - 1)];
          idx += 1;
          return r;
        });

        final snapshots = <WalletBalance>[];
        final subscription = sut.watchWallet().listen(snapshots.add);
        addTearDown(subscription.cancel);

        await Future<void>.delayed(const Duration(milliseconds: 40));
        await subscription.cancel();

        expect(snapshots, isNotEmpty);
        expect(snapshots.first.available, Money.uzs(42));
      });

      test('decoder builds a WalletBalance from wire JSON', () async {
        WalletBalance? decoded;
        when(
          () => gateway.get<WalletBalance>(
            any(),
            decode: any(named: 'decode'),
          ),
        ).thenAnswer((invocation) async {
          final decode = invocation.namedArguments[#decode]
              as WalletBalance Function(Object?);
          final result = decode(<String, Object?>{
            'available': <String, Object?>{
              'amountMinor': 100000,
              'currency': 'UZS',
            },
            'updatedAt': '2026-04-21T10:30:00Z',
          });
          decoded = result;
          return Ok<WalletBalance, AppError>(result);
        });

        final subscription = sut.watchWallet().listen((_) {});
        addTearDown(subscription.cancel);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        await subscription.cancel();

        expect(decoded, isNotNull);
        if (decoded case final WalletBalance snapshot) {
          expect(snapshot.available, Money.uzs(100000));
          expect(snapshot.updatedAt.isUtc, isTrue);
        }
      });
    });
  });
}
