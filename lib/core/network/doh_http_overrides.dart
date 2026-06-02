import 'dart:convert';
import 'dart:io';

/// DNS-over-HTTPS override.
///
/// Quando o DNS da operadora bloqueia/falha resolver domínios (como .supabase.co),
/// esta classe faz a resolução DNS via HTTPS diretamente no IP do Google (8.8.8.8),
/// sem depender do servidor DNS da rede atual.
class DohHttpOverrides extends HttpOverrides {
  // Cache simples em memória para evitar consultas repetidas
  static final Map<String, String> _cache = {};

  // IP fixo do servidor DoH do Google — não precisa de DNS para acessar
  static const _dohIp = '8.8.8.8';

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) {
      return _connect(uri, context);
    };
    return client;
  }

  Future<ConnectionTask<Socket>> _connect(
      Uri uri, SecurityContext? context) async {
    final host = uri.host;
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);

    // Tenta resolver via DoH se ainda não está no cache
    if (!_cache.containsKey(host)) {
      final ip = await _resolveViaDoh(host);
      if (ip != null) _cache[host] = ip;
    }

    final resolvedIp = _cache[host];

    if (resolvedIp != null && uri.scheme == 'https') {
      // Conecta ao IP resolvido usando SNI correto para o TLS funcionar
      final socketFuture = SecureSocket.connect(
        resolvedIp,
        port,
        context: context,
        serverName: host, // garante que o certificado seja validado pelo hostname
      );
      return ConnectionTask.fromSocket(socketFuture);
    }

    // Fallback: usa o comportamento padrão
    return super
        .createHttpClient(context)
        .connectionFactory!(uri, proxyHost, proxyPort);
  }

  Future<String?> _resolveViaDoh(String hostname) async {
    try {
      // Cria um HttpClient temporário para a consulta DoH
      // Conecta direto ao IP 8.8.8.8 sem precisar de DNS
      final innerClient = HttpClient();
      innerClient.badCertificateCallback = (cert, host, port) {
        // Aceita o certificado do Google mesmo conectando via IP
        return host == _dohIp;
      };

      final request = await innerClient.getUrl(
        Uri.parse('https://$_dohIp/resolve?name=$hostname&type=A'),
      );
      // Informa ao servidor qual host estamos acessando (necessário para TLS)
      request.headers.set('Host', 'dns.google');
      request.headers.set('Accept', 'application/dns-json');

      final response = await request.close().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('DoH timeout'),
      );

      final body = await response.transform(utf8.decoder).join();
      innerClient.close();

      final data = json.decode(body) as Map<String, dynamic>;
      final answers = data['Answer'] as List?;

      if (answers != null) {
        // Pega o primeiro registro A (tipo 1 = IPv4)
        for (final answer in answers) {
          if (answer['type'] == 1) {
            return answer['data'] as String;
          }
        }
      }
    } catch (_) {
      // Se o DoH também falhar, retorna null → usa DNS padrão
    }
    return null;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
