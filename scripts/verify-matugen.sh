#!/bin/bash
# Matugen + NvChad Integration Verification Script

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NVIM_CONFIG="$HOME/.config/nvim"
MATUGEN_CONFIG="$HOME/.config/matugen"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Verifying Matugen + NvChad Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Counter for passed checks
PASSED=0
TOTAL=0

# Check 1: NvChad installation
TOTAL=$((TOTAL + 1))
if [ -d "$NVIM_CONFIG" ]; then
  echo -e "${GREEN}✓${NC} NvChad config directory exists"
  PASSED=$((PASSED + 1))
else
  echo -e "${RED}✗${NC} NvChad config directory not found"
fi

# Check 2: Matugen integration module
TOTAL=$((TOTAL + 1))
if [ -f "$NVIM_CONFIG/lua/configs/matugen.lua" ]; then
  echo -e "${GREEN}✓${NC} Matugen integration module installed"
  PASSED=$((PASSED + 1))
else
  echo -e "${RED}✗${NC} Matugen integration module not found"
fi

# Check 3: Updated chadrc.lua
TOTAL=$((TOTAL + 1))
if [ -f "$NVIM_CONFIG/lua/chadrc.lua" ]; then
  if grep -q "matugen" "$NVIM_CONFIG/lua/chadrc.lua"; then
    echo -e "${GREEN}✓${NC} chadrc.lua configured for matugen"
    PASSED=$((PASSED + 1))
  else
    echo -e "${YELLOW}⚠${NC}  chadrc.lua exists but may not have matugen config"
  fi
else
  echo -e "${RED}✗${NC} chadrc.lua not found"
fi

# Check 4: Autocmds
TOTAL=$((TOTAL + 1))
if [ -f "$NVIM_CONFIG/lua/autocmds.lua" ]; then
  if grep -q "MatugenReload" "$NVIM_CONFIG/lua/autocmds.lua"; then
    echo -e "${GREEN}✓${NC} Auto-reload functionality configured"
    PASSED=$((PASSED + 1))
  else
    echo -e "${YELLOW}⚠${NC}  autocmds.lua exists but auto-reload not found"
  fi
else
  echo -e "${RED}✗${NC} autocmds.lua not found"
fi

# Check 5: Matugen installation
TOTAL=$((TOTAL + 1))
if command -v matugen &> /dev/null; then
  echo -e "${GREEN}✓${NC} Matugen is installed"
  PASSED=$((PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC}  Matugen command not found (install it separately)"
fi

# Check 6: Colors file
TOTAL=$((TOTAL + 1))
if [ -f "$MATUGEN_CONFIG/templates/colors.json" ]; then
  # Check if it has actual colors or template placeholders
  if grep -q "{{colors" "$MATUGEN_CONFIG/templates/colors.json" 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC}  colors.json has template placeholders (run 'matugen generate')"
  else
    echo -e "${GREEN}✓${NC} colors.json exists with generated colors"
    PASSED=$((PASSED + 1))
  fi
else
  echo -e "${YELLOW}⚠${NC}  colors.json not found (run 'matugen generate')"
fi

# Check 7: Backups exist
TOTAL=$((TOTAL + 1))
if ls "$NVIM_CONFIG/lua/chadrc.lua.backup"* 1> /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Backup files found"
  PASSED=$((PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC}  No backup files found (might be fresh install)"
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "Result: ${GREEN}$PASSED${NC}/${TOTAL} checks passed"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $PASSED -eq $TOTAL ]; then
  echo -e "${GREEN}✅ All checks passed! Your setup looks good.${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Make sure matugen has generated colors: matugen generate"
  echo "2. Open Neovim to see your colors: nvim"
  echo "3. Check for any errors: :messages"
elif [ $PASSED -ge 4 ]; then
  echo -e "${YELLOW}⚠ Setup is mostly complete, but some optional items missing.${NC}"
  echo ""
  echo "You can proceed, but consider:"
  echo "- Running 'matugen generate' if colors aren't working"
  echo "- Checking the installation guide for troubleshooting"
else
  echo -e "${RED}❌ Setup appears incomplete.${NC}"
  echo ""
  echo "Please run the setup script:"
  echo "  ./setup_matugen.sh"
fi

echo ""
