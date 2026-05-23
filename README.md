# f/Room

> **NFL情報収集 × スカウティングノート** iOS / iPadOS アプリ
> _FILM | FOCUS | FUNDAMENTAL_

NFLのニュース、移籍、契約更新、デプスチャート、怪我人情報、会見の発言などを
**信頼性スコア付き**で自動収集し、試合で気づいたプレーを iPad の Apple Pencil で
**手書きスカウティングレポート**として残せる学習・情報収集ツール。

---

## 主な機能

### 1. インテリジェンスフィード
- X（Twitter）の信頼できる記者（Schefter, Rapoport, Russini など）と公式アカウント
- NFL公式 / ESPN
- 移籍 / サイン / 契約 / 怪我 / 発言 / 噂 にタイプ分け
- **信頼性スコア**（複数ソース確認時はボーナス）
- カードごとに **🇯🇵 和訳ボタン**

### 2. チーム / 選手データ
- 32チームのデプスチャート（OFF / DEF / ST）
- 選手詳細（プロフィール、契約、怪我履歴、発言ログ）

### 3. コーチツリー（HC / OC / DC モード切替）
- Walsh / Belichick / Reid / Parcells / Fangio / LeBeau などの系譜
- 師匠・兄弟弟子・弟子の関係をビジュアルに
- コーチ詳細ページで所感をタグ付きコメントとして残せる

### 4. 試合ページ
- フルボックススコア（ラインスコア / チーム比較 / 個人スタッツ）
- ドライブチャート + プレーバイプレー
- 各プレー行の ✎ ボタンから **キャンバスに直接遷移**

### 5. 手書きスカウティングキャンバス（iPad / Apple Pencil）
- **3エリア構成**: O# / LOS / D# / 独立した手書きメモエリア
- LOS は画面中央に横線として描画
- **FLIP V / H / 180°** ボタンでプレーエリアだけ反転（メモは正立キープ）
- ペン / マーカー / 蛍光ペン / 消しゴム / 投げ縄、5色インク
- 試合別 + タグ別で振り返り可能

### 6. 自動更新
- GitHub Actions が30分おきにニュース収集 → JSON を更新
- アプリが GitHub Pages の JSON を取得

---

## リポジトリ構成

```
froom-app/
├── froom/                          # SwiftUI アプリ本体
│   ├── App/
│   │   └── FRoomApp.swift          # @main エントリーポイント
│   ├── DesignSystem/
│   │   ├── Theme.swift             # カラー・フォント・スペーシング
│   │   ├── FRoomLogo.swift         # F/ROOM ロゴコンポーネント (銅グラデ)
│   │   └── FRComponents.swift      # Card / Chip / Badge / TabBar / Section
│   ├── Models/
│   │   └── Models.swift            # NewsItem / Team / Player / Coach / Game / Play / CanvasNote
│   ├── Mocks/
│   │   └── MockData.swift          # SwiftUIプレビュー用モック
│   ├── Features/
│   │   ├── Splash/SplashView.swift
│   │   ├── Home/HomeView.swift
│   │   ├── Teams/TeamsView.swift
│   │   ├── Coaches/CoachTreeView.swift
│   │   ├── Notes/NotebookView.swift
│   │   ├── Games/GameDetailView.swift
│   │   └── Canvas/CanvasView.swift  # PencilKit + 反転ロジック
│   └── Resources/Assets.xcassets/
│       └── AppIcon.appiconset/      # 切り抜き済みアイコン各サイズ
│
├── data-pipeline/                   # Python データ収集サーバー
│   ├── requirements.txt
│   ├── config.example.yml
│   ├── collectors/
│   │   ├── common.py                # NewsItem 共通モデル & 分類ロジック
│   │   ├── x_collector.py           # X (Twitter) 記者・公式アカウント
│   │   └── nfl_official.py          # NFL.com スクレイパー
│   ├── scorers/
│   │   └── reliability_scorer.py    # 信頼性スコアリング
│   ├── api/
│   │   └── build_feed.py            # 統合JSON生成
│   └── output/                      # 生成された JSON (gitignore対象)
│
├── docs/design/                     # HTMLモック v1〜v8 (デザイン参照用)
│   ├── froom-mockup-v7.html
│   └── froom-mockup-v8.html
│
├── .github/workflows/
│   └── collect-news.yml             # 30分ごとに収集 → コミット
│
├── Package.swift                    # SPMのコア定義
├── .gitignore
└── README.md
```

---

## セットアップ

### 1. リポジトリを取得

```bash
git clone <YOUR_REPO_URL> froom
cd froom
```

### 2. iOSアプリ (Xcode)

#### 初回セットアップ
1. Xcode（最新版）を開く
2. **File → New → Project... → iOS → App**
3. 設定:
   - Product Name: `FRoom`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **iOS 17.0**
4. 既存の `froom/` ディレクトリを Xcode プロジェクトに「Add Files to FRoom...」で追加
   - **Resources/Assets.xcassets** は Xcode の AppIcon に紐づくよう設定
5. アイコン画像 (`Resources/Assets.xcassets/AppIcon.appiconset/`) を AppIcon に登録

#### ビルド
- iPhone シミュレータ または iPad シミュレータ を選択 → **⌘R**
- 物理デバイスでビルドする場合は Apple Developer アカウント設定が必要

#### Apple Pencil テスト
- iPad シミュレータでは Pencil 入力をマウス/トラックパッドで代用可
- 本物の Pencil 体験は実機 (iPad + Apple Pencil) で確認

### 3. データパイプライン (Python)

```bash
cd data-pipeline
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp config.example.yml config.yml
# config.yml を編集して X bearer token などをセット

# テスト実行
python -m api.build_feed --config config.yml --out output/intel-latest.json
```

### 4. GitHub Actions

`config.example.yml` の `REPLACE_ME` 部分は GitHub Actions の Secrets で管理:

- リポジトリ → **Settings → Secrets and variables → Actions**
- `X_BEARER_TOKEN` を追加
- `.github/workflows/collect-news.yml` が30分おきに実行され、`data-pipeline/output/intel-latest.json` を更新コミット

---

## デザインシステム

### カラー
| 用途 | 名前 | 値 |
|---|---|---|
| 背景 (深) | bg-0 | `#060709` |
| 背景 (浅) | bg-2 | `#14171e` |
| テキスト | text-0 | `#f3efe6` |
| アクセント | rust | `#9c4523` |
| 強調 | rust-bright | `#c75a30` |
| ハイライト | bronze | `#b8843a` |
| ホワイトボード | whiteboard | `#f1ece0` |
| メモパッド | memo-pad | `#fbf6e8` |

### タイポグラフィ
- **ロゴ**: Cinzel Black + 銅グラデーション (FRoomLogo)
- **見出し**: Bebas Neue (BebasNeue-Regular)
- **本文 / UI**: Inter (システムフォントにフォールバック可)
- **手書きメモ**: Kalam (フォールバック: SF Pro Rounded)
- **モノスペース**: SF Mono (`.monospaced`)

カスタムフォントは `Info.plist` の `UIAppFonts` に登録するか、Xcode の Asset Catalog に追加してください。

### ロゴ使用例

```swift
FRoomLogo(.hero)     // 64pt - マーケティング画面
FRoomLogo(.splash)   // 52pt - 起動画面
FRoomLogo(.header)   // 26pt - ナビバー
FRoomLogo(.custom(40)) // 任意サイズ
```

---

## ロードマップ

- [x] **Phase 0**: UIモック (v1 → v8 で確定)
- [x] **Phase 1**: アプリ骨格 (SwiftUI + PencilKit)
- [x] **Phase 2**: データパイプライン基本構造
- [ ] **Phase 3**: 信頼性スコアの実データ検証
- [ ] **Phase 4**: PencilKit描画の永続化 (CanvasNote → SwiftData)
- [ ] **Phase 5**: タグ横断検索 + iCloud同期
- [ ] **Phase 6**: NCAA Football 拡張

---

## 開発のコツ

### モックを参考にする
`docs/design/froom-mockup-v8.html` をブラウザで開くと、確定したデザインが見られます。SwiftUI 実装はこれを参考にしながら整合性を保ってください。

### SwiftUI プレビュー
各 `*.View` ファイルの `#Preview` ブロックを使えば Xcode で個別画面を確認可能。

### キャンバス反転の挙動
- プレーエリア (上半分): `scaleEffect(x: flipH ? -1 : 1, y: flipV ? -1 : 1)`
- メモエリア (下半分): 反転対象外。常に正立。

---

## ライセンス

Private（個人プロジェクト）
