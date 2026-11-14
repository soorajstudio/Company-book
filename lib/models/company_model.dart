class CompanyModel {
  final String id;
  final String name;
  final String? inviteCode;
  final String? createdBy;
  final DateTime? createdAt;
  final String? businessType;
  final bool isSingleMemberOnly;

  const CompanyModel({
    required this.id,
    required this.name,
    this.inviteCode,
    this.createdBy,
    this.createdAt,
    this.businessType,
    this.isSingleMemberOnly = true,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      inviteCode: map['invite_code'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      businessType: map['business_type'] as String? ?? 'General Business',
      isSingleMemberOnly: true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'invite_code': inviteCode,
        'created_by': createdBy,
      };

  String get displayCode {
    if (inviteCode != null && inviteCode!.trim().isNotEmpty) {
      return inviteCode!.trim().toUpperCase();
    }
    final cleanId = id.replaceAll('-', '').toUpperCase();
    return cleanId.length >= 6 ? cleanId.substring(0, 6) : cleanId;
  }
}

class CompanyMemberModel {
  final String id;
  final String? companyId;
  final String username;
  final String? fullName;
  final String? phone;
  final bool isAdmin;
  final String role; // 'Sole Authorized Member'

  const CompanyMemberModel({
    required this.id,
    this.companyId,
    required this.username,
    this.fullName,
    this.phone,
    required this.isAdmin,
    this.role = 'Sole Authorized Member',
  });

  factory CompanyMemberModel.fromMap(Map<String, dynamic> map) {
    return CompanyMemberModel(
      id: map['id'] as String,
      companyId: map['family_id'] as String?,
      username: map['username'] as String? ?? 'Unknown Member',
      fullName: map['full_name'] as String?,
      phone: map['phone'] as String?,
      isAdmin: map['is_admin'] as bool? ?? false,
      role: 'Sole Authorized Member',
    );
  }

  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : username;

  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
