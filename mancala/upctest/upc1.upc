#include <upc.h>
#include <stdio.h>

int main(intr argc, char *argv[])
{
    int i;
    for (i = 0; i < THREADS; ++i)
    {
	upc_barrier;
	if (i == MYTHREAD)
	    printf("Hello world from thread: %d\n", MYTHREAD);
    }
    return 0;
}
