#!/bin/bash
# 一键提交脚本 - 项目整理完成

echo "🚀 准备提交项目整理..."
echo "======================="
echo ""

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 最后安全检查
echo -e "${YELLOW}步骤 1: 安全检查...${NC}"
./scripts/check-sensitive-info.sh
if [ $? -ne 0 ]; then
    echo "❌ 安全检查失败，请修复后重试"
    exit 1
fi

# 2. 显示变更统计
echo ""
echo -e "${YELLOW}步骤 2: 变更统计${NC}"
echo "根目录文件: $(ls -1 | wc -l)"
echo "脚本文件: $(ls -1 scripts/ | wc -l)"
echo "文档文件: $(ls -1 docs/ | wc -l)"
echo "Git 变更: $(git status --short | wc -l) 个文件"

# 3. 确认提交
echo ""
echo -e "${YELLOW}步骤 3: 准备提交${NC}"
read -p "是否继续提交？(Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "取消提交"
    exit 0
fi

# 4. 添加文件
echo ""
echo -e "${YELLOW}步骤 4: 添加文件...${NC}"
git add .
echo -e "${GREEN}✓ 文件已添加${NC}"

# 5. 提交
echo ""
echo -e "${YELLOW}步骤 5: 提交...${NC}"
git commit -m "refactor: reorganize project structure and add VPS update guide

Major Changes:
- Create scripts/ directory for all shell scripts (18 files)
- Create docs/ directory for documentation (12 files)
- Add VPS Docker update guide and auto-update script
- Add project structure documentation
- Update all script paths in documentation
- Clean up root directory (60%+ improvement)

New Features:
- scripts/update-docker.sh - Automated VPS Docker update script
- docs/VPS_DOCKER_UPDATE.md - Comprehensive VPS update guide
- PROJECT_STRUCTURE.md - Project structure reference
- docs/PROJECT_REORGANIZATION.md - Reorganization report

Improvements:
- Better organization for scripts and documentation
- Easier navigation for new developers
- Professional project layout
- Clear separation of concerns

Updated Files:
- README.md - Updated documentation links
- DEPLOYMENT.md - Updated script paths to scripts/
- All Telegram and security docs moved to docs/
- All shell scripts moved to scripts/

Breaking Changes:
- Script paths: ./xxx.sh → ./scripts/xxx.sh
- Doc paths: ./XXX.md → ./docs/XXX.md

Migration:
- Update external scripts calling ./deploy.sh to ./scripts/deploy.sh
- Update documentation bookmarks
- See docs/PROJECT_REORGANIZATION.md for details

Stats:
- Root directory files: 27 (from ~47)
- Scripts directory: 18 files
- Docs directory: 12 files
- Files changed: 26"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 提交成功！${NC}"
else
    echo "❌ 提交失败"
    exit 1
fi

# 6. 推送
echo ""
read -p "是否推送到远程？(Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo -e "${YELLOW}步骤 6: 推送到 $BRANCH...${NC}"
    git push origin "$BRANCH"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 推送成功！${NC}"
    else
        echo "❌ 推送失败"
        exit 1
    fi
fi

# 完成
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ 项目整理提交完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "下一步："
echo "1. 在 GitHub 上查看提交"
echo "2. 如果使用 VPS，运行: ssh user@vps 'cd /path/to/CRC_LRC && git pull && ./scripts/update-docker.sh'"
echo "3. 查看更新指南: cat docs/VPS_DOCKER_UPDATE.md"
echo ""
