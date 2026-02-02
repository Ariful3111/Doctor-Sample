import 'package:doctor_app/data/networks/post_with_response.dart';
import 'package:doctor_app/features/auth/models/login_model.dart';
import 'package:fpdart/fpdart.dart';

class LoginRepository {
  final PostWithResponse postWithResponse;
  const LoginRepository({required this.postWithResponse});
  Future<Either<String, LoginModel>> execute({
    required String userName,
    required String password,
  }) async {
    final response = await postWithResponse.postData<LoginModel>(
      url: "/api/drivers/login",
      body: {"username": userName, "password": password},
      fromJson: (json) => LoginModel.fromJson(json),
    );
    return response;
  }
}
