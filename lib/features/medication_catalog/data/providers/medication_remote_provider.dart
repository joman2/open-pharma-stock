import '../../domain/lookup_hint.dart';
import '../../domain/models.dart';

abstract class MedicationRemoteProvider {
  String get providerName;
  int get providerPriority;

  Future<RemoteProviderResult> resolve(List<LookupHint> hints);
}
