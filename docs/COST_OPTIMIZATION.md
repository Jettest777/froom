# Anthropic API コスト最適化メモ

このアプリでは AI Daily Digest 生成に Claude API を使っています。
クレジット制でなるべく課金を抑えるための仕組みを説明します。

## デフォルト構成

| 項目 | デフォルト値 | 理由 |
|---|---|---|
| モデル | `claude-haiku-4-5-20251001` | Sonnet の約 1/12 のコスト |
| 実行頻度 | 1日2回（朝・夜） | スケジュール固定 |
| 入力アイテム数 | 上限 25 件 | トークン爆発防止 |
| 出力トークン | 上限 3,000 | 詳細記事には十分 |
| キャッシュ | 6時間以内に同じソースなら API 呼ばずスキップ | 連続実行時の無駄遣い防止 |

## 月間コスト想定

### Haiku 4.5 を使った場合（推奨）

- 1回あたり: 入力 ~4,000 tokens + 出力 ~2,500 tokens
- 入力: 4K × $1/1M = **$0.004**
- 出力: 2.5K × $5/1M = **$0.0125**
- **1回あたり ≈ $0.017**
- 1日2回 × 30日 = **月 $1.02（約150円）**

### Sonnet 4.5 を使った場合

- 入力: 4K × $3/1M = **$0.012**
- 出力: 2.5K × $15/1M = **$0.038**
- **1回あたり ≈ $0.05**
- 1日2回 × 30日 = **月 $3.00（約450円）**

## さらにコストを下げる方法

### A. Sonnet に切り替えるべきタイミングだけ手動実行

通常は Haiku を回しっぱなしにしておき、**重要な日**（ドラフト直後、トレード期限、Super Bowl 週など）だけ手動で Sonnet にする運用がベスト。

GitHub Actions の **Run workflow** ボタン → **Model** で `claude-sonnet-4-5` を選択。

### B. 朝だけにする

GitHub Actions の `cron` を朝1回だけに変更:

```yaml
schedule:
  - cron: "0 22 * * *"
  # - cron: "0 11 * * *"   ← この行をコメントアウト
```

これで月コスト半額（Haiku で約75円）。

### C. オフシーズン中は止める

NFL シーズンオフ（3月〜8月）はニュース量が少ないので、ワークフロー全体を一時停止:

- GitHub リポジトリ → Actions → AI Daily Digest → 右上 `...` → **Disable workflow**

シーズン開始前に再有効化。

### D. RSS だけで運用（API 完全停止）

ANTHROPIC_API_KEY を未設定にすれば、Claude 呼び出し自体が走らず、フォールバックメッセージが入った digest-latest.json だけが書き出されます。アプリ側はモック表示にフォールバックします。

**完全無料運用**。

### E. 自分の Anthropic クレジットを使い切ったらどうなる？

API がエラーを返すだけで、課金は発生しません。アプリ側は前回キャッシュされた digest を表示し続けます。

## 監視

Anthropic Console ([console.anthropic.com](https://console.anthropic.com)) → **Usage** で日次の消費量がグラフで確認できます。

予算アラートを設定するのも推奨:

1. Console → **Limits** タブ
2. **Spend Limits** に月の上限（例: $5）を設定
3. 上限到達時は API が止まり、それ以上の課金は発生しない

これで安心して運用できます。

## 入力データソース

Claude には RSS と X (Twitter) と NFL.com のニュースを統合したものを渡しています。RSS は完全無料・無制限なので、X bearer token がなくても運用可能です:

- ESPN NFL
- CBS Sports NFL
- FOX Sports NFL
- NBC Sports NFL
- Pro Football Talk
- Yahoo Sports NFL
- Bleacher Report
- PFF NFL
- NFL.com

これらは全部 `data-pipeline/collectors/rss_collector.py` で読み込まれます。
