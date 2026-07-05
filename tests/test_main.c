#include <stdio.h>

/**
 * @brief 最简单的冒烟测试：验证编译产物可正常运行
 *
 * 这个测试在 test_runner 进程内执行，不依赖外部可执行文件。
 * 真正的功能和集成测试可在此基础上扩展。
 */
int main(void)
{
    printf("=== Hello World Smoke Test ===\n");
    printf("PASS: test_runner executed successfully\n");
    return 0;
}
