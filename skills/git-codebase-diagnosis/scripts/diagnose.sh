#!/bin/bash
# Git 代码库诊断脚本
# 基于 Ally Piechowski 的文章: The Git Commands I Run Before Reading Any Code
# 在阅读代码之前，通过 5 个维度快速诊断代码库健康状况

set -e

# 颜色定义
BOLD='\033[1m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# 检查是否在 Git 仓库中
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo -e "${RED}错误：当前目录不是 Git 仓库${RESET}"
    exit 1
fi

REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
TOTAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "N/A")
FIRST_COMMIT_DATE=$(git log --reverse --format='%ad' --date=short | head -1)
LATEST_COMMIT_DATE=$(git log -1 --format='%ad' --date=short)

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Git 代码库诊断报告${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  仓库名称：${CYAN}${REPO_NAME}${RESET}"
echo -e "  诊断时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo -e "  总提交数：${TOTAL_COMMITS}"
echo -e "  历史跨度：${FIRST_COMMIT_DATE} ~ ${LATEST_COMMIT_DATE}"
echo ""

# ─────────────────────────────────────────────
# 1. 变更热点
# ─────────────────────────────────────────────
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  1. 变更热点 (Churn Hotspots)${RESET}"
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${YELLOW}过去一年中改动最频繁的 20 个文件${RESET}"
echo ""
git log --format=format: --name-only --since="1 year ago" 2>/dev/null | \
    grep -v '^$' | sort | uniq -c | sort -nr | head -20 | \
    awk '{printf "  %4d  %s\n", $1, $2}'
echo ""

# ─────────────────────────────────────────────
# 2. 贡献者分布
# ─────────────────────────────────────────────
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  2. 贡献者分布 (Bus Factor)${RESET}"
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${CYAN}[全部历史]${RESET}"
git shortlog -sn --no-merges 2>/dev/null | head -15 | \
    awk '{printf "  %4d  %s\n", $1, substr($0, index($0,$2))}'
echo ""
echo -e "  ${CYAN}[近 6 个月]${RESET}"
git shortlog -sn --no-merges --since="6 months ago" 2>/dev/null | head -15 | \
    awk '{printf "  %4d  %s\n", $1, substr($0, index($0,$2))}'
echo ""

# ─────────────────────────────────────────────
# 3. Bug 聚集区
# ─────────────────────────────────────────────
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  3. Bug 聚集区 (Bug Clusters)${RESET}"
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${YELLOW}包含 fix/bug/broken 关键词的提交涉及的文件${RESET}"
echo ""
git log -i -E --grep="fix|bug|broken" --name-only --format='' --since="1 year ago" 2>/dev/null | \
    grep -v '^$' | sort | uniq -c | sort -nr | head -20 | \
    awk '{printf "  %4d  %s\n", $1, $2}'
echo ""

# ─────────────────────────────────────────────
# 4. 项目趋势
# ─────────────────────────────────────────────
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  4. 项目趋势 (Project Momentum)${RESET}"
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${YELLOW}按月统计的提交数量${RESET}"
echo ""
git log --format='%ad' --date=format:'%Y-%m' 2>/dev/null | \
    sort | uniq -c | tail -24 | \
    awk '{printf "  %4d  %s\n", $1, $2}'
echo ""

# ─────────────────────────────────────────────
# 5. 救火频率
# ─────────────────────────────────────────────
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo -e "${BOLD}  5. 救火频率 (Crisis Patterns)${RESET}"
echo -e "${BOLD}───────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${YELLOW}过去一年中的 revert/hotfix/emergency/rollback 提交${RESET}"
echo ""

CRISIS_COMMITS=$(git log --oneline --since="1 year ago" 2>/dev/null | grep -iE 'revert|hotfix|emergency|rollback' || true)
CRISIS_COUNT=$(echo "$CRISIS_COMMITS" | grep -c . 2>/dev/null || echo "0")

if [ -z "$CRISIS_COMMITS" ]; then
    echo -e "  ${GREEN}未发现相关提交${RESET}"
    CRISIS_COUNT=0
else
    echo "$CRISIS_COMMITS" | while IFS= read -r line; do
        echo "  $line"
    done
    echo ""
    echo -e "  共 ${RED}${CRISIS_COUNT}${RESET} 条"
fi

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  诊断数据收集完毕，请根据以上数据进行综合分析${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
echo ""
