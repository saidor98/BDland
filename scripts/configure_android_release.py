import os
import subprocess
import re
import zlib
import struct
import math

def generate_png_icon(size):
    """Generate a high-resolution BDLandPro Cadastral Survey app icon in pure Python."""
    header = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)
    ihdr = struct.pack('>I', len(ihdr_data)) + b'IHDR' + ihdr_data + struct.pack('>I', zlib.crc32(b'IHDR' + ihdr_data))
    
    half = size / 2.0
    r_outer = half * 0.95
    r_gold_rim = half * 0.88
    r_inner = half * 0.82
    
    rows = []
    for y in range(size):
        row = [0]  # PNG filter byte 0 (None)
        for x in range(size):
            dx = x - half
            dy = y - half
            dist = math.sqrt(dx * dx + dy * dy)
            
            # Anti-aliased / crisp circle
            if dist > r_outer:
                # Transparent/Dark edge
                row.extend([10, 46, 28])
            elif dist > r_gold_rim:
                # Luxurious Gold Outer Ring (#C29015)
                row.extend([194, 144, 21])
            elif dist > r_inner:
                # Light Gold Accent Ring (#FBBF24)
                row.extend([251, 191, 36])
            else:
                # Rich Emerald Green Cadastral Field (#0F3A22)
                # Cadastral grid lines
                cell = max(6, size // 6)
                is_grid = (x % cell < 2) or (y % cell < 2)
                # Surveyor Gunia scale / diagonal traverse
                is_diag = abs(dx - dy) < max(2, size // 30)
                # Center compass star
                is_star = (abs(dx) < 2 and abs(dy) < half * 0.4) or (abs(dy) < 2 and abs(dx) < half * 0.4)

                if is_star or is_diag:
                    row.extend([251, 191, 36])  # Vibrant Amber/Gold surveyor mark
                elif is_grid:
                    row.extend([22, 101, 52])   # Light Cadastral boundary line
                else:
                    row.extend([15, 58, 34])    # Deep Emerald green land
        rows.append(bytes(row))
        
    raw = b''.join(rows)
    comp = zlib.compress(raw, level=9)
    idat = struct.pack('>I', len(comp)) + b'IDAT' + comp + struct.pack('>I', zlib.crc32(b'IDAT' + comp))
    iend = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', zlib.crc32(b'IEND'))
    return header + ihdr + idat + iend

def install_launcher_icons():
    """Install custom BDLandPro launcher icons for all Android densities."""
    densities = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    res_dir = os.path.join("android", "app", "src", "main", "res")
    for folder, size in densities.items():
        target_dir = os.path.join(res_dir, folder)
        os.makedirs(target_dir, exist_ok=True)
        png_data = generate_png_icon(size)
        
        # Save both standard and round icons
        for icon_name in ['ic_launcher.png', 'ic_launcher_round.png']:
            icon_path = os.path.join(target_dir, icon_name)
            with open(icon_path, 'wb') as f:
                f.write(png_data)
        print(f"Generated {size}x{size} launcher icon in {folder}")

def main():
    print("=== Configuring Android Release Signing & Branding ===")
    
    # 1. Install Custom BDLandPro Launcher Icons
    install_launcher_icons()
    
    # 2. Generate Release Keystore
    keystore_path = os.path.join("android", "app", "bdland_release.jks")
    if not os.path.exists(keystore_path):
        os.makedirs(os.path.dirname(keystore_path), exist_ok=True)
        cmd = [
            "keytool", "-genkeypair", "-v",
            "-keystore", keystore_path,
            "-alias", "bdlandpro",
            "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000",
            "-storepass", "bdlandrelease2026",
            "-keypass", "bdlandrelease2026",
            "-dname", "CN=BDLandPro, OU=Engineering, O=BDLand, L=Dhaka, ST=Dhaka, C=BD"
        ]
        subprocess.run(cmd, check=True)
        print(f"Generated release keystore at {keystore_path}")

    # 3. Patch AndroidManifest.xml
    manifest_path = os.path.join("android", "app", "src", "main", "AndroidManifest.xml")
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r', encoding='utf-8') as f:
            content = f.read()
        permissions = (
            "    <uses-permission android:name=\"android.permission.INTERNET\"/>\n"
            "    <uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\"/>\n"
            "    <uses-permission android:name=\"android.permission.ACCESS_COARSE_LOCATION\"/>\n"
            "    <uses-permission android:name=\"android.permission.READ_EXTERNAL_STORAGE\" android:maxSdkVersion=\"32\"/>\n"
            "    <uses-permission android:name=\"android.permission.WRITE_EXTERNAL_STORAGE\" android:maxSdkVersion=\"29\"/>\n"
        )
        if "<uses-permission" not in content:
            content = content.replace("<application", permissions + "    <application", 1)
        
        # Proper application attributes
        content = re.sub(r'android:label="[^"]*"', 'android:label="বিডি ল্যান্ড প্রো (BDLandPro)"', content)
        if 'android:icon=' not in content:
            content = content.replace("<application", '<application android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher_round"', 1)
        else:
            content = re.sub(r'android:icon="[^"]*"', 'android:icon="@mipmap/ic_launcher"', content)
            if 'android:roundIcon=' not in content:
                content = content.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher_round"')
            else:
                content = re.sub(r'android:roundIcon="[^"]*"', 'android:roundIcon="@mipmap/ic_launcher_round"', content)
        
        with open(manifest_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Patched AndroidManifest.xml successfully.")

    # 4. Patch build.gradle (Groovy)
    gradle_file = os.path.join("android", "app", "build.gradle")
    if os.path.exists(gradle_file):
        with open(gradle_file, 'r', encoding='utf-8') as f:
            content = f.read()
        groovy_release = (
            "    signingConfigs {\n"
            "        release {\n"
            "            storeFile file(\"bdland_release.jks\")\n"
            "            storePassword \"bdlandrelease2026\"\n"
            "            keyAlias \"bdlandpro\"\n"
            "            keyPassword \"bdlandrelease2026\"\n"
            "            v1SigningEnabled true\n"
            "            v2SigningEnabled true\n"
            "        }\n"
            "    }\n"
        )
        if "signingConfigs {" in content:
            content = re.sub(
                r'signingConfigs\s*\{',
                'signingConfigs {\n        release {\n            storeFile file("bdland_release.jks")\n            storePassword "bdlandrelease2026"\n            keyAlias "bdlandpro"\n            keyPassword "bdlandrelease2026"\n            v1SigningEnabled true\n            v2SigningEnabled true\n        }',
                content
            )
        elif "buildTypes {" in content:
            content = content.replace("buildTypes {", groovy_release + "\n    buildTypes {", 1)

        content = content.replace("signingConfig = signingConfigs.debug", "signingConfig = signingConfigs.release")
        content = content.replace("signingConfig signingConfigs.debug", "signingConfig signingConfigs.release")
        with open(gradle_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Patched build.gradle (Groovy) successfully.")

    # 5. Patch build.gradle.kts (Kotlin DSL)
    kts_file = os.path.join("android", "app", "build.gradle.kts")
    if os.path.exists(kts_file):
        with open(kts_file, 'r', encoding='utf-8') as f:
            content = f.read()
        kts_release = (
            "    signingConfigs {\n"
            "        create(\"release\") {\n"
            "            storeFile = file(\"bdland_release.jks\")\n"
            "            storePassword = \"bdlandrelease2026\"\n"
            "            keyAlias = \"bdlandpro\"\n"
            "            keyPassword = \"bdlandrelease2026\"\n"
            "            enableV1Signing = true\n"
            "            enableV2Signing = true\n"
            "        }\n"
            "    }\n"
        )
        if "signingConfigs {" in content:
            content = re.sub(
                r'signingConfigs\s*\{',
                'signingConfigs {\n        create("release") {\n            storeFile = file("bdland_release.jks")\n            storePassword = "bdlandrelease2026"\n            keyAlias = "bdlandpro"\n            keyPassword = "bdlandrelease2026"\n            enableV1Signing = true\n            enableV2Signing = true\n        }',
                content
            )
        elif "buildTypes {" in content:
            content = content.replace("buildTypes {", kts_release + "\n    buildTypes {", 1)

        content = content.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
        content = content.replace('signingConfig = signingConfigs.debug', 'signingConfig = signingConfigs.getByName("release")')
        with open(kts_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Patched build.gradle.kts (Kotlin DSL) successfully.")

if __name__ == "__main__":
    main()
