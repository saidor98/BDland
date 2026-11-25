import os
import subprocess
import re

def main():
    print("=== Configuring Android Release Signing ===")
    
    # 1. Generate Keystore
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

    # 2. Patch AndroidManifest.xml
    manifest_path = os.path.join("android", "app", "src", "main", "AndroidManifest.xml")
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r', encoding='utf-8') as f:
            content = f.read()
        permissions = (
            "    <uses-permission android:name=\"android.permission.INTERNET\"/>\n"
            "    <uses-permission android:name=\"android.permission.ACCESS_FINE_LOCATION\"/>\n"
            "    <uses-permission android:name=\"android.permission.ACCESS_COARSE_LOCATION\"/>\n"
            "    <uses-permission android:name=\"android.permission.READ_MEDIA_IMAGES\"/>\n"
        )
        if "<uses-permission" not in content:
            content = content.replace("<application", permissions + "    <application", 1)
        if 'android:largeHeap=' not in content:
            content = content.replace("<application", '<application\n        android:largeHeap="true"', 1)
        content = re.sub(r'android:label="[^"]*"', 'android:label="বিডি ল্যান্ড প্রো (BDLandPro)"', content)
        with open(manifest_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Patched AndroidManifest.xml successfully.")

    # 3. Patch build.gradle (Groovy)
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

    # 4. Patch build.gradle.kts (Kotlin DSL)
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
                'signingConfigs {\n        create("release") {\n            storeFile = file("bdland_release.jks")\n            storePassword "bdlandrelease2026"\n            keyAlias "bdlandpro"\n            keyPassword "bdlandrelease2026"\n            enableV1Signing = true\n            enableV2Signing = true\n        }',
                content
            )
        elif "buildTypes {" in content:
            content = content.replace("buildTypes {", kts_release + "\n    buildTypes {", 1)

        content = content.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
        content = content.replace('signingConfig = signingConfigs.debug', 'signingConfig = signingConfigs.getByName("release")')
        with open(kts_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Patched build.gradle.kts (Kotlin DSL) successfully.")

    # 5. Enforce compileSdk >= 36 on Android library subprojects (e.g. plugins pinned to SDK 34)
    root_kts = os.path.join("android", "build.gradle.kts")
    if os.path.exists(root_kts):
        with open(root_kts, 'r', encoding='utf-8') as f:
            rk_content = f.read()
        if "LibraryExtension" not in rk_content:
            sdk_guard = (
                "subprojects {\n"
                "    afterEvaluate {\n"
                "        if (plugins.hasPlugin(\"com.android.library\")) {\n"
                "            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {\n"
                "                if ((compileSdk ?: 0) < 36) {\n"
                "                    compileSdk = 36\n"
                "                }\n"
                "            }\n"
                "        }\n"
                "    }\n"
                "}\n\n"
            )
            anchor = "subprojects {\n    project.evaluationDependsOn(\":app\")"
            if anchor in rk_content:
                rk_content = rk_content.replace(anchor, sdk_guard + anchor, 1)
            else:
                rk_content += "\n" + sdk_guard
            with open(root_kts, 'w', encoding='utf-8') as f:
                f.write(rk_content)
            print("Patched android/build.gradle.kts to enforce compileSdk >= 36 on library subprojects.")

    root_groovy = os.path.join("android", "build.gradle")
    if os.path.exists(root_groovy):
        with open(root_groovy, 'r', encoding='utf-8') as f:
            rg_content = f.read()
        if "compileSdkVersion 36" not in rg_content:
            sdk_guard_groovy = (
                "subprojects {\n"
                "    afterEvaluate { project ->\n"
                "        if (project.plugins.hasPlugin('com.android.library') && project.hasProperty('android')) {\n"
                "            project.android {\n"
                "                compileSdkVersion 36\n"
                "            }\n"
                "        }\n"
                "    }\n"
                "}\n\n"
            )
            anchor_g = "subprojects {\n    project.evaluationDependsOn(':app')"
            if anchor_g in rg_content:
                rg_content = rg_content.replace(anchor_g, sdk_guard_groovy + anchor_g, 1)
            else:
                rg_content += "\n" + sdk_guard_groovy
            with open(root_groovy, 'w', encoding='utf-8') as f:
                f.write(rg_content)
            print("Patched android/build.gradle to enforce compileSdk >= 36 on library subprojects.")

    # 6. Install BDLandPro Launcher Icons & Adaptive Icon (replacing default Flutter logo)
    import shutil
    res_dir = os.path.join("android", "app", "src", "main", "res")
    icon_src_root = os.path.join("assets", "icons")
    if os.path.exists(res_dir) and os.path.exists(icon_src_root):
        for density in ["mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi"]:
            src_d = os.path.join(icon_src_root, density)
            dst_d = os.path.join(res_dir, density)
            if os.path.exists(src_d):
                os.makedirs(dst_d, exist_ok=True)
                for fname in os.listdir(src_d):
                    shutil.copy2(os.path.join(src_d, fname), os.path.join(dst_d, fname))

        anydpi_dir = os.path.join(res_dir, "mipmap-anydpi-v26")
        values_dir = os.path.join(res_dir, "values")
        os.makedirs(anydpi_dir, exist_ok=True)
        os.makedirs(values_dir, exist_ok=True)

        bg_xml = '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#004126</color>\n</resources>\n'
        with open(os.path.join(values_dir, "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
            f.write(bg_xml)

        adaptive_xml = (
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n'
        )
        for icon_xml in ["ic_launcher.xml", "ic_launcher_round.xml"]:
            with open(os.path.join(anydpi_dir, icon_xml), "w", encoding="utf-8") as f:
                f.write(adaptive_xml)
        print("Installed BDLandPro custom launcher & adaptive icons cleanly.")

if __name__ == "__main__":
    main()
