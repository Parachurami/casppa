class ServerException implements Exception {
  const ServerException(this.message);

  final String message;
}

class CacheException implements Exception {
  const CacheException(this.message);

  final String message;
}

class AppAuthException implements Exception {
  const AppAuthException(this.message);

  final String message;
}
