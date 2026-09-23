"""
Converte logo.png para app.ico (multi-resolução para Windows).
Execute ANTES de rodar o build.bat:
    python make_icon.py
"""

from pathlib import Path
from PIL import Image


def make_ico():
    src = Path(__file__).parent / "logo.png"
    dst = Path(__file__).parent / "app.ico"

    if not src.exists():
        print(
            "ERRO: arquivo 'logo.png' não encontrado.\n"
            f"       Coloque o logo em: {src}\n"
            "       e execute este script novamente."
        )
        return

    img = Image.open(src).convert("RGBA")

    # Tamanhos padrão para ícone Windows (inclui 256 para alta resolução)
    sizes = [16, 24, 32, 48, 64, 128, 256]
    icons = [img.resize((s, s), Image.LANCZOS) for s in sizes]

    icons[0].save(dst, format="ICO", sizes=[(s, s) for s in sizes], append_images=icons[1:])
    print(f"Ícone criado com sucesso: {dst}")


if __name__ == "__main__":
    make_ico()
