R=R -q --vanilla
STANPRINT=~/cmdstan-2.6.0/bin/print

# Make a PDF file of pretty plots and a table of players' ratings.
fooscore.pdf fooscores.dat: fooscore-out.csv fooscore.R
	${R} < fooscore.R
	mv Rplots.pdf fooscore.pdf

# Fit the model and write the parameters' posterior distributions.
# Exploit the sampler's speed by running it for a lot of samples,
# using thinning to keep the output file to a nice size.
# (Before making this target, one must compile the model by running
#	~/cmdstan-2.6.0$ make ~/projects/fooscore/fooscore
#  to produce the `fooscore` sampler program.)
fooscore-out.csv: fooscore data-from-dump.R
#	./fooscore sample num_samples=4000 data file=test-data.R \
#		output file=fooscore-out.csv
	./fooscore sample num_samples=8000 thin=2 \
		data file=data-from-dump.R output file=fooscore-out.csv
#	${STANPRINT} fooscore-out.csv

# Take a text file with a direct copy-and-paste from the results
# spreadsheet, and extract the relevant score data from it into
# a Stan-friendly R-like file.
data-from-dump.R: extract-from-dump.py dump.txt
	./extract-from-dump.py dump.txt data-from-dump.R

# Use a table of player ratings to simulate many games, record those
# simulated games' scores, and fit the model to them. (Don't go crazy
# with the number of samples.)
fauxscore-out.csv: fooscore simulate fooscores.dat
	./simulate fooscores.dat 4999 > simulated-data.txt
	./extract-from-dump.py simulated-data.txt simulated-data.R
	./fooscore sample \
		data file=simulated-data.R output file=fauxscore-out.csv

# Make a program to simulate games on the basis of a ratings table.
simulate: simulate.c
	gcc -Wall -Wextra -ansi -pedantic -Os simulate.c -lm -o simulate
