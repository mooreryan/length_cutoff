library('bear')
library('hash')

fname <- '/Users/ryanmoore/projects/length_cutoff/info/EColik12CompleteGenome.length_cutoff_summary.no-errors.no-zeros_with-confidence-levels.txt'

dat <- read.table(fname, header=T, sep=' ')

dat.95 <- subset(dat, confidence.level == 95)

dat.95.lm <- lm(len.cutoff ~ read.len * gen.cov * assem.kmer, data=dat.95)
summary(dat.95.lm)

null <- lm(len.cutoff ~ 1, data=dat.95)
full <- dat.95.lm
dat.95.step <- step(null, scope=list(lower=null, upper=full), direction='both')
summary(dat.95.step)

attach(dat.95)
par(mfrow=c(1,3))
plot(len.cutoff ~ assem.kmer, pch=20)
plot(len.cutoff ~ read.len, pch=20)
plot(len.cutoff ~ gen.cov, pch=20)
par(mfrow=c(1,1))
detach(dat.95)


hehe <- with(dat.95, data.frame(len.cutoff, read.len, gen.cov, assem.kmer))
he <- subset(hehe, read.len == 250 & gen.cov == 10)
h <- subset(he, assem.kmer != 81)
h <- subset(h, assem.kmer != 141)


fit <- lm(len.cutoff ~ assem.kmer, data=he)
summary(fit)
other.fit <- lm(len.cutoff~assem.kmer, data=h)


summarySE(data=dat.95, measurevar='len.cutoff', groupvars='gen.cov')

tee150 <- subset(hehe, assem.kmer==61 & read.len==150)
tee250 <- subset(hehe, assem.kmer==61 & read.len==250)

par(mfrow=c(1,2))
plot(len.cutoff ~ gen.cov, data=tee150, main="150 - 61")
plot(len.cutoff ~ gen.cov, data=tee250, main="250 - 61")

read.lens <- unique(dat.95$read.len)
gen.covs <- unique(dat.95$gen.cov)
assem.kmers <- unique(dat.95$assem.kmer)

# for checking assem.kmers
for (rl in read.lens) {
    for (gc in gen.covs) {
        print(rl)
        print(gc)
        this.dat <- subset(dat.95, read.len==rl & gen.covs==gc)
        print(summary(this.fit <- lm(len.cutoff ~ assem.kmer, data=this.dat)))
    }
}
    
