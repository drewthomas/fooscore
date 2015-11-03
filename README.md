fooscore
========

An exercise in Small Data. These programs estimate players' table-football performance ratings from the results of first-to-N-goals games. (Of course, these programs don't *have* to be used for foosball. There's no reason they wouldn't work for any other two-sided, no-draw games with discrete scoring.) Complicating the statistical problem is the heterogeneity of the games: some are singles games, others are doubles games; some games are first-to-4 victories, others are first-to-6, and still others are first-to-3.

The heart of the program is a statistical model implemented with [Stan](http://mc-stan.org/), and the data-processing pipeline as a whole goes like this.

## 1. Define the statistical model with a Stan file.

`fooscore.stan` defines the statistical model as a Stan model, which Stan compiles into the sampler program `fooscore`. Running `fooscore` fits the model with a Markov-chain Monte Carlo method, generating estimates of the model's parameters' values (i.e. the performance ratings one actually wants).

The model assumes players' ratings come from some statistical distribution with a mean of zero and standard deviation &sigma;. It puts a lognormal prior on &sigma;, assuming it'll be of order 1. The default distribution is a boring normal distribution, but I've played with a logistic distribution (which makes no obvious difference) and a *t* distribution with 3 degrees of freedom (which allows for a more fat-tailed rating distribution, making a bit of difference at the extremes).

To turn rating differences into expected scores, the model assumes a player or team's chance *p* of scoring the next goal/point is a logistic function of their rating advantage over the opposition. If both sides have equal ratings that chance is of course 50%. To connect this fact to the actual outcome of a game, the model assumes the winner's final score was the number of goals needed to win (e.g. a 7-3 game must have been a first-to-7 game), then treats the loser's score as a negatively binomially distributed variable, where the distribution's parameters are the winner's score and *p*. ([Wikipedia](https://en.wikipedia.org/wiki/Negative_binomial_distribution) expresses the NB distribution's parameters differently to Stan, incidentally, hence the ``(1 - nb_p) / nb_p`` circumlocution in the Stan model.)

The effective rating of a team is simply taken to be the sum of its players' ratings. That just seemed like the intuitive way to do it, but I have no rigorous justification for it!

## 2. Put the data into a usable format.

Someone else logs the game results in spreadsheets. I just pull out the results into the somewhat cleaner text file `dump.txt` for ease of processing, and the table of players' names into `names.dat`. (The names here are fake, by the way.)

## 3. Mince the data into the format Stan likes.

`extract-from-dump.py` reads `dump.txt` and turns it into `data-from-dump.R`, a score data file Stan can use.

## 4. Fit the model.

Finally the actual `fooscore` sampler runs, reading the results of games from `data-from-dump.R` and recording Bayesian posterior distributions for the players' ratings in `fooscore-out.csv`.

## 5. Present the results.

The R script `fooscore.R` reads `fooscore-out.csv` to make a dot plot of players' ratings, with standard error bars. See `fooscore.pdf`.
