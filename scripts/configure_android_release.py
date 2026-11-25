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

if __name__ == "__main__":
    main()
