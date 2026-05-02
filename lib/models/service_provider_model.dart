import 'user_model.dart';

class ServiceProviderModel extends UserModel {
  const ServiceProviderModel({
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
    super.experience,
    super.specializations,
    super.rating,
    super.completedJobs,
    super.isActive,
  });

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) {
    final base = UserModel.fromJson(json);
    return ServiceProviderModel(
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
      experience: base.experience,
      specializations: base.specializations,
      rating: base.rating,
      completedJobs: base.completedJobs,
      isActive: base.isActive,
    );
  }
}
