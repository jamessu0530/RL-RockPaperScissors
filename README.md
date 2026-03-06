# 猜拳 App - 多模型強化學習對戰

Flutter 猜拳遊戲，內建五種 AI 模型同時與玩家對戰，透過不同強化學習策略學習玩家出拳習慣。支援多玩家切換、詳細勝率統計、以及勝率曲線圖。勝率計算排除平手，僅計「勝 / (勝+負)」。介面為黑白主題。

## 功能

- 猜拳（剪刀、石頭、布）對戰五種 AI 模型
- 多玩家切換，每位玩家各有獨立的模型實例
- 本局結果即時顯示各模型出拳與勝負
- 詳細勝率統計頁面（依「電腦出 X 時」及「玩家上一手出 Y 時」分類）
- 勝率曲線圖（fl_chart），支援觸碰拖移查看歷史數據
- 勝率 > 50% 以綠色標示，< 50% 以紅色標示
- 音效回饋：出拳後依結果播放不同音效（勝利、落敗、平手）

## AI 模型

| 模型 | 策略 |
|------|------|
| Contextual Bandit | 以玩家上一手為 context，Q 值搭配 decaying epsilon-greedy 探索，Laplace 先驗 |
| 馬可夫鏈 | 記錄玩家出拳的轉移機率，預測下一手並出相剋招 |
| Thompson Sampling | 貝葉斯方法，對每個 (state, action) 維護 Beta 分布參數，抽樣選動作 |
| UCB1 | 以信賴上界公式 mean + C * sqrt(ln(N)/n) 平衡探索與利用 |
| Random（基準線） | 隨機出拳，作為其他模型的對照基準 |

## 檔案結構

```
lib/
  main.dart                    # 程式入口，MyApp 與 Theme
  models/
    janken_model.dart          # AI 模型抽象介面
    q_entry.dart               # Q 表單一項目資料結構
  pages/
    janken_page.dart           # 猜拳主畫面（玩家選擇、出拳、模型結果）
    stats_page.dart            # 勝率統計頁面（各玩家 / 模型詳細數據）
    chart_page.dart            # 勝率曲線圖頁面（fl_chart 折線圖）
  services/
    bandit_service.dart        # Contextual Bandit（decaying epsilon-greedy）
    markov_service.dart        # 馬可夫鏈
    thompson_service.dart      # Thompson Sampling（Beta 分布）
    ucb_service.dart           # UCB1（Upper Confidence Bound）
    random_service.dart        # Random 基準線
    sound_service.dart         # 音效播放服務（audioplayers）
  styles/
    app_styles.dart            # 主題與樣式（黑白主題）
  widgets/
    janken_buttons.dart        # 剪刀 / 石頭 / 布 按鈕元件
assets/
  sounds/
    tap.wav                    # 出拳點擊音效
    win.wav                    # 勝利音效
    lose.wav                   # 落敗音效
    draw.wav                   # 平手音效
```

## 如何執行

```bash
flutter pub get
flutter run
```

指定裝置（例如 iOS 模擬器）：

```bash
flutter devices
flutter run -d <device_id>
```

## 技術說明

- **狀態（context）**：玩家上一局出拳（首局為預設值 N）。
- **動作**：電腦出剪刀、石頭或布。
- **獎勵**：電腦贏 +1、平手 0、電腦輸 -1。
- **Contextual Bandit**：在每個 context 下以 Q 值選動作，搭配 decaying epsilon-greedy 探索；同分時隨機挑選。Q 表使用 Laplace 先驗（count 從 1 起）。
- **馬可夫鏈**：建立轉移矩陣 transition[prev][next]，預測玩家下一手後出相剋招。
- **Thompson Sampling**：對每個 (state, action) 維護 alpha/beta 參數，每次從 Beta 分布抽樣選最大值的動作。
- **UCB1**：優先嘗試未試過的動作；之後以 mean + C * sqrt(ln(N)/n) 選動作。
- **Random**：純隨機，不學習，作為效能比較基準。

## 依賴

- Flutter SDK
- fl_chart（折線圖）
- audioplayers（音效播放）

## 授權

此專案為課程作業，可依需求自行修改與使用。
