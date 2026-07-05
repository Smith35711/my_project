cmake_minimum_required(VERSION 3.15)

# ============================================================
# 项目信息
# ============================================================
project(my_project VERSION 0.1.0 LANGUAGES C)

# ============================================================
# C11 标准
# ============================================================
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# 导出编译命令数据库（供 clang-tidy 等工具使用）
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ============================================================
# 编译器检测
# ============================================================
if(CMAKE_C_COMPILER_ID MATCHES "Clang")
    set(IS_CLANG TRUE)
elseif(CMAKE_C_COMPILER_ID MATCHES "GNU")
    set(IS_GCC TRUE)
endif()

# ============================================================
# Sanitizer 选项
# ============================================================
option(ENABLE_ASAN  "Enable AddressSanitizer"     ON)
option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" ON)
option(ENABLE_LSAN  "Enable LeakSanitizer"        ON)
option(ENABLE_TSAN  "Enable ThreadSanitizer"       OFF)
option(ENABLE_MSAN  "Enable MemorySanitizer (Clang only)" OFF)

# ============================================================
# 警告选项 — 开到最大
# ============================================================
set(COMMON_WARNINGS
    # ── 基础警告 ──
    -Wall
    -Wextra
    -Wpedantic
    -Werror                          # 所有警告视为错误

    # ── 阴影相关 ──
    -Wshadow
    -Wshadow-local
    -Wshadow-compatible-local

    # ── 格式相关 ──
    -Wformat=2
    -Wformat-overflow=2
    -Wformat-truncation=2
    -Wformat-security

    # ── 类型转换 ──
    -Wconversion
    -Wsign-conversion
    -Wfloat-conversion
    -Warith-conversion

    # ── 未定义行为检测 ──
    -Wnull-dereference
    -Wshift-overflow=2
    -Wshift-negative-value
    -Wint-in-bool-context
    -Wtautological-compare

    # ── 内存相关 ──
    -Warray-bounds=2
    -Wstringop-overflow=4
    -Wimplicit-fallthrough
    -Wstrict-overflow=5
    -Walloc-zero
    -Wduplicated-branches
    -Wduplicated-cond

    # ── 指针相关 ──
    -Wpointer-arith
    -Wcast-align=strict
    -Wwrite-strings

    # ── 初始化相关 ──
    -Wmissing-field-initializers
    -Wmissing-braces
    -Winit-self

    # ── 其他 ──
    -Wundef
    -Wunused-macros
    -Wcast-qual
    -Wstrict-prototypes
    -Wmissing-prototypes
    -Wredundant-decls
    -Wjump-misses-init
    -Wlogical-op
    -Wstrict-aliasing=3
    -Wswitch-default
    -Wswitch-enum
    -Wstack-usage=8192                # 单函数栈使用超过 8KB 警告
    -Wvla                             # 禁止变长数组
    -Wdate-time                       # 禁止 __DATE__/__TIME__（破坏可复现构建）
)

# GCC 专用警告
set(GCC_EXTRA_WARNINGS
    -Wsuggest-attribute=pure
    -Wsuggest-attribute=const
    -Wsuggest-attribute=noreturn
    -Wsuggest-final-types
    -Wsuggest-final-methods
    -Wtrampolines
    -Wvector-operation-performance
    -Wnormalized=nfkc
    -Wdisabled-optimization
    -Wmissing-parameter-type
    -Wold-style-declaration
    -Woverride-init
)

# Clang 专用警告
set(CLANG_EXTRA_WARNINGS
    -Weverything                      # Clang 的 "所有" 警告
    -Wno-c11-extensions              # 需要 C11 扩展
    -Wno-disabled-macro-expansion
    -Wno-padded
    -Wno-reserved-id-macro
    -Wno-documentation-unknown-command
)

# 组合警告选项
set(ALL_WARNINGS ${COMMON_WARNINGS})
if(IS_GCC)
    list(APPEND ALL_WARNINGS ${GCC_EXTRA_WARNINGS})
elseif(IS_CLANG)
    list(APPEND ALL_WARNINGS ${CLANG_EXTRA_WARNINGS})
endif()

add_compile_options(${ALL_WARNINGS})

# ============================================================
# Sanitizer 配置函数
# ============================================================
function(add_sanitizer_flags TARGET)
    set(SAN_FLAGS "")

    # ASan: 内存错误（越界、use-after-free、double-free）
    if(ENABLE_ASAN)
        if(NOT ENABLE_TSAN)  # ASan 与 TSan 互斥
            list(APPEND SAN_FLAGS -fsanitize=address)
            message(STATUS "[Sanitizer] AddressSanitizer  ENABLED")
        else()
            message(WARNING "[Sanitizer] AddressSanitizer  DISABLED（与 TSan 互斥）")
        endif()
    endif()

    # UBSan: 未定义行为（整数溢出、除零、空指针解引用、类型双关等）
    if(ENABLE_UBSAN)
        list(APPEND SAN_FLAGS -fsanitize=undefined)
        list(APPEND SAN_FLAGS -fsanitize=integer)
        list(APPEND SAN_FLAGS -fsanitize=nullability)
        list(APPEND SAN_FLAGS -fsanitize=alignment)
        list(APPEND SAN_FLAGS -fsanitize=bool)
        list(APPEND SAN_FLAGS -fsanitize=bounds)
        list(APPEND SAN_FLAGS -fsanitize=enum)
        list(APPEND SAN_FLAGS -fsanitize=float-cast-overflow)
        list(APPEND SAN_FLAGS -fsanitize=float-divide-by-zero)
        list(APPEND SAN_FLAGS -fsanitize=nonnull-attribute)
        list(APPEND SAN_FLAGS -fsanitize=returns-nonnull-attribute)
        list(APPEND SAN_FLAGS -fsanitize=signed-integer-overflow)
        list(APPEND SAN_FLAGS -fsanitize=unreachable)
        list(APPEND SAN_FLAGS -fsanitize=vla-bound)
        list(APPEND SAN_FLAGS -fno-sanitize-recover=all)  # 检测到未定义行为直接 abort
        message(STATUS "[Sanitizer] UndefinedBehaviorSanitizer  ENABLED")
    endif()

    # LSan: 内存泄漏（Linux 上已集成在 ASan 中，这里是独立开关）
    if(ENABLE_LSAN AND NOT ENABLE_ASAN)
        list(APPEND SAN_FLAGS -fsanitize=leak)
        message(STATUS "[Sanitizer] LeakSanitizer  ENABLED")
    elseif(ENABLE_ASAN)
        # ASan 内置了 LSan
        set(ENV{ASAN_OPTIONS} "detect_leaks=1:check_initialization_order=1:strict_string_checks=1:detect_stack_use_after_return=1")
        message(STATUS "[Sanitizer] LeakSanitizer  ENABLED（via ASan）")
    endif()

    # TSan: 数据竞争（与 ASan、MSan 互斥）
    if(ENABLE_TSAN)
        if(ENABLE_ASAN OR ENABLE_MSAN)
            message(FATAL_ERROR "[Sanitizer] TSan 与 ASan/MSan 互斥，请禁用 ASan 和 MSan 后再启用 TSan")
        endif()
        list(APPEND SAN_FLAGS -fsanitize=thread)
        message(STATUS "[Sanitizer] ThreadSanitizer  ENABLED")
    endif()

    # MSan: 未初始化内存读取（仅 Clang，与 ASan/TSan 互斥）
    if(ENABLE_MSAN)
        if(NOT IS_CLANG)
            message(FATAL_ERROR "[Sanitizer] MemorySanitizer 仅支持 Clang 编译器")
        endif()
        if(ENABLE_ASAN OR ENABLE_TSAN)
            message(FATAL_ERROR "[Sanitizer] MSan 与 ASan/TSan 互斥")
        endif()
        list(APPEND SAN_FLAGS -fsanitize=memory)
        list(APPEND SAN_FLAGS -fsanitize-memory-track-origins=2)
        message(STATUS "[Sanitizer] MemorySanitizer  ENABLED（Clang only）")
    endif()

    # 应用 sanitizer flags
    if(SAN_FLAGS)
        target_compile_options(${TARGET} PRIVATE ${SAN_FLAGS})
        target_link_options(${TARGET} PRIVATE ${SAN_FLAGS})
        message(STATUS "[Sanitizer] Flags: ${SAN_FLAGS}")
    endif()
endfunction()

# ============================================================
# Debug 专用选项
# ============================================================
add_compile_options(
    $<$<CONFIG:Debug>:-g3>                                      # 最详细的调试信息（含宏展开）
    $<$<CONFIG:Debug>:-O0>                                      # 不优化
    $<$<CONFIG:Debug>:-fno-omit-frame-pointer>                  # 保留帧指针（便于 perf/gdb）
    $<$<CONFIG:Debug>:-fstack-protector-strong>                 # 栈保护
    $<$<CONFIG:Debug>:-fcf-protection=full>                     # CET/IBT 保护（控制流完整性）
    $<$<CONFIG:Debug>:-D_FORTIFY_SOURCE=3>                      # 运行时缓冲区溢出检测
    $<$<CONFIG:Debug>:-fno-common>                              # 禁止 common 符号
)

add_link_options(
    $<$<CONFIG:Debug>:-fstack-protector-strong>
    $<$<CONFIG:Debug>:-Wl,-z,relro>
    $<$<CONFIG:Debug>:-Wl,-z,now>
    $<$<CONFIG:Debug>:-Wl,-z,noexecstack>
)

# ============================================================
# Release 优化选项
# ============================================================
add_compile_options(
    $<$<CONFIG:Release>:-O2>
    $<$<CONFIG:Release>:-DNDEBUG>
    $<$<CONFIG:Release>:-fstack-protector-strong>
    $<$<CONFIG:Release>:-D_FORTIFY_SOURCE=2>
    $<$<CONFIG:Release>:-flto>                                  # 链接时优化
)

add_link_options(
    $<$<CONFIG:Release>:-flto>
    $<$<CONFIG:Release>:-Wl,-z,relro>
    $<$<CONFIG:Release>:-Wl,-z,now>
)

# ============================================================
# 启用测试
# ============================================================
enable_testing()

# ============================================================
# 源代码
# ============================================================
file(GLOB_RECURSE SOURCES src/*.c)
file(GLOB_RECURSE HEADERS src/*.h)

# ============================================================
# 主可执行文件
# ============================================================
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/src
)

add_sanitizer_flags(${PROJECT_NAME})

# ============================================================
# 测试可执行文件
# ============================================================
if(EXISTS ${CMAKE_SOURCE_DIR}/tests)
    file(GLOB_RECURSE TEST_SOURCES tests/*.c)
    if(TEST_SOURCES)
        add_executable(test_runner ${TEST_SOURCES})
        target_include_directories(test_runner PRIVATE
            ${CMAKE_SOURCE_DIR}/src
            ${CMAKE_SOURCE_DIR}/tests
        )
        target_compile_definitions(test_runner PRIVATE TESTING)
        target_link_libraries(test_runner PRIVATE ${PROJECT_NAME})
        add_sanitizer_flags(test_runner)
        add_test(NAME all_tests COMMAND test_runner)
    endif()
endif()

# ============================================================
# 安装规则
# ============================================================
include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# ============================================================
# 辅助目标
# ============================================================
# cmake --build build --target check-asan     — 仅运行 ASan 构建
# cmake --build build --target check-tsan     — 仅运行 TSan 构建
# cmake --build build --target check-all      — 运行所有 sanitizer 检查

# 打印 sanitizer 配置摘要
add_custom_target(sanitizer-info
    COMMAND ${CMAKE_COMMAND} -E echo "=== Sanitizer 配置摘要 ==="
    COMMAND ${CMAKE_COMMAND} -E echo "ASan（内存错误）: $<BOOL:${ENABLE_ASAN}>"
    COMMAND ${CMAKE_COMMAND} -E echo "UBSan（未定义行为）: $<BOOL:${ENABLE_UBSAN}>"
    COMMAND ${CMAKE_COMMAND} -E echo "LSan（内存泄漏）: $<BOOL:${ENABLE_LSAN}>"
    COMMAND ${CMAKE_COMMAND} -E echo "TSan（数据竞争）: $<BOOL:${ENABLE_TSAN}>"
    COMMAND ${CMAKE_COMMAND} -E echo "MSan（未初始化内存）: $<BOOL:${ENABLE_MSAN}>"
    COMMAND ${CMAKE_COMMAND} -E echo "编译器: ${CMAKE_C_COMPILER_ID}"
    COMMAND ${CMAKE_COMMAND} -E echo "编译选项: ${CMAKE_C_FLAGS}"
)
