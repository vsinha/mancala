// Mancala - UPC implementation
// Author: Viraj Sinha <viraj@intrepid.com>
#include <upc.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <limits.h>
#include <time.h>
#include <assert.h>
#include <upc.h>

#define BOARDSIZE      14
#define P0POT          BOARDSIZE/2 - 1
#define P1POT          BOARDSIZE - 1
#define NUM_POTS       P0POT
#define START_AMOUNT   4
#define STARTMAXDEPTH  5
#define ARGNUMBER      8

#define NODE_LIMIT 1000000

struct move_score_struct
{
  int move;
  int score;
};
typedef struct move_score_struct move_score_pair_t;

double clock_time (void);
int getInput (int whosTurn, int checkSwitch, int board[]);
int disp (int board[]);
void initArray (int board[]);
int checkForWin (int board[]);
int sum (int board[], int start, int finish);
int move (int board[], int whosTurn, int startBowl);
int endGame (int board[], int winStatus);
int addToPot (int board[], int currentBowl, int whosTurn);
int best_move (int board[], int player, int *best_score);
int eval_max (int board[], int player, int level, int *best_move, int alpha, int beta);
int eval_min (int board[], int player, int level, int *best_move, int alpha, int beta);
int clearPebbles (int board[]);
int randomMove ();
int getRand (int min, int max);
void search_for_best_move (int player);

long int num_nodes = 0;
int turnCounter = 0;
int max_depth = STARTMAXDEPTH;
long long int total_num_nodes;
double total_wall_time;
double total_think_time;

int do_alpha_beta = 0;
int do_sort = 0;
int do_deepen = 0;
int do_weighted_scoring = 0;
int do_random = 0;
int do_debug = 0;
char print_flag[ARGNUMBER];
FILE *stats_file;
FILE *wins_file;

// UPC globals

shared int shared_do_alpha_beta = 1;
shared int shared_do_sort = 1;
shared int shared_do_weighted_scoring = 0;
shared int shared_do_random = 1;
shared int shared_do_debug = 0;
shared int shared_max_depth;

shared [] int shared_board[BOARDSIZE];
shared int shared_answers[THREADS];
shared int shared_num_nodes[THREADS];
shared double shared_think_time[THREADS];

int
main (int argc, char *argv[])
{
  int i;
  int board[BOARDSIZE];
  int startBowl;		// the bowl chosen by the player
  int whosTurn = 1;		// which player's turn it is initially
  int winStatus = 0;
  int checkSwitch = 1;

  srand (time (NULL));

  if (!MYTHREAD)
    {
      if (THREADS != 6)
	{
	  fprintf (stderr, "This program requires "
	           "6 threads to run. Please try again.\n");
	  upc_global_exit (2);
	}

      stats_file = fopen ("stats.txt", "a");
      if (!stats_file)
	{
	  perror ("fopen of stats file failed\n");
	  abort ();
	}
      setlinebuf (stats_file);
      wins_file = fopen ("wins.txt", "a");
      if (!wins_file)
	{
	  perror ("fopen of wins file failed\n");
	  abort ();
	}
      setlinebuf (wins_file);

      if (argc >= 2)
	{
	  int i;
	  for (i = 1; i < argc; i++)
	    {
	      switch (*argv[i])
		{
		case 'a':	// all
		  shared_do_alpha_beta = 1;
		  shared_do_sort = 1;
		  shared_do_weighted_scoring = 1;
		  shared_do_random = 1;
		  do_deepen = 1;
		  break;
		case 'd':	// deepening
		  do_deepen = 1;
		  break;
		case 'g':	// debugging output
		  shared_do_debug = 1;
		  break;
		case 'p':	// prune
		  shared_do_alpha_beta = 1;
		  break;
		case 'r':	// computer plays random player
		  shared_do_random = 1;
		  break;
		case 's':	// sort
		  shared_do_sort = 1;
		  break;
		case 'w':	// weighted scoring
		  shared_do_weighted_scoring = 1;
		  break;
		case 'n':	// no.
		  shared_do_alpha_beta = 0;
		  shared_do_sort = 0;
		  shared_do_weighted_scoring = 0;
		  shared_do_random = 0;
		  do_deepen = 0;
		  break;
		default:
		  abort ();
		}
	    }
	}

      printf ("alpha-beta=%s deepen=%s random-opponent=%s "
              "sort=%s weighted-score=%s\n",
	      shared_do_alpha_beta ? "yes" : "no",
	      do_deepen ? "yes" : "no",
	      shared_do_random ? "yes" : "no",
	      shared_do_sort ? "yes" : "no",
	      shared_do_weighted_scoring ? "yes" : "no");

      fprintf (stats_file, "alpha-beta: %s | deepen: %s | "
              "random-opponent: %s | sort: %s | weighted-score: %s\n",
	      shared_do_alpha_beta ? "yes" : "no",
	      do_deepen ? "yes" : "no",
	      shared_do_random ? "yes" : "no",
	      shared_do_sort ? "yes" : "no",
	      shared_do_weighted_scoring ? "yes" : "no");

      initArray (board);
    }

  upc_barrier 1;


  // sync args across threads
  do_alpha_beta = shared_do_alpha_beta;
  do_sort = shared_do_sort;
  do_weighted_scoring = shared_do_weighted_scoring;
  do_random = shared_do_random;
  do_debug = shared_do_debug;

  if (MYTHREAD > 0)
    /* never returns */
    search_for_best_move (1);

  while (!winStatus)		// main loop
    {
      disp (board);
      if (!checkSwitch)
	{
	  printf ("\n**Player %d gets another turn!**\n", whosTurn);
	}

      startBowl = getInput (whosTurn, checkSwitch, board);
      checkSwitch = move (board, whosTurn, startBowl);
      winStatus = checkForWin (board);
      if (checkSwitch)
	{
	  whosTurn = !whosTurn;
	}
    }

  printf ("\n======Final Score======\n");
  clearPebbles (board);
  winStatus = checkForWin (board);
  disp (board);
  endGame (board, winStatus);

  fclose (stats_file);
  fclose (wins_file);

  upc_global_exit (0);
}

double
clock_time (void)
{
  struct timespec ts;
  double t;
  clock_gettime (CLOCK_MONOTONIC_RAW, &ts);
  t = (double) ts.tv_sec + (double) ts.tv_nsec * 1.0e-9;
  return t;
}

void
initArray (int board[])
{
  int i;

  for (i = 0; i < BOARDSIZE; i++)	// fill the array with pebbles
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

int
getInput (int whosTurn, int checkSwitch, int board[])
{
  int startBowl;
  int error = 1;		// allow it to enter the while loop

  if (checkSwitch)
    {
      printf ("\n======Player %d move======\n", whosTurn);
    }
  if (whosTurn == 0)
    {
      // other player's turn
      while (error)
	{
	  error = 0;
	  if (whosTurn == 0)
	    {
	      printf ("Select a cup of stones from 0-5 to move: ");
	    }
	  else if (whosTurn == 1)
	    {
	      printf ("Select a cup of stones from 7-12 to move: ");
	    }

	  if (whosTurn == 0)
	    {
	      turnCounter++;
	      if (do_random)	// random's turn
		{
		  startBowl = randomMove (board);
		  assert (board[startBowl]);
		}
	      else		// human's turn
		{
		  scanf ("%d", &startBowl);
		}
	    }

	  // sanitize inputs
	  if (whosTurn == 0
	      && ((startBowl < 0 || startBowl >= P0POT)
		  || startBowl == P0POT))
	    {
	      error = 1;
	    }
	  if (whosTurn == 1
	      && ((startBowl <= P0POT || startBowl >= P1POT)
		  || startBowl == P1POT))
	    {
	      error = 1;
	    }
	  if (error)
	    {
	      printf ("Please enter a valid input...\n");
	    }
	  if (!board[startBowl])
	    {
	      error = 1;
	      printf ("This cup is empty...\n");
	    }
	}
    }
 else
    {
      // computer's turn
      int i, p, best_score, n_nodes, prev_n_nodes;
      double start_time, end_time, wall_time, think_time;
      assert (whosTurn == 1);
      turnCounter++;
      if (do_deepen)
        {
	  for (max_depth = 6, prev_n_nodes = -1, n_nodes = 0;
	       n_nodes > prev_n_nodes && n_nodes < NODE_LIMIT;
	       ++max_depth)
	    {
	      prev_n_nodes = n_nodes;
	      shared_max_depth = max_depth;
	      upc_memput (shared_board, board, sizeof (shared_board));
	      search_for_best_move (1);
	      for (i = 0, p =  P0POT + 1, n_nodes = 0;
		   i < THREADS; ++i, ++p)
		{
		  if (board[p])
		    n_nodes += shared_num_nodes[i];
		}
	      if (do_debug)
	        printf ("deepen: depth=%d nodes=%d\n",
	                max_depth, n_nodes);
	    }
	}
      else
        max_depth = STARTMAXDEPTH;
      // copy the initial board position and max depth to shared memory.
      shared_max_depth = max_depth;
      upc_memput (shared_board, board, sizeof (shared_board));
      start_time = clock_time ();
      // parallel search
      search_for_best_move (1);
      end_time = clock_time ();
      wall_time = end_time - start_time;
      for (i = 0, p =  P0POT + 1, best_score = INT_MIN,
	   num_nodes = 0, think_time = 0.0;
           i < THREADS; ++i, ++p)
	{
	  if (board[p])
	    {
	      if (shared_answers[i] > best_score)
	        {
		  best_score = shared_answers[i];
		  startBowl = p;
		}
	      num_nodes += shared_num_nodes[i];
	      think_time += shared_think_time[i];
	    }
	}
      fprintf (stats_file,
               "predict: %d | move: %d | depth: %d | nodes: %d | "
	       "elapsed: %0.3g | total: %0.3g\n",
               best_score, startBowl, max_depth, num_nodes,
	       wall_time, think_time);
      printf ("predict: %d depth: %d nodes: %d "
	      "elapsed: %0.3g total: %0.3g\n",
              best_score, max_depth, num_nodes, wall_time, think_time);
      total_num_nodes += num_nodes;
      total_wall_time += wall_time;
      total_think_time += think_time;
    }
  printf ("startBowl: %d\n", startBowl);
  return startBowl;
}

int
randomMove (int board[])
{
  int i, n, min, max, count, randMove;
  for (i = 0, count = 0; i < NUM_POTS; i++)
    {
      if (board[i])
	{
	  count++;
	}
    }
  assert (count > 0);
  n = count > 1 ? getRand (1, count) : 1;
  for (i = 0; i < NUM_POTS; ++i)
    {
      if (board[i])
        {
          if (!--n)
	    break;
	}
    }
  randMove = i;
  return randMove;
}

int
getRand (int min, int max)
{
  int range = max - min + 1;
  assert (range > 1);
  return ((rand () % range) + min);
}


// returns 1 to change players, 0 to repeat turn
int
move (int board[], int whosTurn, int startBowl)
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

      // calls addToPot
      if ((board[currentBowl] == 1 && value == 0
	   && (currentBowl != P0POT && currentBowl != P1POT)))
	{
	  addToPot (board, currentBowl, whosTurn);
	  // printf("Player %d captured bowl %d!\n", whosTurn, currentBowl);
	}

      // Give the player another turn
      // if he puts his last pebble in his pot.
      if ((whosTurn == 0 && currentBowl == P0POT && value == 0) ||
	  (whosTurn == 1 && currentBowl == P1POT && value == 0))
	{
	  checkSwitch = 0;
	}

      // printf("value = %d\ncurrentBowl = %d\n", value, currentBowl);
      currentBowl++;

      // loop the numbers around
      currentBowl = currentBowl % BOARDSIZE;
      if (currentBowl == BOARDSIZE)
	{
	  currentBowl = 0;
	}
    }

  return checkSwitch;
}

int
addToPot (int board[], int currentBowl, int whosTurn)
{
  int clearbowls = 0;
  if (board[BOARDSIZE - currentBowl - 2])
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

int
clearPebbles (int board[])
{
  int sum0 = sum (board, 0, P0POT - 1);
  int sum1 = sum (board, P0POT + 1, P1POT - 1);
  board[P0POT] += sum0;
  board[P1POT] += sum1;


  // clear remaining holes
  int i;
  for (i = 0; i < P1POT; ++i)
    {
      if (i != P0POT && i != P1POT)
	{
	  board[i] = 0;
	}
    }

  // printf("\nPlayer 0 gets %d remaining pebbles\n", sum0);
  // printf("Player 1 gets %d remaining pebbles\n", sum1);

  return 0;
}

int
checkForWin (int board[])
{
  // returns 1 for player0 win
  //        2 for player1 win
  //        3 for tie
  //        0 for no win

  int checkScores = 0;
  int status = 0;
  int i;

  if (sum (board, 0, P0POT - 1) == 0)
    {
      checkScores = 1;
    }
  if (sum (board, P0POT + 1, P1POT - 1) == 0)
    {
      checkScores = 1;
    }

  if (checkScores)
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

int
endGame (int board[], int winStatus)
{
  double nodes_per_sec;
  int p0 = board[P0POT];
  int p1 = board[P1POT];

  printf ("Player 0: %d\n", p0);
  printf ("Player 1: %d\n", p1);

  switch (winStatus)
    {
    case 1:
      printf ("Player 0 wins!\n");
      break;
    case 2:
      printf ("Player 1 wins!\n");
      break;
    case 3:
      printf ("Tie game\n");
      break;
    }

  nodes_per_sec = total_num_nodes / total_wall_time;

  fprintf (stats_file, "totals | nodes: %lld | elapsed: %0.3g | "
          "think: %0.3g | nodes/sec: %0.3g\n",
	  total_num_nodes, total_wall_time, total_think_time,
	  nodes_per_sec);

  printf ("totals: nodes=%lld elapsed=%0.3g think=%0.3g "
          "nodes/sec=%0.3g\n",
	  total_num_nodes, total_wall_time, total_think_time,
	  nodes_per_sec);

  fprintf (wins_file, "Player 0: %2d | Player 1: %2d\n", p0, p1);

  return 0;
}

int
sum (int board[], int start, int finish)	// inclusive sum
{
  int i;
  int total = 0;

  for (i = start; i <= finish; i++)
    {
      total += board[i];
    }
  return total;
}

int
disp (int board[])
{
  int i;

  printf ("   ");
  for (i = P1POT - 1; i >= P0POT + 1; i--)
    {
      printf ("%4d", i);
    }
  printf ("   \n");

  printf ("|  |");
  for (i = P1POT - 1; i >= P0POT + 1; i--)
    {
      printf ("[%2d]", board[i]);
    }
  printf ("|  |\n");
  printf ("|%2d|", board[P1POT]);
  for (i = P1POT - 1; i >= P0POT + 1; i--)
    {
      printf ("    ");
    }
  printf ("|%2d|\n", board[P0POT]);
  printf ("|  |");
  for (i = 0; i < P0POT; i++)
    {
      printf ("[%2d]", board[i]);
    }
  printf ("|  |\n");
  printf ("   ");
  for (i = 0; i < P0POT; i++)
    {
      printf ("%4d", i);
    }
  printf ("\n");

  return 0;
}

// *************************************************************************
// ****computer player code starts here*************************************
// *************************************************************************

void
search_for_best_move (int player)
{
  int p;
  assert (player == 1);
  p = MYTHREAD + P0POT + 1;
  for (;;)
    {
      int work_board[BOARDSIZE];
      upc_barrier 2;
      upc_memget (work_board, shared_board, sizeof (work_board));
      max_depth = shared_max_depth;
      if (work_board[p])
	{
          int best_score, change_sides, next_player;
	  double start_time, end_time, think_time;
	  start_time = clock_time ();
	  change_sides = move (work_board, player, p);
	  next_player = change_sides ^ player;
	  (void) best_move (work_board, next_player, &best_score);
	  end_time = clock_time ();
	  think_time = end_time - start_time;
	  shared_answers[MYTHREAD] = best_score;
	  shared_num_nodes[MYTHREAD] = num_nodes;
	  if (do_debug)
	    printf ("[%d] depth=%d | score=%d | nodes=%d\n", MYTHREAD, max_depth, best_score, num_nodes);
	  shared_think_time[MYTHREAD] = think_time;
	}
      upc_barrier 3;

      /* Thread 0 returns, to process the answers.  */
      if (!MYTHREAD)
        return;
    }
}

int
best_move (int board[], int player, int *best_score)
{
  int score, move;
  int alpha = INT_MIN;
  int beta = INT_MAX;
  num_nodes = 0;
  *best_score = eval_max (board, player, max_depth, &move, alpha, beta);
  return move;
}

int
eval_max (int board[], int player, int level, int *best_move, int alpha,
	  int beta)
{
  num_nodes += 1;
  if (level > 0 && !checkForWin (board))
    {
      move_score_pair_t choice[NUM_POTS];
      int c, eval_move, nchoice, p;

      // go through each option
      for (p = P0POT + 1, nchoice = 0; p < P1POT; p++)
	{
	  if (board[p])		// if a valid move
	    {
	      int tscore = 0;
	      int tmove = p;
	      int k = nchoice;
	      if (do_sort)	// fill choice[] with insertion sort
		{
		  int sort_board[BOARDSIZE];
		  int move_again;
		  memcpy (sort_board, board, sizeof (int) * BOARDSIZE);
		  move_again = move (sort_board, player, tmove);
		  tscore = sort_board[P1POT];
		  if (do_weighted_scoring)
		    {
		      tscore = tscore * 100 + sum (sort_board, P0POT + 1, P1POT - 1);
		    }
		  while (k > 0 && choice[k - 1].score < tscore)
		    {
		      choice[k].score = choice[k - 1].score;
		      choice[k].move = choice[k - 1].move;
		      k -= 1;
		    }
		}
	      choice[k].move = tmove;
	      choice[k].score = tscore;

	      nchoice += 1;
	    }
	}

      for (c = 0; c < nchoice; ++c)
	{
	  int p = choice[c].move;
	  if (board[p])
	    {
	      int eval_board[BOARDSIZE];
	      int move_again;
	      int this_eval;
	      memcpy (eval_board, board, sizeof (int) * BOARDSIZE);
	      move_again = !move (eval_board, player, p);
	      if (move_again)
		{
		  this_eval = eval_max (eval_board, player, level, NULL, alpha, beta);
		}
	      else
		{
		  this_eval = eval_min (eval_board, !player, level - 1, NULL, alpha, beta);
		}
	      if (this_eval > alpha)
		{
		  alpha = this_eval;
		  eval_move = p;
		  if (do_alpha_beta && alpha >= beta)
		    break; 
		}
	    }
	}
      if (best_move != NULL)
	{
	  *best_move = eval_move;
	}
      return alpha;
    }

  clearPebbles (board);
  return board[P1POT];		// score
}

int
eval_min (int board[], int player, int level, int *best_move, int alpha, int beta)
{
  num_nodes += 1;
  if (level > 0 && !checkForWin (board))
    {
      move_score_pair_t choice[NUM_POTS];
      int c, eval_move, nchoice, p;
      // go through each option
      for (p = 0, nchoice = 0; p < NUM_POTS; p++)
	{
	  if (board[p])		// if a valid move
	    {
	      int tscore = 0;
	      int tmove = p;
	      int k = nchoice;
	      if (do_sort)
		{
		  int sort_board[BOARDSIZE];
		  int move_again;
		  memcpy (sort_board, board, sizeof (int) * BOARDSIZE);
		  move_again = move (sort_board, player, tmove);
		  tscore = sort_board[P1POT];
		  if (do_weighted_scoring)
		    {
		      tscore = (move_again * 1000) + (tscore * 100) + sum (sort_board, 0, P0POT - 1);
		    }
		  while (k > 0 && choice[k - 1].score < tscore)
		    {
		      choice[k].score = choice[k - 1].score;
		      choice[k].move = choice[k - 1].move;
		      k -= 1;
		    }
		}
	      choice[k].move = tmove;
	      choice[k].score = tscore;

	      nchoice += 1;
	    }
	}

      for (c = 0; c < nchoice; ++c)
	{
	  p = choice[c].move;
	  if (board[p])
	    {
	      int eval_board[BOARDSIZE];
	      int move_again;
	      int this_eval;
	      memcpy (eval_board, board, sizeof (eval_board));
	      move_again = !move (eval_board, player, p);
	      if (move_again)
		{
		  this_eval = eval_min (eval_board, player, level, NULL, alpha, beta);
		}
	      else
		{
		  this_eval = eval_max (eval_board, !player, level - 1, NULL, alpha, beta);
		}
	      if (this_eval < beta)
		{
		  beta = this_eval;
		  eval_move = p;
		  if (do_alpha_beta && alpha >= beta)
		    break;
		}
	    }
	}
      if (best_move != NULL)
	{
	  *best_move = eval_move;
	}
      return beta;
    }

  clearPebbles (board);
  return board[P1POT];
}
// vim: ts=8:sw=4:filetype=upc:textwidth=80
