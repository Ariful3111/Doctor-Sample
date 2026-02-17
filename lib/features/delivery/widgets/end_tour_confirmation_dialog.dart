import 'package:doctor_app/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/tour_state_service.dart';

class EndTourConfirmationDialog {
  static Future<bool> show({
    required int appointmentId,
    required String tourId,
    required TourStateService tourStateService,
  }) async {
    final context = Get.context;
    if (context == null) return false;

    final result = await Get.to<bool>(
      () => _EndTourConfirmationPage(
        appointmentId: appointmentId,
        tourId: tourId,
        tourStateService: tourStateService,
      ),
      preventDuplicates: false,
    );

    return result == true;
  }
}

class _EndTourConfirmationPage extends StatefulWidget {
  final int appointmentId;
  final String tourId;
  final TourStateService tourStateService;

  const _EndTourConfirmationPage({
    required this.appointmentId,
    required this.tourId,
    required this.tourStateService,
  });

  @override
  State<_EndTourConfirmationPage> createState() =>
      _EndTourConfirmationPageState();
}

class _EndTourConfirmationPageState extends State<_EndTourConfirmationPage> {
  bool isLoading = false;
  String? errorMessage;

  Future<void> _performEndTour() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final ended = await widget.tourStateService.endTour(
      appointmentId: widget.appointmentId,
      tourId: widget.tourId,
    );

    if (ended) {
      Get.back(result: true);
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to end tour. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showCannotGoBackDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('tour_completed'.tr),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'tour_completed_message'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _performEndTour,
                            child: Text(
                              errorMessage == null ? 'proceed'.tr : 'retry'.tr,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCannotGoBackDialog(BuildContext context) {
    final code = Get.locale?.languageCode;
    final message = code == 'de'
        ? 'Fahren Sie bitte mit dem nächsten Schritt fort. Von dieser Seite aus können Sie nicht zurück navigieren.'
        : 'Please proceed to the next step. You cannot go back from this page.';

    SnackbarUtils.showInfo(title: "info".tr, message: message);
  }
}
