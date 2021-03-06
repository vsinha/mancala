#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <limits.h>
#include <time.h>

#define BOARDSIZE      14
#define P0POT          BOARDSIZE/2 - 1
#define P1POT          BOARDSIZE - 1
#define NUM_POTS       P0POT
#define START_AMOUNT   4
#define STARTMAXDEPTH  10
#define ARGNUMBER      8

struct move_score_struct
{
    int move;
    int score;
}; 
typedef struct move_score_struct move_score_pair_t;


int getInput(int whosTurn, int checkSwitch, int board[]);
int disp(int board[]);
void initArray(int board[]);
int checkForWin(int board[]);
int sum(int board[], int start, int finish);
int move(int board[], int whosTurn, int startBowl);
int endGame(int board[], int winStatus);
int addToPot(int board[], int currentBowl, int whosTurn);
int best_move(int board[], int player, int *best_score);
int eval_max(int board[], int player, int level, int *best_move, int alpha, int beta);
int eval_min(int board[], int player, int level, int *best_move, int alpha, int beta);
int clearPebbles(int board[]);
int randomMove();
int getRand(int min, int max);

int debug = 0;
long int num_nodes = 0;
int turnCounter = 0;
int max_depth = STARTMAXDEPTH;

shared int do_alpha_beta_arg = 0;
shared int do_sort_arg = 0;
int do_deepen = 0;
int do_weighted_scoring = 0;
int do_random = 0;
char print_flag[ARGNUMBER];
FILE *stats_file;
FILE *wins_file;

int main(int argc, char *argv[])
{
    int i;
    int board[BOARDSIZE];
    int startBowl; //the bowl chosen by the player
    int whosTurn = 0;  //which player's turn it is initially
    int winStatus = 0;
    int checkSwitch = 1;

    stats_file = fopen("stats.txt", "a");
    wins_file  = fopen("wins.txt" , "a");
    if (!stats_file || !wins_file)
    {
	perror ("fopen of output file failed (either wins.txt or stats.txt)\n");
	abort ();
    }
  
    if (argc >= 2)
    {
	int i;
	for (i = 1; i < argc; i++)
	{
	    fprintf(stats_file, "%c ", *argv[i]);

	    switch (*argv[i])
	    {
		case 'a': //all
		    do_alpha_beta_arg = 1;
		    do_sort = 1;
		    do_deepen = 1;
		    do_weighted_scoring = 1;
		    do_random = 1;
		    break;
		case 'd': //deepening
		    do_deepen = 1;
		    break;
		case 'p': //prune
		    do_alpha_beta = 1;
		    break;
		case 'r': //computer plays random player
		    do_random = 1;
		    break;
		case 's': //sort
		    do_sort = 1;
		    break;
		case 'w': //weighted scoring
		    do_weighted_scoring = 1;
		    break;
		case 'n': //no.
		    do_alpha_beta = 0;
		    do_sort = 0;
		    do_deepen = 0;
		    do_weighted_scoring = 0;
		    do_random = 0;
		    break;
		default:
		    abort ();
	    }
	}
    }

    fprintf(stats_file, "\n");
    fflush(stats_file);
    initArray(board);

    while (!winStatus)//main loop
    {
        disp(board);
        if (!checkSwitch)
        {
            printf("\n**Player %d gets another turn!**\n", whosTurn);
        }
        startBowl = getInput(whosTurn, checkSwitch, board);
        checkSwitch = move(board, whosTurn, startBowl);
        winStatus = checkForWin(board);
        if (checkSwitch)
        {
            whosTurn = !whosTurn;
        }
    }
    
    printf("\n======Final Score======\n");
    winStatus = checkForWin(board);
    clearPebbles(board);
    disp(board);
    endGame(board, winStatus);

    fclose (stats_file);
    fclose (wins_file);
    return 0;
}

int move(int board[], int whosTurn, int startBowl)//returns 1 to change players, 0 to repeat turn
{
    int i;
    int value;
    int currentBowl;
    int checkSwitch = 1;

    value = board[startBowl];
    board[startBowl] = 0;
    currentBowl = ++startBowl;

    while (value)
    {
        if ((whosTurn == 0 && currentBowl != P1POT) ||
            (whosTurn == 1 && currentBowl != P0POT))
        {
            board[currentBowl]++;
            value--;
        }
        
        //calls addToPot
        if ((board[currentBowl] == 1 && value == 0 && (currentBowl != P0POT && currentBowl != P1POT)))
        {
            addToPot(board, currentBowl, whosTurn);
            // printf("Player %d captured bowl %d!\n", whosTurn, currentBowl);
        }

        //this gives the player another turn if he puts his last pebble in his pot
        if ((whosTurn == 0 && currentBowl == P0POT && value == 0) ||
            (whosTurn == 1 && currentBowl == P1POT && value == 0))
        {
            checkSwitch = 0;
        }
        
        //printf("value = %d\ncurrentBowl = %d\n", value, currentBowl);
        currentBowl++;
        
        //loop the numbers around
        currentBowl = currentBowl % BOARDSIZE;
        if (currentBowl == BOARDSIZE)
        {
            currentBowl = 0;
        }
    }
        
    return checkSwitch;
}

int addToPot(int board[], int currentBowl, int whosTurn)
{ 
    int clearbowls = 0;
    if(board[BOARDSIZE - currentBowl - 2])
    {
        if (whosTurn == 0 && currentBowl < P0POT && currentBowl > 0) 
        {
            board[P0POT] += board[currentBowl];
            board[P0POT] += board[BOARDSIZE - currentBowl - 2];
            clearbowls++;
        }
        else if (whosTurn == 1 && currentBowl < P1POT && currentBowl > P0POT)
        {
            board[P1POT] += board[currentBowl];
            board[P1POT] += board[BOARDSIZE - currentBowl - 2];
            clearbowls++;
        }
    }
    if (clearbowls)
    {
        board[currentBowl] = 0;
        board[BOARDSIZE - currentBowl - 2] = 0;
    }

    return 0;
}

int endGame(int board[], int winStatus)
{
    int p0 = board[P0POT];
    int p1 = board[P1POT];

    printf("Player 0: %d\n", p0);
    printf("Player 1: %d\n", p1);

    switch (winStatus)
    {
        case 1: 
            printf("Player 0 wins!\n");
            break;
        case 2: 
            printf("Player 1 wins!\n");
            break;
        case 3: 
            printf("Tie game\n");
            break;
    }

    fprintf(wins_file, "Player 0: %2d | Player 1: %2d\n", p0, p1);
    fflush(wins_file);

    return 0;
}

int clearPebbles(int board[])
{
    int sum0 = sum(board, 0, P0POT-1);
    int sum1 = sum(board, P0POT + 1, P1POT-1);
    board[P0POT] += sum0;
    board[P1POT] += sum1;
    

    //clear remaining holes
    int i;
    for (i = 0; i < P1POT; ++i)
    {
        if (i != P0POT && i != P1POT)
        {
            board[i] = 0;
        }
    }

    //printf("\nPlayer 0 gets %d remaining pebbles\n", sum0);
    //printf("Player 1 gets %d remaining pebbles\n", sum1);
    
    return 0;
}


int randomMove()
{
    int n, i;
    srand(time(NULL));

    int min, max;

    min = 0;
    max = 6;
    for(i = 0; i < getRand(1,13); i++)
    {
	n = getRand(min, max);
    }

    return n;    
}

int getRand (int min, int max)
{
    return((rand() % (max-min)) + min);
}

int getInput(int whosTurn, int checkSwitch, int board[])
{
    int startBowl;
    int error = 1; //allow it to enter the while loop
    
    if (checkSwitch)
    {
        printf("\n======Player %d move======\n", whosTurn);
    }
    while (error)
    {
        error = 0;
        if (whosTurn == 0)
        {
            printf("Select a cup of stones from 0-5 to move: ");
        }
        else if (whosTurn == 1)
        {
            printf("Select a cup of stones from 7-12 to move: ");
        }
        
        if (whosTurn == 0)
        {
	    if (do_random)
	    {
		startBowl = randomMove();
		while (!board[startBowl])
		{
		    startBowl = randomMove();
		}
	    }
	    else
	    {
		scanf ("%d", &startBowl);
	    }
	    turnCounter++;
        }
        else
        {
            turnCounter++;
            int best_score, prev_num_nodes = -1;
	    if (!MYTHREAD)
	      upc_memput (shared_board, board);
	    upc_barrier;
	    upc_memget (work_board, shared_board);
	    if (can_make_move (work_board, MYTHREAD))
	    {
		make_move (work_board, MYTHREAD);
		if (do_deepen)
		{
		    max_depth = 6;
		    num_nodes = 0;
		    do{
		      prev_num_nodes = num_nodes;
		      num_nodes = 0;
		      startBowl = best_move(work_board, whosTurn, &best_score);
		      ++max_depth;
		    }while(num_nodes < 1000000 && prev_num_nodes < num_nodes);
		}
		else
		{
		    startBowl = best_move(work_board, whosTurn, &best_score);
		}
	    }
	    upc_barrier:
	    if (!MYTHREAD)
	    {
		fprintf(stats_file, "predict: %d", best_score);
		fflush(stats_file);
	    }
            //printf("\nalpha beta: Computer entered %d; score: %d; nodes: %03ld %03ld %03ld\n",
            //     startBowl, best_score, num_nodes/1000000, num_nodes%1000000/1000, num_nodes%1000);
        }

        //sanitize inputs
        if (whosTurn == 0 && ((startBowl < 0 || startBowl >= P0POT) || startBowl == P0POT))
        {
            error = 1;
        }
        if (whosTurn == 1 && ((startBowl <= P0POT || startBowl >= P1POT) || startBowl == P1POT))
        {   
            error = 1;
        }
        if (error)
        {
            printf("Please enter a valid input...\n");
        }
        if (!board[startBowl])
        {
            error = 1;
            printf("This cup is empty...\n");
        }
    }

    printf("\n");
    return startBowl;
}

int checkForWin(int board[])
{
    //returns 1 for player0 win
    //        2 for player1 win
    //        3 for tie
    //        0 for no win

    int checkScores = 0;
    int status = 0;
    int i;

    if(sum(board, 0, P0POT-1) == 0)
    {
        checkScores = 1;
    }
    if(sum(board, P0POT+1, P1POT-1) == 0)
    {
        checkScores = 1;
    }

    if(checkScores)
    {
        if (board[P0POT] > board[P1POT])
        {
            status = 1;
        }
        else if (board[P0POT] < board[P1POT])
        {
            status = 2;
        }
        else if (board[P0POT] == board[P1POT])
        {
            status = 3;
        }
    }
    
    return status;
}

int sum(int board[], int start, int finish) //inclusive sum
{
    int i;
    int total = 0;

    for (i = start; i <= finish; i++)
    {
        total += board[i];
    }
    return total;
}

void initArray(int board[])
{
    int i;

    for (i = 0; i < BOARDSIZE; i++) //fill the array with pebbles
    {
        if (i == P0POT || i == P1POT)
        {
            board[i] = 0;
        }
        else
        {
            board[i] = START_AMOUNT;
        }
    }
}

int disp(int board[])
{
    int i;
    
    printf("   ");
    for (i = P1POT-1; i >= P0POT+1; i--)
    {
        printf("%4d", i);
    }
    printf("   \n");

    printf("|  |");
    for (i = P1POT-1; i >= P0POT+1; i--)
    {
        printf("[%2d]", board[i]);
    }
    printf("|  |\n");
    printf("|%2d|", board[P1POT]);
    for (i = P1POT-1; i>=P0POT+1; i--)
    {
        printf("    ");
    }
    printf("|%2d|\n", board[P0POT]);
    printf("|  |");
    for (i = 0; i<P0POT; i++)
    {
        printf("[%2d]", board[i]);
    }
    printf("|  |\n");
    printf("   ");
    for (i = 0; i < P0POT; i++)
    {
        printf("%4d", i);
    }
    printf("\n");
    
    fprintf(stats_file, "\n#:%2d | depth:%2d | nodes:%10ld |", turnCounter, max_depth, num_nodes);
    fflush(stats_file);

    return 0;
}


//****computer player code starts here****

int best_move (int board[], int player, int *best_score)
{
    int score, move;
    int alpha = INT_MIN;
    int beta  = INT_MAX;
    num_nodes = 0;
    
    *best_score = eval_max(board, player, max_depth, &move, alpha, beta);
    return move;
}

int eval_max (int board[], int player, int level, int *best_move, int alpha, int beta)
{
    num_nodes += 1;
    int result;
    if (level > 0 && !checkForWin(board))
    {
        move_score_pair_t choice[NUM_POTS];
        int best_eval = INT_MIN;
        int eval_move;
	int nchoice = 0;
	int p;

	for (p = P0POT+1; p < P1POT; p++) //go through each option
	{
	    if (board[p]) //if a valid move
	    {
		int tscore = 0;
		int tmove = p;
		int k = nchoice;
		if (do_sort) //fill choice[] with insertion sort
		{
		    int sort_board[BOARDSIZE];
		    int move_again;
		    memcpy (sort_board, board, sizeof(int) * BOARDSIZE);
		    move_again = move (sort_board, player, tmove);
		    tscore = sort_board[P1POT];
		    if (do_weighted_scoring)
		    {
			tscore = tscore * 100 + sum(sort_board, P0POT+1, P1POT-1);
		    }
		    while (k > 0 && choice[k-1].score < tscore)
		    {
			choice[k].score = choice[k-1].score;
			choice[k].move  = choice[k-1].move;
			k -= 1;
		    }
		}
		choice[k].move  = tmove;
		choice[k].score = tscore;

		if (debug && choice[k].score > 5)
		{
		    printf("debug: max choice[%d].score = %2d", k, choice[k].score);
		    int jj;
		    for (jj = 0; jj <= choice[k].score; jj++)
		    {
			printf("|");
		    }
		    printf("\n");
		}

		nchoice += 1;
	    }
	}

	int c;
        for (c = 0; c < nchoice; ++c)
        {
	    int p = choice[c].move;
            if (board[p])
            {
                int eval_board[BOARDSIZE];
                int move_again;
                int this_eval;
                memcpy (eval_board, board, sizeof(int) * BOARDSIZE);
                move_again = !move (eval_board, player, p);
                if (move_again)
                {
                    this_eval = eval_max (eval_board, player, level, NULL, alpha, beta);
                }
                else
                {
                    this_eval = eval_min (eval_board, !player, level-1, NULL, alpha, beta);
                }
                if (this_eval > best_eval)
                {
                    best_eval = this_eval;
		    if (this_eval > alpha)
		    {
			alpha = this_eval;
		    }
		    if (do_alpha_beta && alpha >= beta)
		    {
			return best_eval;
		    }
                    eval_move = p;
                }
            }
        }
        if (best_move != NULL)
        {
            *best_move = eval_move;
        }
        return best_eval;
    }

    clearPebbles(board);
    return board[P1POT];
}

int eval_min (int board[], int player, int level, int *best_move, int alpha, int beta)
{
    num_nodes += 1;
    int result;
    if (level > 0 && !checkForWin(board))
    {
	move_score_pair_t choice[NUM_POTS];
	int nchoice = 0;
        int best_eval = INT_MAX;
        int eval_move;
	int p;

	for (p = 0; p < NUM_POTS; p++) //go through each option
	{
	    if (board[p]) //if a valid move
	    {
		int tscore = 0;
		int tmove = p;
		int k = nchoice;
		if (do_sort)
		{
		    int sort_board[BOARDSIZE];
		    int move_again;
		    memcpy (sort_board, board, sizeof(int) * BOARDSIZE);
		    move_again = move (sort_board, player, tmove);
		    tscore = sort_board[P1POT];
		    if (do_weighted_scoring)
		    {
			tscore = (move_again * 1000) + 
				 (tscore * 100)      + 
				 sum(sort_board, 0, P0POT-1);
		    }
		    while (k > 0 && choice[k-1].score < tscore)
		    {
			choice[k].score = choice[k-1].score;
			choice[k].move  = choice[k-1].move;
			k -= 1;
		    }
		}
		choice[k].move  = tmove;
		choice[k].score = tscore;
		if (debug && choice[k].score > 5)
		{
		    printf("debug: MIN choice[%d].score = %2d", k, choice[k].score);
		    int jj;
		    for (jj = 0; jj <= choice[k].score; jj++)
		    {
			printf("|");
		    }
		    printf("\n");
		}
		nchoice += 1;
	    }
	}

	int c;
        for (c = 0; c < nchoice; ++c)
        {
	    p = choice[c].move;
            if (board[p])
            {
                int eval_board[BOARDSIZE];
                int move_again;
                int this_eval;
                memcpy (eval_board, board, sizeof(int) * BOARDSIZE);
                move_again = !move (eval_board, player, p);
                if (move_again)
                {
                    this_eval = eval_min (eval_board, player, level, NULL, alpha, beta);
                }
                else
                {
                    this_eval = eval_max (eval_board, !player, level-1, NULL, alpha, beta);
                }
                if (this_eval < best_eval)
                {
                    best_eval = this_eval;
		    if (this_eval < beta)
		    {
			beta = this_eval;
		    }
                    if (do_alpha_beta && alpha >= beta)
		    {
			return best_eval;
		    }
		    eval_move = p;
                }
            }
        }
        if (best_move != NULL)
        {
            *best_move = eval_move;
        }
        return best_eval;
    }

    clearPebbles(board);
    return board[P1POT];
}
