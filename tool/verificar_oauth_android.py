#!/usr/bin/env python3
"""Verifica se o google-services.json cobre o applicationId atual.

Substitui o `grep '"client_type": 1'` que o Makefile usava: aquele grep achava
o cliente Android de **qualquer** pacote do arquivo, então continuou passando
depois da renomeação para `com.rodrigo.alta`, enquanto o arquivo só tinha o
cliente do pacote antigo — falso positivo que custou tempo de depuração.

Uso: python3 tool/verificar_oauth_android.py
"""

import json
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CONFIG = RAIZ / 'android/app/google-services.json'
GRADLE = RAIZ / 'android/app/build.gradle.kts'

CLIENTE_ANDROID = 1
CLIENTE_WEB = 3


def application_id() -> str:
    texto = GRADLE.read_text()
    achado = re.search(r'applicationId\s*=\s*"([^"]+)"', texto)
    if not achado:
        sys.exit('ERRO: applicationId não encontrado em android/app/build.gradle.kts')
    return achado.group(1)


def main() -> None:
    if not CONFIG.exists():
        sys.exit(f'ERRO: {CONFIG.relative_to(RAIZ)} não existe.')

    pacote = application_id()
    dados = json.loads(CONFIG.read_text())

    bloco = next(
        (
            c
            for c in dados.get('client', [])
            if c['client_info']['android_client_info']['package_name'] == pacote
        ),
        None,
    )

    if bloco is None:
        pacotes = [
            c['client_info']['android_client_info']['package_name']
            for c in dados.get('client', [])
        ]
        sys.exit(
            f'ERRO: google-services.json não tem bloco para "{pacote}".\n'
            f'       Pacotes no arquivo: {", ".join(pacotes) or "(nenhum)"}\n'
            '       Adicione o app no Firebase Console e baixe o arquivo de novo.'
        )

    tipos = {o.get('client_type') for o in bloco.get('oauth_client', [])}

    if CLIENTE_WEB not in tipos:
        print(f'AVISO: "{pacote}" sem cliente OAuth web (client_type 3) no arquivo.')

    if CLIENTE_ANDROID not in tipos:
        sys.exit(
            f'ERRO: "{pacote}" não tem cliente OAuth Android (client_type 1).\n'
            '       O login no Android falha com "[16] Account reauth failed" /\n'
            '       "This android application is not registered to use OAuth2.0".\n'
            '       Crie um cliente OAuth do tipo Android para esse pacote + SHA-1\n'
            '       em Google Cloud Console → Credenciais, e baixe o arquivo de novo.\n'
            '       Cadastrar a impressão digital só no Firebase não basta.'
        )

    print(f'OK: "{pacote}" tem cliente OAuth Android (client_type 1) no arquivo.')


if __name__ == '__main__':
    main()
