# Levy Companion Mod - ENDER MAGNOLIA

让露薇（Levy）作为你的伙伴跟随你冒险，还能与她进行智能对话！

---

## 功能

- 跟随系统：露薇会跟随玩家移动，速度自适应
- 动画系统：行走、待机、交互动画自然切换
- 场景切换：换场景时自动重生
- 交互动画：打招呼、对话、害羞等多种表情
- AI 智能对话：接入本地大模型，露薇拥有完整人设和记忆（Beta）

---

## 操作按键

| 按键 | 功能 |
|------|------|
| Alt+8 | 召唤/取消露薇 |
| Alt+F1 | 瞬移露薇到身边 |
| Alt+6 | 移动速度 +1 |
| Alt+7 | 移动速度 -1 |
| Alt+1 | 打招呼 |
| Alt+2 | 递东西 |
| Alt+3 | 说话 |
| Alt+4 | 受惊 |
| Alt+5 | 思考/踢 |
| Alt+9 | 仰头打招呼 |
| Alt+F | 打开 AI 对话输入框 |
| Alt+F12 | 强制关闭对话框 |

---

## 安装步骤

### 前置要求

- ENDER MAGNOLIA: Bloom in the Mist（Steam 版）

### 安装

1. 下载 LevyCompanion-v0.1.zip
2. 解压后将所有文件放入：
   ENDER MAGNOLIA/EnderMagnolia/Binaries/Win64/
3. 启动游戏，按 Alt+8 召唤露薇

---

## AI 智能对话配置（核心功能）

让露薇接入本地 AI 大模型，实现真正的智能对话。

重要提示：
- 首次使用 AI 对话前，需要先在游戏中与任意 NPC 对话一次（激活对话框系统）
- 对话后若按键失灵，按 ESC 点击继续即可恢复
- 需要至少 4GB 显存（3B 模型）
- 注意⚠:Beta 版本可能不稳定,请按zip文件中的教程逐步配置


## 常见问题

Q：按 Alt+8 没有反应

A：确认 UE4SS 已安装，mods.txt 中添加了 LevySummon : 1

Q：露薇消失了

A：按 Alt+F1 瞬移，或 Alt+8 重新召唤

Q：AI 对话没反应

A：需要先与任意 NPC 对话一次，激活对话框系统

Q：对话后按键失灵

A：按 ESC 点击继续即可恢复

Q：bridge.py 显示 Cannot reach Ollama

A：打开新命令提示符，输入 ollama serve

Q：回复出现乱码

A：检查 config.json 中的 max_reply_length 不要太短

Q：想清空对话历史

A：按 Alt+D 或手动删除 LevyAI/data/history.json



---

# Levy Companion Mod - ENDER MAGNOLIA

Let Levy accompany you on your adventure and have intelligent conversations with her!

---

## Features

- Follow System: Levy follows the player with adaptive speed
- Animation System: Natural switching between walking, idle, and interactive animations
- Scene Switching: Automatically respawns when changing areas
- Interactive Animations: Greeting, talking, shy, and many more expressions
- AI Smart Dialogue: Connect to local LLM with full character personality and memory (Beta)

---

## Controls

| Keybind | Function |
|---------|----------|
| Alt+8 | Summon/Dismiss Levy |
| Alt+F1 | Teleport Levy to you |
| Alt+6 | Movement speed +1 |
| Alt+7 | Movement speed -1 |
| Alt+1 | Greeting |
| Alt+2 | Give item |
| Alt+3 | Talk |
| Alt+4 | Frightened |
| Alt+5 | Think/Kick |
| Alt+9 | Look up greeting |
| Alt+F | Open AI chat input |
| Alt+F12 | Force close dialog |

---

## Installation

### Requirements

- ENDER MAGNOLIA: Bloom in the Mist (Steam version)

### Installation

1. Download LevyCompanion-v0.1.zip
2. Extract all files into:
   ENDER MAGNOLIA/EnderMagnolia/Binaries/Win64/
3. Launch the game and press Alt+8 to summon Levy

---

## AI Smart Dialogue Configuration (Core Feature)

Connect Levy to a local AI large language model for true intelligent conversations.

Important Notes:
- Before using AI chat for the first time, talk to any NPC in the game first (to activate the dialog system)
- If controls become unresponsive after talking to an NPC, press ESC and click Continue to restore
- Requires at least 4GB VRAM (3B model)
- Note ⚠: Beta version may be unstable. Please follow the tutorial in the zip file for step-by-step configuration

---

## FAQ

Q: Pressing Alt+8 does nothing

A: Make sure UE4SS is properly installed and LevySummon : 1 is added to mods.txt

Q: Levy disappeared

A: Press Alt+F1 to teleport her, or Alt+8 to resummon

Q: AI chat doesn't respond

A: You need to talk to any NPC first to activate the dialog system

Q: Controls become unresponsive after talking to an NPC

A: Press ESC and click Continue to restore normal control

Q: bridge.py shows "Cannot reach Ollama"

A: Open a new Command Prompt and type: ollama serve

Q: Replies contain garbled text

A: Check that max_reply_length in config.json isn't too short

Q: How to clear conversation history

A: Press Alt+D or manually delete LevyAI/data/history.json



---
## Dependencies
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) 

