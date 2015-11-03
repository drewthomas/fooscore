data {
	int<lower=1> N;  // number of games
	int<lower=1> P;  // number of players
	int<lower=0> p1t1[N];  // ID of player 1 on team 1
	int<lower=0> p2t1[N];  // ID of player 2 on team 1 (if doubles game)
	int<lower=0> p1t2[N];  // ID of player 1 on team 2
	int<lower=0> p2t2[N];  // ID of player 2 on team 2 (if doubles game)
	int<lower=0> score1[N];  // player/team 1's score
	int<lower=0> score2[N];  // player/team 2's score
}
parameters {
	real rating[P];       // individual players' ratings
	real<lower=0> sigma;  // estimated grand standard deviation of ratings
}
model {
	/* A convenience variable for the estimated probability of a game's
	   losing team winning a point against the winning team. */
	real nb_p;

	/* Assume players' ratings are normally distributed with mean zero
	   and a standard deviation not known exactly but of order 1. */
	sigma ~ lognormal(0, 1);
	rating ~ normal(0, sigma);
//	rating ~ logistic(0, sigma * sqrt(3) / pi());
//	rating ~ student_t(3, 0, sigma / sqrt(3.0 / (3.0 - 2.0)));

	/* Iterate over each game, incorporating each game's observed
	   results into the likelihood. Assume a player/team's chance of
	   winning a point is a logistic (`inv_logit`) function of their
	   rating advantage, and that a team's rating is the sum of its
	   players' ratings. */
	for (i in 1:N) {
		if (p2t2[i]) {
			// doubles game
			if (score1[i] > score2[i]) {
				// Team 1 won.
				nb_p <- inv_logit(rating[p1t2[i]] + rating[p2t2[i]]
				                  - rating[p1t1[i]] - rating[p2t1[i]]);
				score2[i] ~ neg_binomial(score1[i], (1 - nb_p) / nb_p);
			} else if (score1[i] < score2[i]) {
				// Team 2 won.
				nb_p <- inv_logit(rating[p1t1[i]] + rating[p2t1[i]]
				                  - rating[p1t2[i]] - rating[p2t2[i]]);
				score1[i] ~ neg_binomial(score2[i], (1 - nb_p) / nb_p);
			} else {
				// Both teams finished the game with the same score?!
				print("Ignoring a game where both teams scored equally.");
			}
		} else {
			// singles game
			if (score1[i] > score2[i]) {
				// Player 1 won.
				nb_p <- inv_logit(rating[p1t2[i]] - rating[p1t1[i]]);
				score2[i] ~ neg_binomial(score1[i], (1 - nb_p) / nb_p);
			} else if (score1[i] < score2[i]) {
				// Team 2 won.
				nb_p <- inv_logit(rating[p1t1[i]] - rating[p1t2[i]]);
				score1[i] ~ neg_binomial(score2[i], (1 - nb_p) / nb_p);
			} else {
				// Both players finished the game with the same score?!
				print("Ignoring a game where both players scored equally.");
			}
		}
	}
}
