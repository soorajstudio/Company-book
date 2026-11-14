import 'package:flutter_test/flutter_test.dart';
import 'package:company_book/models/company_model.dart';
import 'package:company_book/models/transaction_model.dart';
import 'package:company_book/services/transaction_service.dart';

void main() {
  test('CompanyModel single member flag test', () {
    const comp = CompanyModel(
      id: 'comp-123',
      name: 'Acme Corp',
    );
    expect(comp.name, 'Acme Corp');
    expect(comp.isSingleMemberOnly, true);
    expect(comp.displayCode, 'COMP12');
  });

  test('CompanyMemberModel role verification', () {
    const member = CompanyMemberModel(
      id: 'user-1',
      username: 'ceo',
      fullName: 'Alice Walker',
      isAdmin: true,
    );
    expect(member.role, 'Sole Authorized Member');
    expect(member.displayName, 'Alice Walker');
    expect(member.initials, 'AW');
  });

  test('TransactionModel ledger entry calculations', () {
    final tIncome = TransactionModel(
      id: 'tx-1',
      companyId: 'comp-123',
      type: 'income',
      amount: 50000,
      date: DateTime(2026, 11, 1),
    );
    expect(tIncome.isIncome, true);
    expect(tIncome.isExpense, false);
    expect(tIncome.recordedByTitle, 'Sole Authorized Member');
  });

  test('Salary cycle calculation (18th - 17th)', () {
    // Exactly on the 18th (e.g., Nov 18, 2026) -> Nov 18 to Dec 17
    final on18th = DateTime(2026, 11, 18, 10, 30);
    final start1 = TransactionService.getCycleStartDate(on18th);
    final end1 = TransactionService.getCycleEndDate(start1);
    expect(start1, DateTime(2026, 11, 18));
    expect(end1, DateTime(2026, 12, 17));

    // Before the 18th (e.g., Nov 14, 2026) -> Oct 18 to Nov 17
    final before18th = DateTime(2026, 11, 14, 15, 0);
    final start2 = TransactionService.getCycleStartDate(before18th);
    final end2 = TransactionService.getCycleEndDate(start2);
    expect(start2, DateTime(2026, 10, 18));
    expect(end2, DateTime(2026, 11, 17));

    // On the 17th (e.g., Nov 17, 2026) -> Oct 18 to Nov 17
    final on17th = DateTime(2026, 11, 17, 23, 0);
    final start3 = TransactionService.getCycleStartDate(on17th);
    final end3 = TransactionService.getCycleEndDate(start3);
    expect(start3, DateTime(2026, 10, 18));
    expect(end3, DateTime(2026, 11, 17));

    // Year-end boundary (Jan 5, 2027) -> Dec 18, 2026 to Jan 17, 2027
    final jan = DateTime(2027, 1, 5);
    final start4 = TransactionService.getCycleStartDate(jan);
    final end4 = TransactionService.getCycleEndDate(start4);
    expect(start4, DateTime(2026, 12, 18));
    expect(end4, DateTime(2027, 1, 17));
  });
}
