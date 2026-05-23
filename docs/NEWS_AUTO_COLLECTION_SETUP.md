# ニュース自動収集 セットアップ手順

X（Twitter）の主要NFL記者・公式アカウントから自動でニュースを収集して、
GitHub経由でアプリに配信する仕組みを動かすための手順書です。

## 全体の流れ

```
[X記者のツイート]
       ↓ 30分おきに自動収集
[GitHub Actions (収集スクリプト)]
       ↓ JSONを生成
[GitHubリポジトリの data-pipeline/output/intel-latest.json]
       ↓ アプリが起動時にfetch
[f/Room アプリの Home 画面]
```

Jettyさんがやることは、この流れを動かすための **「鍵」（X Bearer Token）** を取得して、GitHub に登録するだけです。コードは全部書いてあります。

---

## ステップ1: X (Twitter) Developer アカウントを作る

### 1-1. ブラウザで X Developer Portal にアクセス

[https://developer.x.com/en/portal/dashboard](https://developer.x.com/en/portal/dashboard)

### 1-2. 普段使っているXアカウントでログイン

すでにXのアカウントがあればそれを使えます。なければ作ってください（無料）。

### 1-3. 利用申請する

初回アクセスだと「**Sign up for a free account**」のような画面が出ます。

- **Free tier**（無料プラン）を選択 — これでOK
- ユースケースを書く欄が出たら、簡単に英語で:
  - `Research and personal study of NFL news. Collecting public tweets from official NFL accounts and beat writers for a personal study app.`
  - のように書けば通ります（30分くらいで承認されることが多い）

### 1-4. App を作成

承認されたら:

1. Dashboard に戻る
2. **+ Create Project** → プロジェクト名: `froom` などお好きに
3. **Create App** → アプリ名: `froom-collector` などお好きに
4. App が作成される

---

## ステップ2: Bearer Token を取得

### 2-1. App の Keys タブを開く

作成した App のページで **Keys and tokens** タブをクリック

### 2-2. Bearer Token を生成

- **Bearer Token** の項目に「**Generate**」ボタンがあるので押す
- 長い文字列（100文字くらい）が表示される
- **このトークンは1回しか表示されません**。必ずメモ帳などに保存

例:
```
AAAAAAAAAAAAAAAAAAAAANb%2BxQEAAAAAabcdefghijklmnop...
```

---

## ステップ3: GitHub にトークンを登録

### 3-1. GitHubのリポジトリページに移動

ブラウザで [https://github.com/Jettest777/froom](https://github.com/Jettest777/froom) を開く

### 3-2. Settings に移動

- リポジトリページ上部のタブで **Settings** をクリック
- もし Settings が見えない場合は、ログインしているか確認

### 3-3. Secrets を追加

1. 左メニューを下にスクロール
2. **Secrets and variables** → **Actions** をクリック
3. **New repository secret** ボタンを押す
4. 入力:
   - **Name**: `X_BEARER_TOKEN`（このスペルを正確に）
   - **Secret**: ステップ2でメモした Bearer Token を貼り付け
5. **Add secret** を押す

これでトークンが GitHub に**暗号化された状態**で保存され、Actions から使えるようになります。

---

## ステップ4: GitHub Actions を有効化

### 4-1. Actions タブに移動

リポジトリページ上部の **Actions** タブをクリック

### 4-2. ワークフローを有効化

- 初回は「**Workflows are disabled**」のようなメッセージが出ているかも
- **I understand my workflows, go ahead and enable them** を押す
- もしくは「**Collect NFL News**」というワークフロー名が見えれば、それをクリック

### 4-3. 手動実行してテスト

1. 左側のリストで「**Collect NFL News**」をクリック
2. 右上の「**Run workflow**」ボタンを押す
3. **Branch: main** が選ばれていることを確認 → 緑の **Run workflow** ボタン
4. 数秒待つと、新しいジョブが走り始める（黄色い丸 → 緑のチェック）

緑のチェックになれば成功。**約3〜5分**かかります。

### 4-4. 結果を確認

成功すると、リポジトリの `data-pipeline/output/intel-latest.json` というファイルが**自動で作られている**はずです。ブラウザでリポジトリのファイル一覧から `data-pipeline/output/` を開いてみてください。

---

## ステップ5: アプリ側で確認

### 5-1. Xcodeでアプリを起動

iPadシミュレータまたは実機で起動

### 5-2. Home画面を確認

- 起動時に自動でフィードを取得しに行きます
- 取得できた本物のニュースがHome画面に表示される
- 取得失敗時は **「⚠️ 取得失敗」** メッセージ + MockData が表示

### 5-3. 引っ張って更新

画面を **下に引っ張る (Pull to refresh)** とニュースが再取得されます

---

## トラブルシューティング

### GitHub Actions が赤いバツになる

- リポジトリの Actions タブ → 失敗したジョブをクリック → ログを確認
- よくある原因:
  - **`X_BEARER_TOKEN` が未登録または間違っている** → ステップ3を再確認
  - **X APIのレート制限** → 30分待ってリトライ
  - **`Workflow permissions` が不足** → Settings → Actions → General → 「Read and write permissions」をON

### アプリでニュースが MockData のままで切り替わらない

考えられる原因:
1. **GitHub Actions がまだ動いていない**（初回手動実行が必要）→ ステップ4-3
2. **リポジトリが Private + 認証なしでアクセスできない** → Public に変更するか、GitHub Personal Access Token を使う方式に切り替え（後述）
3. **JSON のフォーマット不一致** → Xcodeコンソールに `[FeedClient]` 系のエラーログが出ているはず

### Private リポジトリのまま使いたい場合

`raw.githubusercontent.com` への素のアクセスは Public リポジトリのみ可能です。Private のままでアプリから取得したい場合は以下の選択肢があります:

#### 選択肢A: リポジトリを Public にする
最も簡単。コードは公開されるが、Bearer Token は GitHub Secrets に入っているので漏れません。

#### 選択肢B: GitHub Pages を使う
- Settings → Pages → Source: `main` branch, `/data-pipeline/output` フォルダ
- すると `https://jettest777.github.io/froom/intel-latest.json` でアクセス可能
- `FeedClient.swift` の `feedURL` をその URL に変更

#### 選択肢C: 別の配信先を用意
S3 / Cloudflare R2 / Vercel などにJSONをアップロードして、そのURLをアプリに設定

---

## アカウントリストのカスタマイズ

`data-pipeline/config.example.yml` に監視するアカウントが書かれています。

追加・削除したい場合:

```yaml
x:
  watch_accounts:
    insiders:
      - AdamSchefter
      - RapSheet
      # 追加したいアカウントをここに
      - 新しいハンドル名（@マークなし）
```

編集 → コミット → push すれば、次回のActions実行から反映されます。

---

## 確認チェックリスト

- [ ] X Developer Portal で App を作成
- [ ] Bearer Token を取得・メモ
- [ ] GitHub の Secrets に `X_BEARER_TOKEN` を登録
- [ ] GitHub Actions で「Collect NFL News」を手動実行
- [ ] `data-pipeline/output/intel-latest.json` が生成された
- [ ] アプリの Home 画面で本物のニュースが表示される

困ったところがあれば、エラーメッセージのスクショと一緒に質問してください。
