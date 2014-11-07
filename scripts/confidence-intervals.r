#!/usr/local/bin/Rscript

## written: 2014-10-28
## update: 2014-10-29 - clean it up a little, fix output
## update: 2014-10-30 - output size of set @ each step
## update: 2014-10-31 - fix error where no contigs are within acceptable error
## update: 2014-11-03 - fix matrix output error where the cutoffs
##   arent updating past the first on

## see
## http://www.unc.edu/courses/2007spring/enst/562/001/docs/lectures/lecture28.htm#boot

kelly.green <- '#00A000'

boot.sample <- function(thing.to.sample, n.times) {
    ## will include in the first column the original thing.to.sample
    matrix(
        c(thing.to.sample,
          sample(thing.to.sample,
                 rep=T,
                 (n.times-1)*length(thing.to.sample))),
        ncol=n.times)
}

close.enough <- function(i, real.mean, acceptable.error) {
    abs(real.mean - i) < ((acceptable.error * real.mean) / 2)
}

perc.contigs.close.enough <- function(mean.coverages,
                                      real.mean,
                                      acceptable.error) {
    num <- sum( ## number that are close enough
               unlist( ## true false vals for each contig in a nice list
                      lapply( ## true false vals for each contig
                             mean.coverages,
                             close.enough,
                             real.mean=real.mean,
                             acceptable.error=acceptable.error)))
    if (length(mean.coverages) == 0) {
        ## TODO handle the error
        cat('ERROR: length(mean.coverages) == 0')
        q(save="no")
    } else {
        val <- num / length(mean.coverages)
    }
    return(val) ## percent that are close enough, will never be zero as it dies upstream
}
    
boot.perc.contigs.close.enough <- function(dat,
                                           real.mean,
                                           acceptable.error,
                                           n.times) {
    mean.cov <- dat$mean.cov
    boots <- boot.sample(mean.cov, n.times)

    apply(boots,
          2,
          perc.contigs.close.enough,
          real.mean=real.mean,
          acceptable.error=acceptable.error)
}

## boot.stats is the output from boot.perc.contigs.close.enough
bootstrap.info <- function(boot.stats, simple.output=T) {
    sample.stat <- boot.stats[1]
    bootstrap.stats <- boot.stats[-1]

    bias <- mean(bootstrap.stats) - sample.stat
    std.err <- sd(bootstrap.stats)
    basic.ci <- 2*sample.stat - quantile(bootstrap.stats, c(0.975, 0.025))

    plot.it <- function() {
        hist(bootstrap.stats,
             main='Percent of contigs w/acceptable error',
             xlab='Bootstrapped acceptable percentages')
        abline(v=sample.stat, col='blue', lwd=3)
        abline(v=basic.ci, col='red', lwd=2)
        legend('topleft',
               c("Mean", '95% CI'),
               lty=1,
               col=c('blue', 'red'),
               lwd=c(3,2),
               cex=0.6,
               inset=0.01)
    }

    if (simple.output == T) {
        return(c(basic.ci[1], sample.stat, basic.ci[2]))
    } else {
        return(list(sample.stat=sample.stat,
                    bootstrap.stats=bootstrap.stats,
                    bias=bias,
                    std.err=std.err,
                    ci.low=basic.ci[1],
                    ci.high=basic.ci[2],
                    plot=plot.it))
    }
}

find.length.cutoff <- function(dat,
                               real.mean=10,
                               acceptable.percent=0.95,
                               acceptable.error=0.05,
                               n.times=1999,
                               simple.output=T) {

    ## acceptable percent is the chance of getting a contig within the
    ## acceptable error

    perc.contigs.acceptable = 0
    max.len <- max(dat$len)
    cutoff <- 0

    ## check and make sure there are contigs within the error
    perc.contigs.acceptable <- perc.contigs.close.enough(
        dat$mean.cov,
        real.mean,
        acceptable.error)

    if (perc.contigs.acceptable < 0.000001 || perc.contigs.acceptable == 0) {
        return(c(nrow(dat), cutoff, c(0,0,0)))
    } else {
        this.subset <- subset(dat, len > cutoff)        
        ## this isn't incrementig properly
        while(perc.contigs.acceptable <= acceptable.percent && cutoff < max.len) {
            cutoff <- cutoff + 1
            this.subset <- subset(dat, len > cutoff) # TODO perhaps deal with if this is null

            this.mean.cov <- this.subset$mean.cov

            perc.contigs.acceptable <- perc.contigs.close.enough(
                this.mean.cov,
                real.mean,
                acceptable.error)
        }

        ## `cutoff` is the appropriate length cutoff to give you a
        ## `perc.contigs.acceptable` value which is higher than the
        ## `acceptable.percent`

        ## find the CI's
        boot.stats <- boot.perc.contigs.close.enough(this.subset,
                                                     real.mean,
                                                     acceptable.error,
                                                     n.times)

        if (simple.output == T) {
            ## c(cutoff, low-ci, sample-stat, high-ci)
            return(c(nrow(this.subset), cutoff, bootstrap.info(boot.stats)))
        } else {
            return(bootstrap.info(boot.stats, F)) # TODO doesn't currently work
        }
    }
}

## make this spit out a nice chart with the length cutoff on x and
## confidence on y, with CIs for the confidence
find.multiple.length.cutoffs <- function(dat,
                                         real.mean=10,
                                         acceptable.percent=0.9,
                                         acceptable.error=0.05,
                                         n.times=1999,
                                         plot.only=F,
                                         rl=250,
                                         kmer=101) {

    ## TODO this can sometimes be zero
    start <- perc.contigs.close.enough(dat$mean.cov,
                                       real.mean,
                                       acceptable.error)

    get.start <- function(start) {
        as.numeric(paste('0.', substring(toString(start*10), 1, 1),
                         sep=''))
    }

    the.list <- lapply(seq(get.start(start), 0.95, by=0.05),
                       find.length.cutoff,
                       dat=dat,
                       real.mean=real.mean,
                       acceptable.error=acceptable.error,
                       n.time=n.times)
    my.matrix <- t(matrix(unlist(the.list), nrow=5))
    ## print out the data
    for (i in 1:nrow(my.matrix)) { cat(my.matrix[i,], "\n") }

    ## after printing data, drop the first column (num. contigs per set)
    my.matrix <- my.matrix[,-1]
    
    plot.it <- function() {
        xs <- my.matrix[,1]
        my.matrix.xlim <- c(xs[1], xs[length(xs)])
        my.matrix.ylim <- c(my.matrix[1,2], my.matrix[nrow(my.matrix),4])

        plot(1, type='n', xlab='Length cutoff',
             ylab=paste('Proportion of cotigs w/less than 5% error from',
                 'real mean cov value', sep=' '),
             xlim=my.matrix.xlim, ylim=my.matrix.ylim,
             main=paste('What should my length cutoff be? (RL: ', rl, ', Cov: ', real.mean, 'x, Kmer: ', kmer, ')', sep=''))
        polygon(c(xs, rev(xs)),
                c(my.matrix[,4],
                  rev(my.matrix[,2])),
                col='gray97',
                border=NA)
        points(x=xs, y=my.matrix[,3], type='l', col=kelly.green, lwd=3)
        legend('topleft', c('Confidence', 'Basic 95% CI'),
               fill=c(kelly.green, 'gray97'),
               inset=0.025)
    }
    if (plot.only == T) {
        return(plot.it)
    } else {
        return(list(data.matrix=my.matrix, plot=plot.it))
    }
}

######################################################################
##### Script #########################################################
######################################################################

## see http://www.r-bloggers.com/parse-arguments-of-an-r-script/
## for command line 

## collect arguments
args <- commandArgs(T)

## Default setting when no arguments passed
if(length(args) < 1) {
  args <- c("--help")
}

help <- "
  Making the confidence interval graphs....
 
  Arguments:
    --infile=/path/to/infile - the input file (ie output from simple_info)
    --outpdf=/path/to/outpdf - the path to output pdf
    --realMean=an_integer    - the actual mean coverage value
    --readLen=an_integer     - length of fake reads
    --kmer=an_integer        - size of assembly kmer
    --help                   - print this text
 
  Example:
    ./confidence-intervals.r --infile=/my/file.txt \\
    --outpdf=/my/out.pdf --real-mean=10\n\n"

## Help section
if("--help" %in% args) {
  cat(help)
  q(save="no")
}

## Parse arguments (we expect the form --arg=value)
parseArgs <- function(x) strsplit(sub("^--", "", x), "=")
argsDF <- as.data.frame(do.call("rbind", parseArgs(args)))
argsL <- as.list(as.character(argsDF$V2))
names(argsL) <- argsDF$V1

## handle --infile
if (is.null(argsL$infile)) {
    cat("Don't forget the --infile argument!\n")
    cat(help)
    q(save="no")
} else if (!file.exists(argsL$infile)) {
    cat(paste("\nARG ERROR: It looks like",
              argsL$infile, "doesn't exist!\n", sep=' '))
    cat(help)
    q(save="no")
}
 
## handle --outpdf
if (is.null(argsL$outpdf)) {
    cat("\nARG ERROR: Don't forget the --outpdf argument!\n")
    cat(help)
    q(save="no")
}
 
## handle --realMean
if (is.null(argsL$realMean)) {
    cat("\nARG ERROR: Don't forget the --realMean argument!\n")
    cat(help)
    q(save="no")
} else if (grepl("[^0-9]+", argsL$realMean)) { ## make sure its an integer
    cat("\nARG ERROR: --realMean must be an integer!\n")
    cat(help)
    q(save="no")
} else {
    argsL$realMean <- as.numeric(argsL$realMean)
    if (argsL$realMean < 0) {
        cat("\nARG ERROR: Enter a positive value for --realMean\n")
        cat(help)
        q(save='no')
    }
}

## handle --readLen
if (is.null(argsL$readLen)) {
    cat("\nARG ERROR: Don't forget the --readLen argument!\n")
    cat(help)
    q(save="no")
} else if (grepl("[^0-9]+", argsL$readLen)) { ## make sure its an integer
    cat("\nARG ERROR: --readLen must be an integer!\n")
    cat(help)
    q(save="no")
} else {
    argsL$readLen <- as.numeric(argsL$readLen)
    if (argsL$readLen < 0) {
        cat("\nARG ERROR: Enter a positive value for --readLen\n")
        cat(help)
        q(save='no')
    }
}

## handle --kmer
if (is.null(argsL$kmer)) {
    cat("\nARG ERROR: Don't forget the --kmer argument!\n")
    cat(help)
    q(save="no")
} else if (grepl("[^0-9]+", argsL$kmer)) { ## make sure its an integer
    cat("\nARG ERROR: --kmer must be an integer!\n")
    cat(help)
    q(save="no")
} else {
    argsL$kmer <- as.numeric(argsL$kmer)
    if (argsL$kmer < 0) {
        cat("\nARG ERROR: Enter a positive value for --kmer\n")
        cat(help)
        q(save='no')
    }
}

## TODO handle the last two arguments
        
f <- argsL$infile
outpdf <- argsL$outpdf
real.mean <- argsL$realMean
acceptable.percent <- 0.95
acceptable.error <- 0.05
n.times <- 1999
read.length <- argsL$readLen
kmer <- argsL$kmer

dat <- read.table(f, header=T, sep="\t",
                  col.names=c('ref', 'len', 'num.mapped', 'mean.cov',
                      'prop.frags', 'prop.frag.cov'))
filtered.dat <- subset(dat, dat$len >= read.length)

## cat("cutoff confidence\n")

plot.me <- find.multiple.length.cutoffs(filtered.dat,
                                        real.mean,
                                        acceptable.percent,
                                        acceptable.error,
                                        n.times,
                                        plot.only=T,
                                        read.length,
                                        kmer)

pdf(outpdf, width=11*0.8, height=8.5*0.8)
plot.me()
invisible(dev.off())

## cat(paste("\nFile written:", outpdf, sep=' '))
