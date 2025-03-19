#include <stdlib.h>

void nasm_printf(const char fmt[], ...);
void stdout_flush();

int main() {
    atexit(stdout_flush);

    nasm_printf("printf message:\n");
    nasm_printf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n",
               -1, -1, "love", 3802, 100, 33, 127,
                   -1, "love", 3802, 100, 33, 127);
}

