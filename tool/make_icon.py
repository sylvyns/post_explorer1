"""Рисует иконку Post Explorer: стопка карточек-постов + лупа (поиск).

Выход (в папку, переданную аргументом):
  app_icon.png             — 1024x1024, полный значок (фон + рисунок), без прозрачности
  app_icon_foreground.png  — 1024x1024, только рисунок на прозрачном фоне (Adaptive Icon)
  app_icon_background.png  — 1024x1024, только фон-градиент (Adaptive Icon)
  app_icon_monochrome.png  — 1024x1024, белый силуэт (тематический значок Android 13+)
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

SIZE = 1024
SS = 4  # суперсэмплинг для гладких краёв
W = SIZE * SS

INDIGO_LIGHT = (92, 107, 192)  # #5C6BC0
INDIGO_DARK = (40, 53, 147)  # #283593
LINE = (197, 202, 233)  # #C5CAE9
AVATAR = (121, 134, 203)  # #7986CB
AMBER = (255, 193, 7)  # #FFC107
AMBER_DARK = (255, 143, 0)  # #FF8F00


def gradient_bg() -> Image.Image:
    """Диагональный градиент индиго (как colorSchemeSeed в приложении)."""
    small = Image.new("RGB", (256, 256))
    px = small.load()
    for y in range(256):
        for x in range(256):
            t = (x + y) / 510
            px[x, y] = tuple(
                round(a + (b - a) * t) for a, b in zip(INDIGO_LIGHT, INDIGO_DARK)
            )
    return small.resize((W, W), Image.BICUBIC).convert("RGBA")


def s(v):
    return round(v * SS)


def rrect(draw, box, r, fill):
    draw.rounded_rectangle([s(c) for c in box], radius=s(r), fill=fill)


def draw_artwork(scale: float, mono: bool) -> Image.Image:
    """Рисунок на прозрачном фоне. scale<1 — уменьшить к центру (для adaptive)."""
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))

    def t(x, y):  # масштабирование относительно центра
        return 512 + (x - 512) * scale, 512 + (y - 512) * scale

    def tb(x0, y0, x1, y1):
        a, b = t(x0, y0)
        c, d = t(x1, y1)
        return (a, b, c, d)

    white = (255, 255, 255, 255)
    clear = (0, 0, 0, 0)

    # --- задняя карточка (лента постов) ---
    back = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    rrect(ImageDraw.Draw(back), tb(300, 170, 790, 600), 56 * scale,
          (255, 255, 255, 255 if mono else 165))
    if mono:  # в монохроме полупрозрачность не работает — делаем зазор
        gap = Image.new("L", (W, W), 0)
        rrect(ImageDraw.Draw(gap), tb(200, 236, 724, 724), 72 * scale, 255)
        back.putalpha(ImageChops.subtract(back.getchannel("A"), gap))
    layer = Image.alpha_composite(layer, back)

    # --- передняя карточка-пост ---
    card = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(card)
    rrect(d, tb(230, 260, 700, 700), 56 * scale, white)
    ink = clear if mono else None
    # аватар + имя автора
    ax, ay = t(320, 350)
    d.ellipse([s(ax - 44 * scale), s(ay - 44 * scale),
               s(ax + 44 * scale), s(ay + 44 * scale)], fill=ink or AVATAR)
    rrect(d, tb(390, 322, 620, 350), 14 * scale, ink or AVATAR)
    rrect(d, tb(390, 364, 540, 386), 11 * scale, ink or LINE)
    # строки текста поста
    for y, x1 in ((450, 620), (510, 620), (570, 520)):
        rrect(d, tb(280, y, x1, y + 30), 15 * scale, ink or LINE)
    layer = Image.alpha_composite(layer, card)

    # --- лупа ---
    cx, cy = t(640, 630)
    R = 150 * scale  # радиус кольца (по центру обводки)
    ring_w = 50 * scale
    gap = 26 * scale  # зазор между лупой и карточкой
    hx0, hy0 = cx + (R + ring_w / 2 - 6 * scale) * 0.7071, cy + (R + ring_w / 2 - 6 * scale) * 0.7071
    hx1, hy1 = t(870, 860)
    handle_w = 76 * scale

    def magnifier_mask(extra: float, with_lens: bool) -> Image.Image:
        m = Image.new("L", (W, W), 0)
        md = ImageDraw.Draw(m)
        ro = R + ring_w / 2 + extra
        md.ellipse([s(cx - ro), s(cy - ro), s(cx + ro), s(cy + ro)], fill=255)
        if not with_lens:
            ri = R - ring_w / 2  # внутри линзы зазор не нужен
            md.ellipse([s(cx - ri), s(cy - ri), s(cx + ri), s(cy + ri)], fill=0)
        hw = handle_w + 2 * extra
        md.line([s(hx0), s(hy0), s(hx1), s(hy1)], fill=255, width=s(hw))
        for px, py in ((hx0, hy0), (hx1, hy1)):
            md.ellipse([s(px - hw / 2), s(py - hw / 2), s(px + hw / 2), s(py + hw / 2)], fill=255)
        return m

    # вырезаем зазор вокруг лупы
    knock = magnifier_mask(gap, with_lens=False)
    layer.putalpha(ImageChops.subtract(layer.getchannel("A"), knock))

    mag = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    md = ImageDraw.Draw(mag)
    if not mono:  # стекло
        ri = R - ring_w / 2
        md.ellipse([s(cx - ri), s(cy - ri), s(cx + ri), s(cy + ri)], fill=(255, 255, 255, 60))
        # блик
        md.arc([s(cx - ri * 0.72), s(cy - ri * 0.72), s(cx + ri * 0.72), s(cy + ri * 0.72)],
               start=200, end=250, fill=(255, 255, 255, 200), width=s(16 * scale))
    # ручка
    handle_col = white if mono else AMBER_DARK
    md.line([s(hx0), s(hy0), s(hx1), s(hy1)], fill=handle_col, width=s(handle_w))
    md.ellipse([s(hx1 - handle_w / 2), s(hy1 - handle_w / 2),
                s(hx1 + handle_w / 2), s(hy1 + handle_w / 2)], fill=handle_col)
    # кольцо
    ro = R + ring_w / 2
    md.ellipse([s(cx - ro), s(cy - ro), s(cx + ro), s(cy + ro)],
               outline=white if mono else AMBER, width=s(ring_w))
    layer = Image.alpha_composite(layer, mag)
    return layer


def shift_to_center(img: Image.Image) -> Image.Image:
    """Ставит рисунок по центру холста по его габаритам."""
    bbox = img.getchannel("A").getbbox()
    dx = (W - (bbox[0] + bbox[2])) // 2
    dy = (W - (bbox[1] + bbox[3])) // 2
    out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    out.alpha_composite(img, dest=(max(dx, 0), max(dy, 0)),
                        source=(max(-dx, 0), max(-dy, 0)))
    return out


def down(img):
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main(out_dir: Path):
    out_dir.mkdir(parents=True, exist_ok=True)
    bg = gradient_bg()

    full = Image.alpha_composite(bg, shift_to_center(draw_artwork(1.06, mono=False)))
    down(full).convert("RGB").save(out_dir / "app_icon.png")

    # Для adaptive: пакет сам добавляет отступ 16% (adaptive_icon_foreground_inset),
    # поэтому рисунок занимает почти весь холст, но остаётся в безопасной зоне.
    down(shift_to_center(draw_artwork(1.0, mono=False))).save(out_dir / "app_icon_foreground.png")
    down(bg).convert("RGB").save(out_dir / "app_icon_background.png")
    down(shift_to_center(draw_artwork(1.0, mono=True))).save(out_dir / "app_icon_monochrome.png")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
