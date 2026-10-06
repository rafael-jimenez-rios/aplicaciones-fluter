import '../../data/daos/auth_dao.dart';

class CheckSessionController {
  CheckSessionController({AuthDao? authDao}) : _authDao = authDao ?? AuthDao();

  final AuthDao _authDao;

  Future<String?> getActiveRole() async {
    final session = await _authDao.getActiveSession();
    if (session['token'] == null) return null;
    return session['role'];
  }
}
