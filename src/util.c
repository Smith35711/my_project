#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * @brief 读取配置文件，返回动态分配的字符串
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
        free(buf);               /* 修复: 释放已分配的内存 */
        return NULL;
    }

    char *ret = fgets(buf, 256, fp);
    fclose(fp);
    if (ret == NULL) {
        free(buf);               /* 修复: fgets 失败时也释放 */
        return NULL;
    }

    return buf;
}

/**
 * @brief 复制字符串到堆上
 */
char *dup_string(const char *src);

char *dup_string(const char *src)
{
    if (src == NULL) {           /* 修复: 空指针检查 */
        return NULL;
    }
    size_t len = strlen(src);
    char *dst = (char *)malloc(len + 1);
    if (dst != NULL) {
        strcpy(dst, src);
    }
    return dst;
}
