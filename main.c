#include <stdlib.h>
#include <stdio.h>


void nasm_printf(const char fmt[], ...);
void stdout_flush();

int main() {
    nasm_printf("min : %d\n", 1);
    nasm_printf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n",
               -1L, -1L, "love", 3802, 100, 33, 127,
                   -1L, "love", 3802, 100, 33, 127,
                   -1L, "love", 3802, 100, 33, 126
                   );
    // nasm_printf("%d %s %x %d%%%c%b\n", -1L, "love", 3802, 100L, 33L, 126L);
}
