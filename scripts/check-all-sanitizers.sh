#!/bin/bash
# ============================================================
# 全量 Sanitizer 检查脚本
# 对代码进行 ASan / UBSan / TSan 三个维度的检查
# ============================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_BASE="${PROJECT_ROOT}/build"
LOG_DIR="${PROJECT_ROOT}/build/sanitizer-logs"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0

mkdir -p "$LOG_DIR"

log_pass()  { echo -e "${GREEN}[PASS]${NC} $*"; }
log_fail()  { echo -e "${RED}[FAIL]${NC} $*"; }
log_info()  { echo -e "${YELLOW}[INFO]${NC} $*"; }

run_sanitizer_build() {
    local name="$1"
    local cmake_opts="$2"
    local build_dir="${BUILD_BASE}/san-${name}"
    local log_file="${LOG_DIR}/${name}-${TIMESTAMP}.log"

    log_info "============================================"
    log_info "  ${name} 检查"
    log_info "============================================"

    # 配置
    log_info "配置 cmake ..."
    if ! cmake -B "$build_dir" $cmake_opts > "$log_file" 2>&1; then
        log_fail "${name} — cmake 配置失败"
        cat "$log_file"
        ((failed++))
        return 1
    fi

    # 构建
    log_info "编译 ..."
    if ! cmake --build "$build_dir" --parallel $(nproc) >> "$log_file" 2>&1; then
        log_fail "${name} — 编译失败"
        tail -50 "$log_file"
        ((failed++))
        return 1
    fi

    # 运行测试
    log_info "运行测试 ..."
    if (cd "$build_dir" && ctest --output-on-failure >> "$log_file" 2>&1); then
        log_pass "${name} — 全部通过"
        ((passed++))
    else
        log_fail "${name} — 测试失败（详见 ${log_file}）"
        tail -30 "$log_file"
        ((failed++))
    fi
}

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║          全量 Sanitizer 检查                          ║"
echo "║  时间: $(date '+%Y-%m-%d %H:%M:%S')                              ║"
echo "║  日志: ${LOG_DIR}                                     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── 1. ASan + UBSan + LSan（默认 Debug） ──
run_sanitizer_build "asan-ubsan" \
    "-DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON -DENABLE_UBSAN=ON -DENABLE_LSAN=ON -DENABLE_TSAN=OFF -DENABLE_MSAN=OFF"

# ── 2. TSan 独立检查（与 ASan 互斥） ──
run_sanitizer_build "tsan" \
    "-DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=OFF -DENABLE_UBSAN=OFF -DENABLE_LSAN=OFF -DENABLE_TSAN=ON -DENABLE_MSAN=OFF"

# ── 3. 编译时检查（不运行，仅确保 -Wall -Werror 无警告） ──
log_info "============================================"
log_info "  编译时警告检查（-Wall -Werror）"
log_info "============================================"
build_dir="${BUILD_BASE}/warncheck"
log_file="${LOG_DIR}/warnings-${TIMESTAMP}.log"
if cmake -B "$build_dir" -DCMAKE_BUILD_TYPE=Debug > "$log_file" 2>&1 && \
   cmake --build "$build_dir" --parallel $(nproc) >> "$log_file" 2>&1; then
    log_pass "编译时警告 — 无警告通过"
    ((passed++))
else
    log_fail "编译时警告 — 有警告（详见 ${log_file}）"
    grep -E 'warning:|error:' "$log_file" | head -20
    ((failed++))
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  检查完成                                            ║"
echo "║  通过: ${passed}  失败: ${failed}                                     ║"
echo "║  日志目录: ${LOG_DIR}                                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

if [ "$failed" -gt 0 ]; then
    exit 1
fi
