import '../../../core/error/exceptions.dart';
import '../../../core/rest_client/rest_client.dart';
import '../../../models/remote_models.dart';

/// Remote DataSource: загрузка данных с JSONPlaceholder.
abstract interface class ImportRemoteDataSource {
  Future<List<RemoteUserModel>> fetchUsers();
  Future<List<RemoteTodoModel>> fetchTodos({required int limit});
}

class ImportRemoteDataSourceImpl implements ImportRemoteDataSource {
  ImportRemoteDataSourceImpl(this._client);

  final RestClient _client;

  @override
  Future<List<RemoteUserModel>> fetchUsers() async =>
      _list(await _client.get('/users')).map(RemoteUserModel.fromJson).toList();

  @override
  Future<List<RemoteTodoModel>> fetchTodos({required int limit}) async =>
      _list(await _client.get('/todos', query: {'_limit': limit}))
          .map(RemoteTodoModel.fromJson)
          .toList();

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data is! List) {
      throw ParseException(
        'Ожидался JSON-массив, получено: ${data.runtimeType}',
      );
    }
    return data.cast<Map<String, dynamic>>();
  }
}
