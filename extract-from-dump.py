#!/usr/bin/env python

from sys import argv, exit

if len(argv) < 2:
	print "Usage: " + argv[0] + " [DUMP FILE]"
	exit(1)

f = open(argv[1], "rb")
dump_lines = [ line.strip() for line in f.readlines() ] 
f.close()

dump = [ line.split("\t") for line in dump_lines ]
games = dump[1:]  # throw away header line
print len(games), "total games"

def make_singles_game_nice(game):
	for i in range(len(game)):
		if game[i] == "":
			game[i] = "0"
	return game

games = map(make_singles_game_nice, games)

P = max(map(lambda game: max(map(int, game[:4])), games))

def pull_out_column(name, idx):
	col_data = ",".join(map(lambda game: game[idx], games))
	return name + " <- c(" + col_data + ")\n"

col_names = ("p1t1", "p2t1", "p1t2", "p2t2", "score1", "score2")
f = open("data-from-dump.R", "wb")
f.write("N <- %u\nP <- %u\n" % (len(games), P))
for col_idx in range(len(col_names)):
	f.write(pull_out_column(col_names[col_idx], col_idx))
f.close()

print len(games), "games and", P, "players extracted into data-from-dump.R"
