import '../../domain/lookup_hint.dart';
import '../../domain/models.dart';
import 'medication_remote_provider.dart';

class GepirProvider implements MedicationRemoteProvider {
  @override
  String get providerName => MedicationSource.gepir;

  @override
  int get providerPriority => MedicationSourcePriority.gepir;

  @override
  Future<RemoteProviderResult> resolve(List<LookupHint> hints) async {
    return const RemoteProviderResult(
      status: RemoteProviderStatus.unsupported,
      providerName: MedicationSource.gepir,
      entry: null,
      lookupCodes: [],
      errorMessage: 'GEPIR ainda não suporta lookup determinístico neste build.',
    );
  }
}
