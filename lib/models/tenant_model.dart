import 'user_model.dart';

class TenantModel extends UserModel {
  const TenantModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.role,
    super.profilePhoto,
    super.address,
    super.city,
    super.state,
    super.pincode,
    super.country,
    super.businessName,
    super.subdomain,
    super.businessDescription,
    super.businessType,
    super.businessWebsite,
    super.isActive,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final base = UserModel.fromJson(json);
    return TenantModel(
      id: base.id,
      fullName: base.fullName,
      email: base.email,
      phone: base.phone,
      role: base.role,
      profilePhoto: base.profilePhoto,
      address: base.address,
      city: base.city,
      state: base.state,
      pincode: base.pincode,
      country: base.country,
      businessName: base.businessName,
      subdomain: base.subdomain,
      businessDescription: base.businessDescription,
      businessType: base.businessType,
      businessWebsite: base.businessWebsite,
      isActive: base.isActive,
    );
  }
}
