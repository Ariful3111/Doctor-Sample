import 'package:doctor_app/data/networks/get_networks.dart';
import 'package:doctor_app/features/dashboard/models/tour_model.dart';
import 'package:fpdart/fpdart.dart';

class GetTourRepository {
  final GetNetwork getNetwork;
  const GetTourRepository({required this.getNetwork});

  Future<Either<String, CombinedScheduleModel>> execute({
    required String date,
    required int driverId,
  }) async {
    final formattedDate = date;
    final response = await getNetwork.getData<CombinedScheduleModel>(
      url: "/api/appointments/driver/$driverId/$formattedDate",
      headers: {},
      fromJson: (json) => CombinedScheduleModel.fromJson(json),
    );
    return response;
  }
}
