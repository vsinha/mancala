#include <upc.h>
#include <stdlib.h>

#define BOARD_SIZE 15

shared [BOARD_SIZE] int shared_board[THREADS][BOARD_SIZE];

int main ()
{
    int i;
    int board[BOARD_SIZE];
    if (!MYTHREAD)
    {
	int t;
	for (i = 0; i < BOARD_SIZE; ++i)
	    board[i] = (i + 1);
	for (t = 0; t < THREADS; ++t)
	    upc_memput (&shared_board[t][0], board, sizeof (board));
    }
    upc_barrier;
    if (MYTHREAD)
      upc_memget (board, &shared_board[MYTHREAD][0], sizeof (board));
    upc_barrier;
    for (i = 0; i < BOARD_SIZE; ++i)
	if (board[i] != (i + 1))
	    abort ();
}
