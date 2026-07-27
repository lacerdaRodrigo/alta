#!/usr/bin/env python3
"""Pós-processamento dos ícones gerados por tool/gerar_icones.dart.

Duas coisas que o engine do Flutter não entrega prontas:

1. **iOS sem canal alfa.** A App Store rejeita ícone com transparência
   ("Invalid Image - ... can't be transparent nor contain an alpha channel").
   Os ícones já são opacos; aqui o canal é removido de fato.
2. **`.ico` do Windows**, que empacota vários tamanhos num arquivo só.

Requer Pillow. Rode via `make icones` (que chama o gerador antes).
"""

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit(
        'Pillow nao encontrado. Instale com: python3 -m pip install --user Pillow'
    )

RAIZ = Path(__file__).resolve().parent.parent


def achatar_ios() -> None:
    pasta = RAIZ / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for png in sorted(pasta.glob('*.png')):
        imagem = Image.open(png)
        if imagem.mode == 'RGB':
            continue
        fundo = Image.new('RGB', imagem.size, (0x4A, 0x2F, 0xB2))
        fundo.paste(imagem, mask=imagem.convert('RGBA').split()[3])
        fundo.save(png)
        print(f'  ✓ {png.relative_to(RAIZ)} (sem canal alfa)')


def gerar_ico_windows() -> None:
    destino = RAIZ / 'windows/runner/resources/app_icon.ico'
    if not destino.parent.exists():
        return
    mestre = Image.open(RAIZ / 'build/icone_mestre_1024.png').convert('RGBA')
    mestre.save(
        destino,
        format='ICO',
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )
    print(f'  ✓ {destino.relative_to(RAIZ)} (7 tamanhos)')


if __name__ == '__main__':
    achatar_ios()
    gerar_ico_windows()
