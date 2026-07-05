#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * @brief 读取配置文件，返回动态分配的字符串
 *
 * 编译零警告，但 cppcheck 可检测到逻辑问题
 */
char *read_config(const char *path);

char *read_config(const char *path)
{
    char *buf = (char *)malloc(256);
    if (buf == NULL) {
        return NULL;
    }

    FILE *fp = fopen(path, "r");
    if (fp == NULL) {
        /* BUG: 这里直接返回 NULL，但 buf 没有被释放 → 内存泄漏 */
        return NULL;
    }

    /* BUG: 未检查 fgets 返回值，buf 内容可能未初始化 */
    char *ret = fgets(buf, 256, fp);
    (void)ret;
    fclose(fp);

    return buf;
}

/**
 * @brief 复制字符串到堆上
 *
 * BUG: 未检查 src 是否为 NULL，传 NULL 会崩溃
 */
char *dup_string(const char *src);  /* 前置声明 */

char *dup_string(const char *src)
{
    size_t len = strlen(src);       /* 如果 src == NULL，这里段错误 */
    char *dst = (char *)malloc(len + 1);
    if (dst != NULL) {
        strcpy(dst, src);
    }
    return dst;
}
