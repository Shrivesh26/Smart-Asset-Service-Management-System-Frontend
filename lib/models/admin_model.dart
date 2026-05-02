import 'user_model.dart';

class AdminModel extends UserModel {
  const AdminModel({
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
    super.gstNumber,
    super.businessDescription,
    super.isActive,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    final base = UserModel.fromJson(json);
    return AdminModel(
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
      gstNumber: base.gstNumber,
      businessDescription: base.businessDescription,
      isActive: base.isActive,
    );
  }
}
