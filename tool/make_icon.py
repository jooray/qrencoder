#!/usr/bin/env python3
"""Draw the QREncoder app icon: a QR glyph in ink, newsprint and one acid accent.

Usage: python3 tool/make_icon.py <out-dir>
Writes icon-square.svg (full bleed) and icon-macos.svg (squircle mask) plus PNGs.
"""

import subprocess
import sys

INK = "#111110"
NEWS = "#F5F3EE"
ACCENT = "#D8FF3E"

N = 9          # module grid
M = 96         # module size at 1024
S = N * M      # 864
O = (1024 - S) // 2  # 80


def ring(grid, r, c):
    for dr in range(3):
        for dc in range(3):
            if dr == 1 and dc == 1:
                continue
            grid[r + dr][c + dc] = 1


def build():
    g = [[0] * N for _ in range(N)]
    ring(g, 0, 0)
    ring(g, 0, 6)
    ring(g, 6, 0)
    # data modules, placed for balance at 16 px rather than for scannability
    for r, c in [
        (4, 0), (4, 1), (4, 2),
        (5, 4), (5, 5),
        (6, 4), (6, 7),
        (7, 5), (7, 6), (7, 8),
        (8, 4), (8, 5), (8, 7),
    ]:
        g[r][c] = 1
    return g


def svg(ground, body, accent_modules, radius=None):
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">']
    if radius:
        out.append(f'<rect width="1024" height="1024" rx="{radius}" ry="{radius}" fill="{ground}"/>')
    else:
        out.append(f'<rect width="1024" height="1024" fill="{ground}"/>')
    for r in range(N):
        for c in range(N):
            if not body[r][c]:
                continue
            fill = accent_modules(r, c)
            out.append(
                f'<rect x="{O + c * M}" y="{O + r * M}" width="{M}" height="{M}" fill="{fill}"/>'
            )
    out.append("</svg>")
    return "".join(out)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    g = build()

    def colours(r, c):
        # the top-right finder carries the accent; everything else is newsprint
        return ACCENT if (r < 3 and c >= 6) else NEWS

    square = svg(INK, g, colours)
    macos = svg(INK, g, colours, radius=200)
    open(f"{out}/icon-square.svg", "w").write(square)
    open(f"{out}/icon-macos.svg", "w").write(macos)

    for name, src in (("icon-square.png", square), ("icon-macos.png", macos)):
        open(f"{out}/tmp.svg", "w").write(src)
        subprocess.run(
            ["magick", "-background", "none", f"{out}/tmp.svg", "-resize", "1024x1024", f"{out}/{name}"],
            check=True,
        )
    subprocess.run(["rm", "-f", f"{out}/tmp.svg"], check=True)
    print("wrote", out)


if __name__ == "__main__":
    main()
