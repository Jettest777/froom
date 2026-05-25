# Rebrand: f/Room → Redzone Tracker

旧ブランド「**f/Room** — FILM / FOCUS / FUNDAMENTAL」から、
新ブランド「**Redzone Tracker** — The Sideline View」へ刷新しました。

## ブランド要素

| 項目 | 旧 | 新 |
|---|---|---|
| アプリ名 | f/Room | **Redzone Tracker** |
| サブコピー | FILM / FOCUS / FUNDAMENTAL | **THE SIDELINE VIEW** |
| プライマリカラー | Rust #9c4523（錆色） | **Red Zone Red #DC2626**（NFLレッド） |
| アクセント | Bronze #b8843a | **End Zone Gold #FBBF24** |
| セカンダリ | — | **Electric Blue #38BDF8**（データ用） |
| 雰囲気 | 革・羊皮紙・オールドスクール | **スタジアム照明・データ駆動・現代的** |

## Xcode 側で必要な変更

コードは自動更新済みですが、**Xcode プロジェクト設定** はJettyさんが手動で更新してください。

### 1. アプリ表示名を変更

1. Xcode の左ペインで一番上の **FRoom** プロジェクトをクリック
2. **TARGETS → FRoom** を選択
3. **General タブ**:
   - **Display Name**: `f/Room` → **`Redzone Tracker`** に書き換え
4. **Build Settings → Packaging → Product Name** も確認（変えなくてもDisplay Nameが優先される）

これでホーム画面のアプリ名表示が変わります。

### 2. アプリアイコンを差し替え（任意・後でOK）

旧アイコン（革調フットボール×F）は新ブランドのトーンと合わなくなるので、
新アイコンができたら `froom/Resources/Assets.xcassets/AppIcon.appiconset/` の中身を差し替えます。

仮で動かす分には旧アイコンのままでビルドは通ります。

### 3. プロジェクト名（任意）

ファイルシステム上のプロジェクト名は `FRoom` のままでも問題なく動きます。
気になる場合は Xcode の File → Project Settings 等で変更できますが、
リポジトリパスの変更を伴うので慎重に。

## コード側で変わったこと

### 新規ファイル

- `DesignSystem/Theme.swift` — 新カラーパレット（rzRed, ezGold, elecBlue 等）
- `DesignSystem/FRoomLogo.swift` — `RZTLogo` コンポーネント新規追加（旧 `FRoomLogo` も互換ラッパとして残存）

### 影響を受けるファイル

- `Features/Splash/SplashView.swift` — 新ブランドの起動画面に刷新
- `Features/Home/HomeView.swift` ほか各タブのヘッダー — `RZTLogo` 使用
- `Features/Canvas/CanvasView.swift` — 小さな RZT マークに置換

### 旧 API 互換性

- `FRoomLogo(.header)` 等の旧コードはそのまま動きます（内部で `RZTLogo` を呼ぶ）
- `FRTheme.Color.rust` 等の旧定数も生き残っており、`rzRed` の別名として機能

## 確認方法

1. Xcode で ⌘Shift+K（Clean Build）
2. ⌘R で実行
3. スプラッシュ画面に新ロゴ（REDZONE / TRACKER + THE SIDELINE VIEW）が出るか確認
4. 各タブのヘッダーが「REDZONE | TRACKER」のインラインロゴに変わっているか確認

## トラブルシューティング

### スプラッシュが古いまま
Clean Build Folder（⌘Shift+K）後に再ビルド。それでもダメなら DerivedData を削除:
```
rm -rf ~/Library/Developer/Xcode/DerivedData/FRoom-*
```

### ロゴが見切れる
スプラッシュではフォントサイズ52pxを使っています。iPhone SE（小画面）だと文字がはみ出ることがあるので、その場合は `RZTLogo.Size.headline` を `.caption` に下げてください。
