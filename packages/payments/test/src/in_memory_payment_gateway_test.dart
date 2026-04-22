import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:payments/payments.dart';

void main() {
  group('InMemoryPaymentGateway', () {
    late InMemoryPaymentGateway sut;
    late DateTime fixedNow;

    setUp(() {
      fixedNow = DateTime.utc(2026, 4, 21, 10, 30);
      sut = InMemoryPaymentGateway(
        initialBalance: WalletBalance(
          available: Money.uzs(50000),
          updatedAt: fixedNow,
        ),
        clock: () => fixedNow,
      );
    });

    tearDown(() async {
      await sut.dispose();
    });

    CheckoutRequest requestFor(Money amount, {String? idempotencyKey}) =>
        CheckoutRequest(
          miniAppId: 'com.superapp.taxi',
          amount: amount,
          description: 'Taxi trip',
          idempotencyKey: idempotencyKey,
        );

    test('records a successful checkout in completedCheckouts', () async {
      final request = requestFor(Money.uzs(12500));

      final result = await sut.checkout(request);

      expect(result, isA<Ok<PaymentReceipt, AppError>>());
      expect(sut.completedCheckouts, hasLength(1));
      expect(sut.completedCheckouts.single, same(request));
    });

    test('debits the wallet when funds are sufficient', () async {
      await sut.checkout(requestFor(Money.uzs(12500)));

      expect(sut.currentBalance.available, Money.uzs(37500));
    });

    test('returns a ValidationError when funds are insufficient', () async {
      final result = await sut.checkout(requestFor(Money.uzs(99999)));

      expect(result, isA<Err<PaymentReceipt, AppError>>());
      final error = (result as Err<PaymentReceipt, AppError>).error;
      expect(error, isA<ValidationError>());
      expect((error as ValidationError).field, 'balance');
      expect(error.message, insufficientFundsMessage);
    });

    test('does not debit the wallet when funds are insufficient', () async {
      await sut.checkout(requestFor(Money.uzs(99999)));

      expect(sut.currentBalance.available, Money.uzs(50000));
      expect(sut.completedCheckouts, isEmpty);
    });

    test('returns a ValidationError on currency mismatch', () async {
      final result = await sut.checkout(requestFor(Money.usd(10)));

      expect(result, isA<Err<PaymentReceipt, AppError>>());
      final error = (result as Err<PaymentReceipt, AppError>).error;
      expect(error, isA<ValidationError>());
      expect((error as ValidationError).field, 'amount');
    });

    test('uses the preferred payment method on the receipt when set',
        () async {
      const token = PaymentMethodToken('card_tok_123');
      final result = await sut.checkout(
        CheckoutRequest(
          miniAppId: 'com.superapp.taxi',
          amount: Money.uzs(10000),
          description: 'Taxi trip',
          preferredMethod: token,
        ),
      );

      final receipt = (result as Ok<PaymentReceipt, AppError>).value;
      expect(receipt.method, token);
      expect(receipt.completedAt, fixedNow);
    });

    test('generates deterministic receipt ids with the default generator',
        () async {
      final first = await sut.checkout(requestFor(Money.uzs(1000)));
      final second = await sut.checkout(requestFor(Money.uzs(2000)));

      expect((first as Ok<PaymentReceipt, AppError>).value.id, 'rcpt_1');
      expect((second as Ok<PaymentReceipt, AppError>).value.id, 'rcpt_2');
    });

    test('honours the injected idGenerator', () async {
      final custom = InMemoryPaymentGateway(
        initialBalance: WalletBalance(
          available: Money.uzs(50000),
          updatedAt: fixedNow,
        ),
        idGenerator: () => 'fixed-id',
      );
      addTearDown(custom.dispose);

      final result = await custom.checkout(requestFor(Money.uzs(1000)));

      expect((result as Ok<PaymentReceipt, AppError>).value.id, 'fixed-id');
    });

    test('watchWallet emits the current snapshot immediately', () async {
      final first = await sut.watchWallet().first;

      expect(first.available, Money.uzs(50000));
      expect(first.updatedAt, fixedNow);
    });

    test('watchWallet emits a new snapshot after a successful checkout',
        () async {
      final snapshots = <WalletBalance>[];
      final subscription = sut.watchWallet().listen(snapshots.add);
      addTearDown(subscription.cancel);

      // Allow the initial snapshot to be delivered.
      await Future<void>.delayed(Duration.zero);
      await sut.checkout(requestFor(Money.uzs(10000)));
      await Future<void>.delayed(Duration.zero);

      expect(snapshots, hasLength(2));
      expect(snapshots.first.available, Money.uzs(50000));
      expect(snapshots.last.available, Money.uzs(40000));
    });

    test('creditBalance updates the current snapshot', () async {
      sut.creditBalance(Money.uzs(25000));

      expect(sut.currentBalance.available, Money.uzs(75000));
    });

    test('creditBalance emits on the wallet stream', () async {
      final snapshots = <WalletBalance>[];
      final subscription = sut.watchWallet().listen(snapshots.add);
      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);
      sut.creditBalance(Money.uzs(1000));
      await Future<void>.delayed(Duration.zero);

      expect(snapshots, hasLength(2));
      expect(snapshots.last.available, Money.uzs(51000));
    });

    test('creditBalance throws on currency mismatch', () {
      expect(
        () => sut.creditBalance(Money.usd(10)),
        throwsArgumentError,
      );
    });
  });
}
