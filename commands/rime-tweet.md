---
description: 读取 X/Twitter 推文内容
---

读取 X/Twitter 推文内容。参数: 推文 URL 或 Tweet ID。

## 流程

### 1. 提取 Tweet ID

从参数中提取数字 ID：
- `https://x.com/user/status/123456` → `123456`
- `https://twitter.com/user/status/123456` → `123456`
- 纯数字直接使用

### 2. fxtwitter API（首选）

```
WebFetch: https://api.fxtwitter.com/status/{tweet_id}
Prompt: Return the COMPLETE tweet text verbatim from the "text" field — do not summarize or paraphrase. Also return: author name, screen_name, created_at. For media, only list image URLs (ignore videos).
```

成功 → 输出内容，结束。

### 3. twitter-thread.com Fallback

fxtwitter 404 时：

**3a.** 直接尝试：
```
WebFetch: https://twitter-thread.com/t/{tweet_id}
```

有内容 → 输出，结束。

**3b.** 没有内容 → 用 agent-browser 提交抓取：
```bash
npx agent-browser --native open "https://twitter-thread.com"
# 用 snapshot -i 确认输入框和按钮选择器
npx agent-browser --native fill "{input_selector}" "https://x.com/{author}/status/{tweet_id}"
npx agent-browser --native click "{submit_selector}"
npx agent-browser --native wait 5000
```

然后重新 WebFetch twitter-thread.com 读取结果。

### 4. 全部失败

告知用户无法获取，建议手动查看原链接。

## 输出格式

```
**@{author}** — {date}

{推文内容}

{图片（如有，用 ![](url) 展示）}
```

长 thread 按顺序排列，用分隔线隔开。
