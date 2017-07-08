#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* arg[])
{
	printf("short: \t%i\n", sizeof(short));
	printf("int: \t%i\n", sizeof(int));
	printf("long: \t%i\n", sizeof(long));
	printf("float: \t%i\n", sizeof(float));
	printf("double: \t%i\n", sizeof(double));

	printf("long int: \t%i\n", sizeof(long int));
	printf("long long: \t%i\n", sizeof(long long));
	printf("long double: \t%i\n", sizeof(long double));

	return 0;
}
