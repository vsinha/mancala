#include <stdio.h>
#include <string.h>
#include <stddef.h>
#include <limits.h>
#define BOARDSIZE      14
#define P0POT          BOARDSIZE/2 - 1
#define P1POT          BOARDSIZE - 1
#define START_AMOUNT   4

int getInput(int whosTurn, int checkSwitch, int board[]);
int disp(int board[]);
void initArray(int board[]);
int checkForWin(int board[]);
int sum(int board[], int start, int finish);
int move(int board[], int whosTurn, int startBowl);
int endGame(int board[], int winStatus);
int addToPot(int board[], int currentBowl, int whosTurn);
int best_move(int board[], int player, int *best_score);
int eval_max(int board[], int player, int level, int *best_move);
int eval_min(int board[], int player, int level, int *best_move);
int clearPebbles(int board[]);

int debug = 1;
long int num_nodes = 0;
int turnCounter = 0;
int max_depth = 6;

int main()
{
    int i;
    int board[BOARDSIZE];
    int startBowl; //the bowl chosen by the player
    int whosTurn = 1;  //which player's turn it is initially
    int winStatus = 0;
    int checkSwitch;

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
    clearPebbles(board);
    disp(board);
    endGame(board, winStatus);
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
    printf("Player 0: %d\n", board[P0POT]);
    printf("Player 1: %d\n", board[P1POT]);

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
        
        if (whosTurn == 0) //human goes first
        {
            scanf ("%d", &startBowl);
            turnCounter++;
        }
        else
        {
            turnCounter++;
            max_depth = 5 + ((turnCounter/10) * 2);
            int best_score;
            startBowl = best_move(board, whosTurn, &best_score);
            printf("\nComputer entered %d; score: %d; nodes: %03ld %03ld %03ld\n",
                   startBowl, best_score, num_nodes/1000000, num_nodes%1000000/1000, num_nodes%1000);
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
    
    if (status)
    {
         
    }
    return status;
}

int sum(int board[], int start, int finish)
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
    
    printf("(turn: %d)(depth: %d)\n", turnCounter, max_depth);
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
    return 0;
}


//****computer player code starts here****

int best_move (int board[], int player, int *best_score)
{
    int score, move;
    num_nodes = 0;
    *best_score = eval_max(board, player, max_depth, &move);
    return move;
}

int eval_max (int board[], int player, int level, int *best_move)
{
    num_nodes += 1;
    int result;
    if (level > 0 && !checkForWin(board))
    {
        int best_eval = INT_MIN;
        int eval_move;
        int p;
        for (p = P0POT + 1; p < P1POT; ++p)
        {
            if (board[p])
            {
                int eval_board[BOARDSIZE];
                int move_again;
                int this_eval;
                memcpy (eval_board, board, sizeof(int) * BOARDSIZE);
                move_again = !move (eval_board, player, p);
                if (move_again)
                {
                    this_eval = eval_max (eval_board, player, level, NULL);
                }
                else
                {
                    this_eval = eval_min (eval_board, !player, level-1, NULL);
                }
                if (this_eval > best_eval)
                {
                    best_eval = this_eval;
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

int eval_min (int board[], int player, int level, int *best_move)
{
    num_nodes += 1;
    int result;
    if (level > 0 && !checkForWin(board))
    {
        int best_eval = INT_MAX;
        int eval_move;
        int p;
        for (p = 0; p < P0POT; ++p)
        {
            if (board[p])
            {
                int eval_board[BOARDSIZE];
                int move_again;
                int this_eval;
                memcpy (eval_board, board, sizeof(int) * BOARDSIZE);
                move_again = !move (eval_board, player, p);
                if (move_again)
                {
                    this_eval = eval_min (eval_board, player, level, NULL);
                }
                else
                {
                    this_eval = eval_max (eval_board, !player, level-1, NULL);
                }
                if (this_eval < best_eval)
                {
                    best_eval = this_eval;
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
