import os
import sys
import requests
import pyperclip
import re  # 引入正则库，用于清洗数据
from datetime import datetime

# ================= 🚀 核心配置区 =================
API_KEY_ENV_VARS = ("JINDOUYUN_DEEPSEEK_API_KEY", "DEEPSEEK_API_KEY")

# [升级点1]：超时时间延长到 120秒，给 AI 足够时间思考长文
TIMEOUT_SECONDS = 120

# [升级点2]：字符数安全上限（防止把一整本书复制进去导致崩溃）
MAX_CHARS = 30000

LIFEOS_ROOT_ENV = "JINDOUYUN_LIFEOS_ROOT"
SUB_FOLDER = "AI精华汇总"
# ================================================

# --- [新技能]：数据清洗与压缩 ---
def clean_and_compress(text):
    """清洗杂乱字符，并防止过长"""
    # 1. 清洗：去除多余的空行、制表符，合并连续空格
    text = re.sub(r'\s+', ' ', text).strip()

    # 2. 截断：如果还是太长，保留头尾精华
    if len(text) > MAX_CHARS:
        print(f"⚠️ 文本过长 ({len(text)}字)，已自动压缩...")
        half = int(MAX_CHARS / 2)
        # 保留前一半和后一半，中间省略
        text = text[:half] + "\n\n[...中间内容过长已省略...]\n\n" + text[-half:]

    return text

def get_target_dir():
    """使用用户配置的知识库目录，未配置时写入个人文档目录。"""
    base = os.getenv(LIFEOS_ROOT_ENV, "").strip()
    if not base:
        base = os.path.join(os.path.expanduser("~"), "Documents", "筋斗云")
    target = os.path.join(base, SUB_FOLDER)
    os.makedirs(target, exist_ok=True)
    return target

def get_api_key():
    """从环境变量读取 DeepSeek API Key"""
    for env_name in API_KEY_ENV_VARS:
        value = os.getenv(env_name, "").strip()
        if value:
            return value
    return ""

def call_deepseek(content):
    """调用 DeepSeek API"""
    api_key = get_api_key()
    if not api_key:
        vars_text = " 或 ".join(API_KEY_ENV_VARS)
        return f"❌ 未设置 DeepSeek API Key。请先配置环境变量：{vars_text}"

    url = "https://api.deepseek.com/chat/completions"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}

    # [升级点3]：针对长文优化的提示词
    system_prompt = f"""
    你是一位个人知识库专家。用户提供了一篇较长的文章或文本。
    请忽略所有的广告、推广信息和无关的格式字符。
    日期: {datetime.now().strftime("%Y-%m-%d")}

    【任务目标】：
    请对这篇文章进行深度的【逻辑重构】，而非简单的摘抄。

    【格式要求】：
    1. YAML Frontmatter:
       ---
       tags: [AI/长文精读, LifeOS/深度学习]
       source: 外部采集
       created: {datetime.now().strftime("%Y-%m-%d %H:%M")}
       ---
    2. 正文结构：
       ## 💡 核心论点 (One Big Idea)
       (用一句话概括全文最核心的价值)

       ## 🧬 逻辑脉络
       (还原文章的论证逻辑，使用多级列表)

       ## 📖 关键知识点 (Gold Nuggets)
       (提取文中 3-5 个具体的概念、数据或案例)

       ## ⚡ 行动指南
       (基于此文，对"身体/语言/注意力"系统的具体建议)
    """

    data = {
        "model": "deepseek-chat",
        "messages": [{"role": "system", "content": system_prompt}, {"role": "user", "content": content}],
        "temperature": 1.1,
        "stream": False
    }

    try:
        # 使用配置好的超时时间
        r = requests.post(url, headers=headers, json=data, timeout=TIMEOUT_SECONDS)
        if r.status_code == 200:
            return r.json()['choices'][0]['message']['content']
        else:
            return f"❌ API 报错: {r.status_code} - {r.text}"
    except Exception as e:
        return f"❌ 请求超时或失败: {str(e)}"

def main():
    # 1. 获取剪贴板
    content = pyperclip.paste()
    if not content or len(content) < 5: return

    # 2. 清洗数据 (v1.1 核心)
    clean_content = clean_and_compress(content)

    target_dir = get_target_dir()

    # 3. 调用 AI
    note = call_deepseek(clean_content)

    # 4. 写入与弹窗
    if note:
        filename = datetime.now().strftime("%Y-%m-%d_%H%M%S") + "_深度长文.md"
        filepath = os.path.join(target_dir, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(note)
        os.startfile(target_dir)

if __name__ == "__main__":
    main()
