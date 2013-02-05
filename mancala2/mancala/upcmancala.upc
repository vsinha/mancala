#include <stdio.h>
#include <string.h>
#include <upc.h>

#define NPOTS 6

shared [] int shared_board[(NPOTS+1)*2];
shared int best_score[NPOTS];

int board[(NPOTS+1)*2];

int main()
{
    if (MYTHREAD == 0)
    {
        /* ask for move, make the move, print the board. */	
    }
    upc_barrier;
    upc_memget (board, shared_board, sizeof (board));
    return 0;
}
