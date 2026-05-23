# f/Room セットアップガイド

このドキュメントは、Jetty さんがローカル環境で f/Room を動かすまでの手順を詳しく説明します。

## 前提

- **macOS**（最新版推奨）
- **Xcode 15以上**（App Store からインストール）
- **Python 3.11以上**（`brew install python` または python.org から）
- **Git**（最新版）

## 1. アプリを Xcode で開く

### 1-1. 新規 Xcode プロジェクト作成

1. Xcode を起動 → **Create New Project**
2. **iOS → App** を選択 → Next
3. 入力:
   - **Product Name**: `FRoom`
   - **Team**: 任意（Personal でもOK）
   - **Organization Identifier**: `com.yourname` のようなドメイン
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Use Core Data**: チェックなし
   - **Include Tests**: チェックあり（推奨）
4. **Next** → 保存場所を `Desktop/F:ROOM/` 配下に作成

### 1-2. ソースコードを取り込む

1. Xcode の Project Navigator（左ペイン）で `FRoom` グループを右クリック → **Add Files to "FRoom"...**
2. このリポジトリの `froom/` ディレクトリを丸ごと追加
3. **Copy items if needed**: チェックなし（参照のみ）
4. **Create groups**: 選択
5. **Add to targets**: `FRoom` にチェック

### 1-3. アイコン登録

1. `froom/Resources/Assets.xcassets/AppIcon.appiconset/` に各サイズのアイコンPNGがある
2. Xcode で `Assets.xcassets` を開き、**AppIcon** にドラッグ＆ドロップ
3. または `Assets.xcassets` を直接置き換える

### 1-4. iOS バージョン設定

- Project → Target → **Deployment Info → iOS** を **17.0** 以上に
- **Supported Destinations**: iPhone, iPad の両方をチェック

### 1-5. ビルド

- 上部のシミュレータを **iPhone 15 Pro** や **iPad Pro 13"** に切り替え
- **⌘R** で実行

## 2. データパイプラインを動かす

### 2-1. 仮想環境

```bash
cd data-pipeline
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 2-2. 設定

```bash
cp config.example.yml config.yml
```

`config.yml` を編集:

- **X bearer token**: 持っていなければ X Developer Portal で取得 (free tierでOK)
- **watch_accounts** の各リストを編集して、フォローしたいアカウントを追加

### 2-3. テスト実行

```bash
python -m api.build_feed --config config.yml --out output/intel-latest.json
```

`output/intel-latest.json` が生成されれば成功。

### 2-4. アプリと連携

現状アプリは `MockData` を参照していますが、本番化するには `Services/FeedClient.swift` を作成して JSON を fetch する処理を追加します（今後のフェーズ）。

## 3. GitHub に Push

### 3-1. リポジトリ作成

GitHub の Web UI で新規プライベートリポジトリ `froom` を作成（README 等は **追加しない**）。

### 3-2. 初回 Push

```bash
cd ~/Desktop/F:ROOM/froom-app
git init
git add .
git commit -m "Initial commit: f/Room app + data pipeline"
git branch -M main
git remote add origin git@github.com:YOUR_NAME/froom.git
git push -u origin main
```

### 3-3. GitHub Actions の Secrets 設定

GitHub リポジトリ → **Settings → Secrets and variables → Actions → New repository secret**

- `X_BEARER_TOKEN`: X API のトークン

これで `.github/workflows/collect-news.yml` が30分ごとに自動実行されます。

## トラブルシューティング

### Xcode で「Cannot find type 'PKDrawing'」
- Build Phases → Link Binary With Libraries に **PencilKit.framework** を追加

### フォントが反映されない
- カスタムフォント（Cinzel, Bebas Neue, Kalam）を使う場合は:
  1. `.ttf` ファイルをプロジェクトに追加
  2. **Build Phases → Copy Bundle Resources** に追加
  3. `Info.plist` → **Fonts provided by application (UIAppFonts)** に登録

### アプリビルドが通らない
- `Models.swift` で `import SwiftUI` が必要な場合は追加してください
- iOS Deployment Target が 17.0 未満だと `.navigationDestination(for:)` などが使えないので注意

---

不明点があれば Issue を立てるか、リポジトリの Discussions を活用してください。
