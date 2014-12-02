library('plot3D')
library('scatterplot3d')

get.label.coords <- function(num.colors) {
    scale <- function(v, num.colors) {
        unlist(lapply(v, function(i) { i / num.colors + 1 }))
    }
    
    new.scale.max <- num.colors * (num.colors-1)
    new.scale <- seq(0, new.scale.max, length.out=num.colors+1)

    start <- new.scale[2] / 2
    step <- new.scale[2]
    center.points <- seq(from=start,
        by=step,
        length.out=num.colors)

    return(scale(center.points, num.colors))
}

par(cex.axis=0.5, mfrow=c(1,2))
par(mfrow=c(1,2))

mydata <- read.csv('assembly_groups_no_bad.csv', header=T)
# K-Means Cluster Analysis
fit <- kmeans(mydata[1:3], 3, iter.max=100) # 5 cluster solution
# append cluster assignment
mydata <- data.frame(mydata, three.clusters=fit$cluster)
# K-Means Cluster Analysis
fit <- kmeans(mydata[1:3], 4, iter.max=100) # 5 cluster solution
# append cluster assignment
mydata <- data.frame(mydata, four.clusters=fit$cluster)
# K-Means Cluster Analysis
fit <- kmeans(mydata[1:3], 5, iter.max=100) # 5 cluster solution
# append cluster assignment
mydata <- data.frame(mydata, five.clusters=fit$cluster)
## col.key <- list(at=get.label.coords(3),
##                 labels=c('1', '2', '3'))
## colors <- c('#FF5858', '#53F1F1', '#FFA358')#, '#55F855', 'black')

MASS::write.matrix(mydata, file='clusters.txt')

par(mfrow=c(2,2))

col.key <- list(at=get.label.coords(3),
                labels=c('1', '2', '3'))
colors <- c('#7909b2', '#ffa800', '#19FF8b')
with(mydata,
     scatter3D(x=N50, y=Coverage, z=TotalContigs,
               colvar=three.clusters,
               colkey=col.key,
               col=colors,
               phi=20,
               theta=40,
               pch=20,
               xlab='N50',
               ylab='% Coverage',
               zlab='Total contigs',
               bty='b2',
               main='Three clusters',
               clab=c(rep('', 2), 'Cluster'),
               ticktype='detailed'))
col.key <- list(at=get.label.coords(4),
                labels=c('1', '2', '3', '4'))
colors <- c('#ff009b', '#b0ff00', '#125eff', '#ffa900')
with(mydata,
     scatter3D(x=N50, y=Coverage, z=TotalContigs,
               colvar=four.clusters,
               colkey=col.key,
               col=colors,
               phi=20,
               theta=40,
               pch=20,
               xlab='N50',
               ylab='% Coverage',
               zlab='Total contigs',
               bty='b2',
               main='Four clusters',
               clab=c(rep('', 2), 'Cluster'),
               ticktype='detailed'))
## with assembly parameters
backup <- mydata
mydata <- backup
tehe <- read.table('clusters_with_info.txt', header=T, sep=' ')
col.key <- list(at=get.label.coords(3),
                labels=c('1', '2', '3'))
colors <- c('#7909b2', '#ffa800', '#19FF8b')
with(tehe,
     scatter3D(x=Kmer, y=ReadLen, z=GenCov,
               colvar=three.clusters,
               colkey=col.key,
               col=colors,
               phi=20,
               theta=40,
               pch=20,
               xlab='Kmer',
               ylab='Read length',
               zlab='Generated coverage',
               bty='b2',
               main='Three clusters',
               clab=c(rep('', 2), 'Cluster'),
               ticktype='detailed'))
col.key <- list(at=get.label.coords(4),
                labels=c('1', '2', '3', '4'))
colors <- c('#ff009b', '#b0ff00', '#125eff', '#ffa900')
with(tehe,
     scatter3D(x=Kmer, y=ReadLen, z=GenCov,
               colvar=four.clusters,
               colkey=col.key,
               col=colors,
               phi=20,
               theta=40,
               pch=20,
               xlab='Kmer',
               ylab='Read length',
               zlab='Generated coverage',
               bty='b2',
               main='Four clusters',
               clab=c(rep('', 2), 'Cluster'),
               ticktype='detailed'))




with(mydata,
     scatterplot3d(x=N50, y=Coverage, z=TotalContigs,
                   pch=20,
                   color=five.clusters,
                   main='Stuff',
                   angle=80))

dat <- read.csv('dat.csv', header=T)
names(dat)

summary(full <- lm(Length ~ N50 + Total.Contigs + Coverage, data=dat))
summary(null <- lm(Length ~ 1, data=dat))
summary(s <- step(null, scope=list(lower=null, upper=full), direction='both'))
with(dat, plot(Length ~ N50))
points(s$fitted.values ~ dat$N50, type='l', col='blue')


summary(lm.f <- lm(N50 ~ Length, data=dat))

with(dat, plot(N50 ~ Length))
points(lm.f$fitted.values ~ dat$Length, type='l', col='blue')


summary(lm.f <- lm(N50 ~ Kmer, data=dat))
with(dat, plot(N50 ~ Kmer))
points(lm.f$fitted.values ~ dat$Kmer, type='l', col='blue')

summary(lm.f <- lm(N50 ~ Kmer + Gen.Cov + Length, data=dat))
with(dat, plot(N50 ~ Gen.Cov))
points(lm.f$fitted.values ~ dat$Gen.Cov, col='blue')

plot(lm.f)



summary(lm.f <- lm(Total.Contigs ~ Kmer + Gen.Cov + Length, data=dat))
summary(lm.f <- lm(Total.Contigs ~ Kmer, data=dat))
with(dat, plot(Total.Contigs ~ Kmer))
points(lm.f$fitted.values ~ dat$Kmer, col='blue')

summary(lm.f <- lm(Coverage ~ Kmer, data=dat))
with(dat, plot(Coverage ~ Kmer))


## as kmer goes up, N50 goes up, Number.Contigs goes down and % coverage goes down
