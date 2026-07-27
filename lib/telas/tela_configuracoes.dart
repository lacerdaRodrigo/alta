import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../componentes/design_system.dart';
import '../provedores/provedores_dados.dart';
import '../provedores/provedor_autenticacao.dart';
import 'tela_login.dart';

class TelaConfiguracoes extends ConsumerStatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  ConsumerState<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends ConsumerState<TelaConfiguracoes> {
  final _valorController = TextEditingController();
  bool _notif = true;
  bool _lembrete = true;

  @override
  void initState() {
    super.initState();
    _valorController.text = ref.read(provedorValorSessaoPadrao);
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _sair() async {
    await ref.read(provedorAutenticacao.notifier).sair();
    limparDados(ref);
    if (mounted) {
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TelaLogin()),
        (_) => false,
      );
    }
  }

  Future<void> _sincronizar() async {
    await carregarDadosReais(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados sincronizados!')),
    );
  }

  Future<void> _abrirDrive() async {
    final planilhaId = ref.read(provedorPlanilhaId);
    final url = planilhaId != null
        ? 'https://docs.google.com/spreadsheets/d/$planilhaId'
        : 'https://drive.google.com';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copiarLogs() async {
    final logs = ref.read(provedorLogsAuditoria);
    await Clipboard.setData(ClipboardData(text: logs.join('\n')));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs copiados para a área de transferência.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(provedorAutenticacao);
    final nome = auth.sessao?.nomeUsuario ?? 'Profissional';
    final email = auth.sessao?.email ?? '';
    final planilhaId = ref.watch(provedorPlanilhaId);

    return Material(
      color: FisioCores.surface,
      child: FisioResponsiveCenter(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FisioGradientHeader(
              eyebrow: 'Conta',
              titulo: 'Configurações',
              bottom: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(fisioIniciais(nome),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nome,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          Text(email,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.75))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FisioSectionLabel('Base de dados'),
                  const SizedBox(height: 9),
                  FisioCard(
                    radius: 16,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: FisioCores.success.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.grid_on_rounded,
                                  color: FisioCores.success, size: 18),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Planilha conectada',
                                      style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: FisioCores.textPrimary)),
                                  Text(
                                    planilhaId != null
                                        ? '__saas_fisio_db__'
                                        : 'Não conectada',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: FisioCores.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            FisioStatusPill(
                                label: planilhaId != null ? 'Ativa' : 'Inativa',
                                cor: planilhaId != null
                                    ? FisioCores.success
                                    : FisioCores.warning),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _botaoSecundario(
                                    'Sincronizar', _sincronizar)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _botaoSecundario(
                                    'Abrir no Drive', _abrirDrive)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FisioSectionLabel('Valor padrão da sessão'),
                  const SizedBox(height: 9),
                  FisioCard(
                    radius: 16,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_money_rounded,
                            color: FisioCores.primary, size: 20),
                        const SizedBox(width: 10),
                        const Text('R\$ ',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: FisioCores.textPrimary)),
                        Expanded(
                          child: TextField(
                            controller: _valorController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: FisioCores.textPrimary),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: '150,00',
                            ),
                            onSubmitted: (v) async {
                              final messenger = ScaffoldMessenger.of(context);
                              await salvarValorSessaoPadraoReal(ref, v);
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Valor padrão salvo!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FisioSectionLabel('Preferências'),
                  const SizedBox(height: 9),
                  FisioCard(
                    radius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _switchTile(
                            Icons.notifications_rounded,
                            FisioCores.primary,
                            'Notificações',
                            'Alertas de sessões e pendências',
                            _notif,
                            (v) => setState(() => _notif = v)),
                        _divisor(),
                        _switchTile(
                            Icons.edit_note_rounded,
                            FisioCores.warning,
                            'Lembrete de evolução',
                            'Avisar após cada atendimento',
                            _lembrete,
                            (v) => setState(() => _lembrete = v),
                            ultimo: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FisioSectionLabel('Privacidade e conta'),
                  const SizedBox(height: 9),
                  FisioCard(
                    radius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _linkTile('Exportar logs de auditoria', _copiarLogs),
                        _divisor(),
                        _linkTile('Sair da conta', _sair,
                            danger: true, ultimo: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('Alta',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB6C2CC))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoSecundario(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569))),
      ),
    );
  }

  Widget _switchTile(IconData icon, Color cor, String titulo, String sub,
      bool valor, ValueChanged<bool> onChanged,
      {bool ultimo = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: FisioCores.textPrimary)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: FisioCores.textMuted)),
              ],
            ),
          ),
          Switch(
            value: valor,
            activeThumbColor: Colors.white,
            activeTrackColor: FisioCores.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _linkTile(String titulo, VoidCallback? onTap,
      {bool danger = false, bool ultimo = false}) {
    final cor = danger ? FisioCores.danger : FisioCores.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(titulo,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: cor)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: danger ? FisioCores.danger : const Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _divisor() => const Divider(height: 1, color: Color(0xFFF1F5F9));
}
