"""Membuat assets/modern_farm/16x16/autotiles/Soil_Edges_16x16.png dari tile ASLI 1_Terrains_16x16.png.

Di asset Modern Farm, petak tanah 1 tile (1_Terrains, kolom 8-10 baris 12-14) terdiri dari tile tanah
penuh di tengah + rumbai rumput/tanah yang menjorok ke 8 tile rumput di sekitarnya. Script ini mengambil
piksel rumbai itu saja (piksel yang berbeda dari tile rumput polos 3,2 -> sisanya transparan), lalu
menggabungkannya untuk semua 256 kombinasi tetangga. Hasil: atlas 16x16 tile, tile (m % 16, m / 16)
= rumbai untuk tile rumput yang punya tanah di arah mask m
(bit: N=1, NE=2, E=4, SE=8, S=16, SW=32, W=64, NW=128 - sama dengan TerrainTiles.NEIGHBORS).

Pakai (dari folder project):
    python3 tools/make_soil_edges.py          -> tanah cokelat muda (pusat 9,17)  [dipakai sekarang]
    python3 tools/make_soil_edges.py 9 13     -> tanah cokelat kemerahan (pusat 9,13)
Jika pusat diganti, samakan juga TerrainTiles.SOIL_COORD.
"""
import sys
from PIL import Image

TERRAINS = "assets/modern_farm/16x16/terrains/1_Terrains_16x16.png"
OUT = "assets/modern_farm/16x16/autotiles/Soil_Edges_16x16.png"
GRASS = (3, 2)
# pusat petak tanah 1 tile di 1_Terrains (default: tanah cokelat muda, baris 16-18)
CX, CY = (int(sys.argv[1]), int(sys.argv[2])) if len(sys.argv) >= 3 else (9, 17)
# arah tanah (dilihat dari tile rumput, urutan N NE E SE S SW W NW) -> tile rumbai di sisi sebaliknya
PIECES = [(CX, CY + 1), (CX - 1, CY + 1), (CX - 1, CY), (CX - 1, CY - 1),
          (CX, CY - 1), (CX + 1, CY - 1), (CX + 1, CY), (CX + 1, CY + 1)]

t = Image.open(TERRAINS).convert("RGBA")
grass = t.crop((GRASS[0] * 16, GRASS[1] * 16, GRASS[0] * 16 + 16, GRASS[1] * 16 + 16))


def fringe(tile):
    img = t.crop((tile[0] * 16, tile[1] * 16, tile[0] * 16 + 16, tile[1] * 16 + 16))
    px, gp = img.load(), grass.load()
    for y in range(16):
        for x in range(16):
            if px[x, y] == gp[x, y]:
                px[x, y] = (0, 0, 0, 0)
    return img


pieces = [fringe(p) for p in PIECES]
sheet = Image.new("RGBA", (256, 256))
for mask in range(256):
    tile = Image.new("RGBA", (16, 16))
    for bit in range(8):
        if mask & (1 << bit):
            tile.alpha_composite(pieces[bit])
    sheet.paste(tile, ((mask % 16) * 16, (mask // 16) * 16))
sheet.save(OUT)
print("saved", OUT)
