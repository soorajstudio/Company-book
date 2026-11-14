import 'package:flutter_test/flutter_test.dart';
import 'package:company_book/models/company_model.dart';
import 'package:company_book/models/category_model.dart';
import 'package:company_book/models/transaction_model.dart';

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
}
