#include "io.h"

int fibonacci(int x) {
	if (x <= 2) return 1;
	else return (fibonacci(x-1) + fibonacci(x-2));
}

int main() {
	println("f1");
	outlln(fibonacci(1));
	println("f5");
	outlln(fibonacci(5));
	println("f10");
	outlln(fibonacci(10));
	return 0;
}