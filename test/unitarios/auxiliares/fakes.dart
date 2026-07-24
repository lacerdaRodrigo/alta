import 'package:fisio_home_care/servicos/servico_autenticacao_google.dart';

/// Fake compartilhado para testes que precisam de autenticação Google.
class ServicoAutenticacaoGoogleFake implements ServicoAutenticacaoGoogle {
  @override
  Stream<ContaGoogleConectada> get contasConectadas => const Stream.empty();

  @override
  Stream<SessaoGoogle> get sessoesConectadas => const Stream.empty();

  @override
  bool get suportaLoginProgramatico => true;

  @override
  Future<void> inicializar() async {}

  @override
  Future<SessaoGoogle?> tentarRestaurarSessao() async => null;

  @override
  Future<SessaoGoogle> entrar() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return SessaoGoogle(
      nomeUsuario: 'Dr. Teste',
      email: 'teste@example.com',
      obterHeaders: () async => {'Authorization': 'Bearer fake-token'},
    );
  }

  @override
  Future<void> sair() async {}
}
