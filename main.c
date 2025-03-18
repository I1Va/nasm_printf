#include <string.h>
#include <stdio.h>

void _ntoa_long_long(unsigned long long value)
{
    char buf[128] = {};
    size_t len = 0U;
    unsigned long long base = 16;

    // write if precision != 0 and value is != 0
    do {
        const char digit = (char)(value % base);
        buf[len++] = digit < 10 ? '0' + digit : 'a' + digit - 10;
        value /= base;
        } while (value && (len < 128));
    printf("bufer : '%s'\n", buf);
}


int main() {
    unsigned long long val;
    scanf("%Lu", &val);
    _ntoa_long_long(val);
}
