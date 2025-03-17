build:
	nasm -f elf64 -l main.lst main.s
	ld -s -o main.out main.o
