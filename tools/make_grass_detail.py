"""Phase 21: membuat atlas detail rumput (assets/modern_farm/tilesets/grass_detail_16x16.png).
Warna diambil dari palet rumput Modern Farm (1_Terrains + Grass_Tufts). Baris atlas:
 0 = jarang (1-2 rumpun), 1 = sedang, 2 = lebat gelap (dasar bertitik + banyak bilah),
 3 = terang (bilah ujung terang), 4 = bunga kecil, 5 = rumpun tinggi,
 6 = detail jalan tanah (kerikil samar + tunas rumput kecil, hanya di setengah bawah tile agar tidak ikut bergoyang).
Setiap baris 8 variasi. Jalankan: python3 tools/make_grass_detail.py
"""
import random
from PIL import Image

BASE = (71, 151, 87)
D1 = (55, 133, 78)
D2 = (42, 116, 76)
D3 = (36, 102, 70)
L1 = (86, 168, 92)
L2 = (104, 184, 98)
L3 = (130, 200, 108)
FLOWERS = [(240, 236, 222), (250, 214, 92), (242, 150, 172), (170, 190, 250)]
T = 16
COLS, ROWS = 8, 7


def put(img, x, y, c):
    if 0 <= x < T and 0 <= y < T:
        img.putpixel((x, y), c + (255,))


def blade(img, x, y, h, lean, cols):
    """Bilah dari (x,y) = pangkal ke atas setinggi h. cols = [pangkal, tengah, ujung]."""
    for i in range(h):
        k = i / max(h - 1, 1)
        c = cols[0] if k < 0.34 else (cols[1] if k < 0.7 else cols[2])
        put(img, x + round(lean * i / max(h - 1, 1)), y - i, c)


def clump(img, rnd, cx, by, n, hmin, hmax, cols):
    for j in range(n):
        x = cx + rnd.randint(-2, 2)
        h = rnd.randint(hmin, hmax)
        lean = rnd.choice([-1, 0, 0, 1]) if h > 2 else 0
        blade(img, x, by, h, lean, cols)


def tile(row, var):
    rnd = random.Random(row * 100 + var * 7 + 3)
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    dark = [D2, D1, D1]
    lite = [D1, L1, L2]
    if row == 0:
        for _ in range(rnd.randint(1, 2)):
            clump(img, rnd, rnd.randint(4, 11), rnd.randint(7, 14), rnd.randint(2, 3), 2, 3, dark)
    elif row == 1:
        for _ in range(rnd.randint(3, 4)):
            clump(img, rnd, rnd.randint(3, 12), rnd.randint(5, 15), rnd.randint(2, 4), 2, 4, rnd.choice([dark, dark, lite]))
    elif row == 2:
        # dasar lebat: banyak goresan bilah pendek (bukan titik acak) agar terlihat seperti rumput rapat
        for _ in range(34):
            x, y = rnd.randint(0, T - 1), rnd.randint(1, T - 1)
            h = rnd.randint(2, 3)
            for i in range(h):
                put(img, x, y - i, D2 if i == 0 else D1)
        for _ in range(rnd.randint(4, 6)):
            clump(img, rnd, rnd.randint(2, 13), rnd.randint(4, 15), rnd.randint(2, 4), 2, 4, [D3, D2, D1])
    elif row == 3:
        for _ in range(10):
            x, y = rnd.randint(1, T - 2), rnd.randint(2, T - 1)
            put(img, x, y, L1); put(img, x, y - 1, L2)
        for _ in range(rnd.randint(3, 5)):
            clump(img, rnd, rnd.randint(3, 12), rnd.randint(5, 15), rnd.randint(2, 3), 2, 4, [L1, L2, L3])
    elif row == 4:
        for _ in range(rnd.randint(2, 3)):
            cx, by = rnd.randint(3, 12), rnd.randint(7, 14)
            clump(img, rnd, cx, by, rnd.randint(2, 3), 2, 4, dark)
            fc = rnd.choice(FLOWERS)
            fx, fy = cx + rnd.randint(-1, 1), by - rnd.randint(3, 5)
            put(img, fx, fy, fc)
            if rnd.random() < 0.5:
                put(img, fx + 1, fy, fc); put(img, fx, fy - 1, fc)
                put(img, fx - 1, fy, fc); put(img, fx, fy + 1, fc)
                put(img, fx, fy, (250, 214, 92) if fc != (250, 214, 92) else (240, 160, 60))
    elif row == 5:
        cx, by = rnd.randint(5, 10), rnd.randint(13, 15)
        for j in range(rnd.randint(5, 7)):
            x = cx + rnd.randint(-3, 3)
            h = rnd.randint(5, 9)
            blade(img, x, by - rnd.randint(0, 1), h, rnd.choice([-2, -1, 0, 1, 2]), [D2, D1, L2])
    elif row == 6:
        PL, PD = (186, 158, 104), (148, 122, 78)
        for _ in range(rnd.randint(1, 3)):
            x, y = rnd.randint(2, 13), rnd.randint(10, 14)
            put(img, x, y, PL); put(img, x + 1, y, PL)
            put(img, x, y + 1, PD); put(img, x + 1, y + 1, PD)
        for _ in range(rnd.randint(0, 2)):
            put(img, rnd.randint(1, 14), rnd.randint(9, 15), PD)
        if rnd.random() < 0.35:
            x, y = rnd.randint(3, 12), rnd.randint(13, 15)
            put(img, x, y, D1); put(img, x - 1, y - 1, D1); put(img, x + 1, y - 1, L1)
    return img


def main():
    atlas = Image.new("RGBA", (COLS * T, ROWS * T), (0, 0, 0, 0))
    for r in range(ROWS):
        for c in range(COLS):
            atlas.paste(tile(r, c), (c * T, r * T))
    atlas.save("assets/modern_farm/tilesets/grass_detail_16x16.png")
    print("ok", atlas.size)


if __name__ == "__main__":
    main()
