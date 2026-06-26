import '../../data/models/profile.dart';
import '../../data/models/tournament.dart';

bool canManageTournament(Tournament tournament, Profile? profile) {
  if (profile == null) return false;
  if (profile.isAdmin) return true;
  return tournament.createdBy != null && tournament.createdBy == profile.id;
}
