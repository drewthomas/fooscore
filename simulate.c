#include <math.h>  /* for computing edges from rating advntages */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>  /* for `time`, for seeding the PRNG */

#define proceed_to_next_line(fp) \
	while ((!feof(fp)) && (!ferror(fp)) && (getc(fp) != '\n')) { \
	}

typedef struct Rating {
	unsigned int id;
	float rating;
	char name[70];
} Rating;

void simulate_singles_game(const unsigned int play_to, const Rating* a, const Rating* b)
{
	unsigned int goal[2] = { 0, 0 };
	float p_a;  /* probability of player/team `a` scoring next goal */

	p_a = 1.0 / (1.0 + exp(b->rating - a->rating));
	
	do {
		if ((rand() / (double) RAND_MAX) < p_a) {
			goal[0]++;
		} else {
			goal[1]++;
		}
	} while ((goal[0] < play_to) && (goal[1] < play_to));

	printf("%u\t\t%u\t\t%u\t%u\n", a->id, b->id, goal[0], goal[1]);
}

int main(int argc, char* argv[])
{
	Rating* cur_rat;
	int fields_read;
	FILE *fp;
	unsigned int i;
	unsigned int line_no = 2;
	unsigned int num_games;
	Rating* prev_rat_pointer;
	Rating* rat;
	unsigned int ratings_read = 0;
	unsigned int ratings_space = 1;

	if (argc != 3) {
		fprintf(stderr, "Usage: %s [RATINGS FILE] [GAME COUNT]\n", argv[0]);
		return EXIT_FAILURE;
	}

	if ((rat = malloc(ratings_space * sizeof(Rating))) == NULL) {
		fprintf(stderr,
		        "Can't allocate %lu bytes of initial memory for ratings.\n",
		        ratings_space * sizeof(Rating));
		return EXIT_FAILURE;
	}

	if ((fp = fopen(argv[1], "rb")) == NULL) {
		fprintf(stderr, "Can't open ratings file %s.\n", argv[1]);
		free(rat);
		return EXIT_FAILURE;
	}

	proceed_to_next_line(fp);

	while ((!feof(fp)) && (!ferror(fp))) {
		if ((line_no - 1) > ratings_space) {
			/* `rat` is full. Reallocate it to have more memory. */
			ratings_space = 2 * line_no;
			prev_rat_pointer = rat;
			if ((rat = realloc(rat,
			                   ratings_space * sizeof(Rating))) == NULL) {
				fprintf(stderr,
				        "Can't allocate %lu bytes of memory for ratings.\n",
				        ratings_space * sizeof(Rating));
				rat = prev_rat_pointer;
				break;
			}
		}
		cur_rat = &(rat[line_no - 2]);
		fields_read = fscanf(fp, "%u\t%f\t%*f\t\"%69[^\"]\"\n",
		                     &(cur_rat->id), &(cur_rat->rating),
		                     (char*) &(cur_rat->name));
		if (fields_read != 3) {
			/* This line isn't rating data or is badly formatted.
			   Inform the user and move on to the next line. */
			fprintf(stderr,
			        "Can't read full rating record from line %u of %s.\n",
			        line_no, argv[1]);
			proceed_to_next_line(fp);
		} else {
			ratings_read++;
		}
		line_no++;
	}

	fclose(fp);

	srand(time(NULL));

	/* Simulate `num_games` singles games with uniformly randomly chosen
	   players, and the needed number of goals to win between 3 & 20. */
	puts("P1T1\tP2T1\tP1T2\tP2T2\tScore1\tScore2");
	num_games = atoi(argv[2]);
	for (i = 0; i < num_games; i++) {
		simulate_singles_game(3 + (rand() % 18),
		                      &(rat[rand() % ratings_read]),
		                      &(rat[rand() % ratings_read]));
	}

	free(rat);

	return EXIT_SUCCESS;
}
