# Daily Digest + RAS データ収集 セットアップ手順

このドキュメントは、新規追加した2つの自動収集機能を Jetty さんが運用開始するための手順です。

## 1. AI Daily Digest

Claude API を使って、朝・夜の1日2回、収集したニュースを **日英バイリンガル** でまとめます。

### 1-1. Anthropic API キーを取得

1. ブラウザで [https://console.anthropic.com](https://console.anthropic.com) を開く
2. ログイン（または無料アカウント作成）
3. 左メニューの **API Keys** をクリック
4. **Create Key** を押す
5. Name を `redzone-tracker-digest` などにして Create
6. **表示された `sk-ant-...` で始まる長い文字列をメモ帳に保存**（一度しか表示されません）

### 1-2. GitHub Secrets に登録

1. ブラウザで [https://github.com/Jettest777/froom/settings/secrets/actions](https://github.com/Jettest777/froom/settings/secrets/actions)
2. **New repository secret** を押す
3. 入力:
   - Name: `ANTHROPIC_API_KEY`
   - Secret: さっきメモしたキー（`sk-ant-...`）を貼り付け
4. **Add secret**

### 1-3. テスト実行

1. リポジトリページ上部の **Actions** タブ
2. 左メニューから **AI Daily Digest** をクリック
3. **Run workflow** ボタン → **time_of_day** を `morning` か `evening` 選択 → **Run workflow**
4. 緑のチェックになれば成功（30秒〜2分）
5. リポジトリの `data-pipeline/output/digest-latest.json` が新規作成されているはず

### 1-4. アプリで確認

- Xcode でビルドして起動
- **News タブ** の最上部に黒地のダイジェストカードが表示される
- JA / EN トグルで言語切替
- 「詳しく読む」を押すと注目トピックスと「明日の見どころ」が展開

### 1-5. 自動実行

GitHub Actions が自動で実行:
- 朝 22:00 UTC（日本時間 朝7時）
- 夜 11:00 UTC（日本時間 夜8時）

### コスト目安

Claude Sonnet 4.5 で1回あたり概算:
- 入力 ~3,000 tokens × $3/1M = $0.009
- 出力 ~1,500 tokens × $15/1M = $0.023
- **1回 ≈ $0.03（約4.5円）**
- 1日2回 × 30日 = **月 $1.80（約270円）**

---

## 2. RAS (Relative Athletic Score) データ収集

選手の身体能力スコアを ras.football からスクレイピングします。

### 2-1. 監視対象選手を編集

`data-pipeline/ras-seed.json` を開いて、収集したい選手を追加:

```json
{
  "players": [
    {"first": "Patrick", "last": "Mahomes"},
    {"first": "Josh", "last": "Allen"},
    {"first": "新しい選手の名", "last": "新しい選手の姓"}
  ]
}
```

### 2-2. テスト実行

1. リポジトリの **Actions** タブ → **Collect RAS Data** → **Run workflow**
2. 緑のチェックで成功
3. `data-pipeline/output/ras-latest.json` が生成される

### 2-3. アプリで確認

- Team → 任意のチーム → Players サブタブ → 選手をタップ
- 選手詳細画面の上部に **Profile / Athleticism / Career** の3サブタブ
- **Athleticism** タブを選ぶと:
  - 大きなRAS総合スコア（10満点、グレード付き）
  - レーダーチャート（SIZE / SPEED / EXPLOSION / AGILITY / STRENGTH）
  - Combine 数値（40-yd, Vertical, Broad, Bench, 3-Cone, Shuttle）
  - データソースリンク（ras.football）

### 2-4. 自動実行

毎週月曜 04:00 UTC（日本時間 月曜 13:00）に自動で更新されます。RAS データは選手ごとにほぼ静的なので、週1で十分。

### 注意

- ras.football は公開API がないため HTML スクレイピングです。サイト構造が変わるとデータが取れなくなる可能性があります
- 取れなかった場合、選手詳細画面の Athleticism タブには「RAS データは未取得です」と表示されます
- 大量の選手を一度に追加するとサーバーに負荷がかかるので、最初は20人程度から始めることを推奨

---

## まとめ: Jetty さんがやることリスト

### Daily Digest 用
- [ ] Anthropic API キー取得
- [ ] GitHub Secrets に `ANTHROPIC_API_KEY` 登録
- [ ] Actions タブから「AI Daily Digest」を手動実行してテスト

### RAS 用
- [ ] `ras-seed.json` に好きな選手を追加（任意）
- [ ] Actions タブから「Collect RAS Data」を手動実行してテスト

### Xcode 側
- [ ] 新規ファイルを Add Files で追加:
  - `froom/Models/DailyDigest.swift`
  - `froom/Models/RASData.swift`
  - `froom/Services/DigestClient.swift`
  - `froom/Services/RASClient.swift`
  - `froom/Features/Home/DailyDigestCard.swift`
  - `froom/Features/Players/AthleticismView.swift`
- [ ] ⌘Shift+K → ⌘R でビルド & 起動
- [ ] News タブ上部のダイジェストカードを確認
- [ ] Team → Players → 選手詳細 → Athleticism タブを確認

### GitHub push

```bash
cd ~/Desktop/F:ROOM/froom-app
git add .
git commit -m "Add: Redzone Tracker rebrand, AI Daily Digest, RAS athleticism"
git push
```
