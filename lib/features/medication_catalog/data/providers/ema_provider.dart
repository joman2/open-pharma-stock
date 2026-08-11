import '../../domain/lookup_hint.dart';
import '../../domain/models.dart';
import 'medication_remote_provider.dart';

class EmaProvider implements MedicationRemoteProvider {
  @override
  String get providerName => MedicationSource.ema;

  @override
  int get providerPriority => MedicationSourcePriority.ema;

  @override
  Future<RemoteProviderResult> resolve(List<LookupHint> hints) async {
    return const RemoteProviderResult(
      status: RemoteProviderStatus.unsupported,
      providerName: MedicationSource.ema,
      entry: null,
      lookupCodes: [],
      errorMessage: 'EMA ainda não suporta lookup determinístico neste build.',
    );
  }
}
