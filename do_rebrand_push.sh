#!/usr/bin/env bash
cd /a0/usr/workdir/cooc
log=/a0/usr/workdir/cooc/rebrand_push.log
echo "[$(date)] START" >> $log
# 1 strings
find apps/multiplatform/android/src/main/res -name 'strings.xml' -exec sed -i 's/SimpleX Chat/COOC/g; s/SimpleX/COOC/g' {} + 2>/dev/null
echo STRINGS_DONE >> $log
# 2 logo
for f in $(find apps/multiplatform/android/src/main/res/mipmap* -name '*.png'); do cp /a0/usr/workdir/cooc-logo.png "$f" 2>/dev/null; done
echo LOGO_DONE >> $log
# 3 presets .onion
sed -i 's#"smp://8Af90NX2TTkKEJAF1RCg69P_Odg2Z-6_J6DOKUqK3rQ=@smp7.simplex.im,dbxqutskmmbkbrs7ofi7pmopeyhgi5cxbjbh4ummgmep4r6bz4cbrcid.onion"#"smp://8Af90NX2TTkKEJAF1RCg69P_Odg2Z-6_J6DOKUqK3rQ=@smp7.simplex.im,dbxqutskmmbkbrs7ofi7pmopeyhgi5cxbjbh4ummgmep4r6bz4cbrcid.onion",
  "smp://pY0NwwHrzS2dZwpnNdC1bmfGh5a85yA563mLV8XUjQc=@5qke7ycslppw3pl723wgsd3oyjsw445msvzk6ouhgar7ameucqrlpdqd.onion:5223"#' src/Simplex/Chat/Operators/Presets.hs
echo PRESETS_DONE >> $log
# 4 workflow (public cachix, no token needed)
cat > .github/workflows/android-apk.yml <<'YML'
name: COOC Android APK
on:
  push:
    branches: [ main ]
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Nix
        uses: cachix/install-nix-action@v27
        with:
          nix_path: nixpkgs=channel:nixos-24.05
          extra_nix_config: |
            substituters = https://simplex-chat.cachix.org https://cache.nixos.org
            trusted-public-keys = simplex-chat.cachix.org-1:ySS7A1KSl1uVbVO1hvYy32JZz9o/XX5Xz/j8Hdb8V8= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - name: Set up Android SDK
        uses: android-actions/setup-android@v3
      - name: Build APK (aarch64)
        env:
          ARCHES: aarch64
        run: ./scripts/android/build-android.sh 1
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: cooc-android-apk
          path: '**/*.apk'
YML
echo WORKFLOW_DONE >> $log
# 5 commit
git add -A
git -c user.email=agent@cooc -c user.name=agent commit -m 'COOC rebrand: name, logo, green, baked .onion + cachix CI' >> $log 2>&1
echo COMMIT_DONE >> $log
# 6 push
git remote set-url origin https://${TOKEN}@github.com/libbi3605/cooc.git 2>>$log
nohup setsid bash -c 'cd /a0/usr/workdir/cooc && git push origin main --force' >> $log 2>&1 &
echo PUSH_LAUNCHED >> $log
