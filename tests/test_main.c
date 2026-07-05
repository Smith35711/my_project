#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * @brief 测试 ASan 检测堆缓冲区溢出
 */
static void test_heap_overflow(void)
{
    /* 只分配了 8 字节 */
    char *buf = (char *)malloc(8);
    if (!buf) {
        fprintf(stderr, "malloc failed\n");
        return;
    }

    /* BUG: 写入 20 字节，超出分配范围，触发 heap-buffer-overflow */
    strcpy(buf, "Hello, World! This is a buffer overflow!");
    printf("buf = %s\n", buf);

    free(buf);
}

int main(void)
{
    printf("=== Hello World Smoke Test ===\n");
    printf("Running heap overflow test...\n");
    test_heap_overflow();  /* ASan 应该在这里捕获到越界写入 */
    printf("PASS: test_runner executed successfully\n");
    return 0;
}
