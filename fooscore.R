# Read in the model fitting results from the sampler.
foo <- read.table("fooscore-out.csv", TRUE, ",", colClasses="numeric")
num_cols <- dim(foo)[2]

# Pick out the subset of the sampler's output with actual ratings.
# (Exclude the first 6 columns of `foo`, which give other information
#  about the sampling process, and `foo`'s last column, which gives
#  the model's estimate of the rating distribution's dispersion.)
foos <- foo[substr(colnames(foo), 1, 6) == "rating"]

# Read in the table mapping IDs to names.
nams <- read.table("names.dat", FALSE, "\t")
colnames(nams) <- c("PL", "SUR", "FORE")
nams$FULL <- paste(nams$FORE, nams$SUR)

P <- dim(foos)[2]  # number of players
ratings <- data.frame(PL=1:P, MEAN=apply(foos, 2, mean),
                      SD=apply(foos, 2, sd))

par(las=1, mar=c(4.8, 4, 0.2, 0.2))

## Overview of the model fitting results: means and standard deviations
## of sampled ratings.
#plot(ratings$PL, ratings$MEAN,
#     xlab="player ID", ylab="mean sampled rating")
#grid()
#plot(ratings$PL, ratings$SD,
#     xlab="player ID", ylab="standard deviation of sampled rating")
#grid()

# Merge the table of ratings with the table of names.
ratings <- merge(ratings, nams[, c(1,4)])

# Pick out the subset of people with ratings with narrowed-down standard
# deviations/errors. Then sort that subset of people by rating.
ratis <- ratings[ratings$SD < (0.8 * mean(foo$sigma)),]
ratis <- ratis[order(ratis$MEAN),]

# Plot people's ratings, then throw in error bars (allowing for the fact
# that `dotchart` flips the y-direction!).
dotchart(ratis$MEAN, ratis$FULL, cex=0.77, xlim=c(-0.9, 0.6),
         xlab="fooscore (with standard error bars)", pch=21, bg="#0000006f")
abline(h=seq(1, length(ratis[,1]), 4), col="#0000009f", lty="dotted")
abline(v=seq(-0.9, 1, 0.1), col="#0000004f", lty="dotted")
abline(v=0, lty="dotted")
for (i in 1:length(ratis[,1])) {
	xs <- ratis$MEAN[i] - (c(-1, 1) * ratis$SD[i])
	arrows(xs[1], i, xs[2], i, length=0.03, angle=90, code=3)
}
text(-0.5, length(ratis[,1]) - 2,
     substitute(atop("estimated " * sigma * " of rating",
                     "distribution = " * sig),
                list(sig=signif(mean(foo$sigma), 3))),
     cex=0.9)

# Define the link function the model used to convert someone's rating
# advantage into their probability of winning a point.
link <- function(advantage)
{
	return(1 / (1 + exp(-advantage)))
}

# Make a plot of the link function.
curve(100 * link(x), -1.45, 1.45, xlab="fooscore advantage",
      ylab="expected chance of winning point (%)", lwd=2)
abline(v=seq(-1.5, 1.5, 0.1), col="#0000004f", lty="dotted")
abline(v=seq(-1.5, 1.5, 0.5), col="#0000007f", lty="dotted")
abline(h=seq(0, 100, 5), col="#0000004f", lty="dotted")

# Convert people's ratings into probabilities of winning a point, then
# plot those probabilities.
dotchart(100 * link(ratis$MEAN), ratis$FULL, cex=0.77, xlim=c(31, 69),
         xlab="estimated chance of winning a point vs. average player (%)",
         pch=21, bg="#0000006f")
abline(h=seq(1, length(ratis[,1]), 4), col="#0000009f", lty="dotted")
abline(v=seq(30, 70, 5), col="#0000004f", lty="dotted")
abline(v=50, lty="dotted")

# Are people's ratings reasonably consistent with an underlying
# normal distribution?
cat("Normality test p-value: ", shapiro.test(ratis$MEAN)$p.value, "\n")

#plot(density(ratis$MEAN), main="",
#     xlab="rating", ylab="probability density of rating")
#curve(dnorm(x), lty="dashed", add=TRUE)
#grid()

# Record the fooscores.
ratis$MEAN <- round(ratis$MEAN, 3)
ratis$SD <- round(ratis$SD, 3)
write.table(ratis, "fooscores.dat", sep="\t", row.names=FALSE)
