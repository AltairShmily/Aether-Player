# Icon Source

原始图标文件：`Aether-Player.png`

## 各平台图标

| 平台 | 文件 | 说明 |
|------|------|------|
| Android | `android/ic_launcher.png` | xxxhdpi (192×192) |
| Android | `android/ic_launcher_foreground.png` | Adaptive icon foreground (432×432) |
| Android | `android/ic_launcher_round.png` | Round icon |
| iOS | `ios/AppIcon.png` | 1024×1024 Marketing icon |
| macOS | `macos/AppIcon.png` | 512×512 |
| Windows | `windows/app_icon.ico` | Multi-size ICO |
| Windows | `windows/app_icon.png` | 256×256 |
| Linux | `linux/app_icon.png` | 512×512 |

## 重新生成图标

替换 `Aether-Player.png` 后，在项目根目录运行：

```bash
cd Aether-Player
python3 << 'EOF'
from PIL import Image
import struct, io, os

src = 'icon/Aether-Player.png'
img = Image.open(src).convert("RGBA")

def resize(image, size):
    return image.resize((size, size), Image.LANCZOS)

# Android
for folder, size in [("mipmap-mdpi",48),("mipmap-hdpi",72),("mipmap-xhdpi",96),("mipmap-xxhdpi",144),("mipmap-xxxhdpi",192)]:
    resize(img, size).save(f"app/android/app/src/main/res/{folder}/ic_launcher.png", "PNG")
resize(img, 432).save("app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png", "PNG")
resize(img, 192).save("app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png", "PNG")

# iOS
ios_dir = "app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
for s in [20,29,40,58,60,76,80,87,120,152,167,180,1024]:
    resize(img, s).save(f"{ios_dir}/icon_{s}x{s}.png", "PNG")
for s in [20,29,40,60,76]:
    for m, suf in [(2,"@2x"),(3,"@3x")]:
        resize(img, s*m).save(f"{ios_dir}/icon_{s}x{s}{suf}.png", "PNG")

# macOS
mac_dir = "app/macos/Runner/Assets.xcassets/AppIcon.appiconset"
for s in [16,32,128,256,512,1024]:
    resize(img, s).save(f"{mac_dir}/icon_{s}x{s}.png", "PNG")
    resize(img, s*2).save(f"{mac_dir}/icon_{s}x{s}@2x.png", "PNG")

# Windows ICO
sizes = [16, 32, 48, 256]
png_data = [io.BytesIO() for _ in sizes]
for i, s in enumerate(sizes):
    resize(img, s).save(png_data[i], format="PNG")
header = struct.pack("<HHH", 0, 1, len(sizes))
entries = b""
off = 6 + len(sizes) * 16
for s, buf in zip(sizes, png_data):
    d = buf.getvalue()
    entries += struct.pack("<BBBBHHII", s if s<256 else 0, s if s<256 else 0, 0, 0, 1, 32, len(d), off)
    off += len(d)
with open("app/windows/runner/resources/app_icon.ico", "wb") as f:
    f.write(header + entries)
    for buf in png_data:
        f.write(buf.getvalue())
resize(img, 256).save("app/windows/runner/resources/app_icon.png", "PNG")

# Linux
resize(img, 512).save("app/linux/app_icon.png", "PNG")

print("All icons regenerated!")
EOF
```
