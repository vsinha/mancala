//****computer player code starts here****
/*
int eval(int board, int player, int i, int do_max, int num_levels);

int main()
{
    int max = -1;
	int move = -1;
	int num_levels = 3;
	int do_max = 1;
	int other_player = player;

	for (i = 0; i<10; i++)
	{
		score = eval(board, player, i, do_max, num_levels);
		if (score > max)
		{
			max = score;
			move = i;
		}
	}
}

int eval(int board, int player, int move, int max_min, int level)
{
	int try_board[BOARDSIZE];
	if (level>0)
	{
		memcpy(try_board, board, sizeof(board));
		next_player = moveit(try_board, player, move);
		next_max_min = (next_player == player) ? max_min : !max_min;
		if (!game_over(try_board))
		{
			max = -1;
			move = -1;
			num_levels = 3;
			for (i = 0; i < 10; i++)
			{
				score = eval(try_board, next_player, i, next_max_min, level-1);
				if (score > max)
				{
					max = score;
				}
			}
		}
	}
	net_score = pot[player] - pot[!player];
	if(!max_min)
	{
		net_score = -net_score;
	}
	return net_score;
}
}
*/
