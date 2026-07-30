/// Páginas legais publicadas junto com o app.
///
/// São arquivos estáticos em `branding/`, copiados para `build/web` pelo alvo
/// `prod-web` do Makefile e pelos workflows de deploy. O `firebase.json` tem
/// rewrites explícitos para os dois caminhos — sem eles o catch-all mandaria
/// tudo para o `index.html` e as páginas nunca apareceriam.
class LinksLegais {
  static const base = 'https://app-fisio-care-2.web.app';

  static const termosDeUso = '$base/termos.html';
  static const politicaPrivacidade = '$base/privacidade.html';
}
