## pick one assembly from each of the four assembly clusters randomly
## and use those for the calculations

dat <- read.table('clusters_with_info.txt', header=T, sep=' ')

sample(subset(dat, four.clusters==1)$Name, 1)
## 250-25-201

sample(subset(dat, four.clusters==2 & GenCov == 25)$Name, 1)
## 250-25-141

sample(subset(dat, four.clusters==3 & GenCov == 25 & ReadLen == 250)$Name, 1)
## 250-25-81

sample(subset(dat, four.clusters==4 & GenCov == 25 & ReadLen == 250)$Name, 1)
## 250-25-41

## these also happen to be the "center most" choices to evenly
## distribute kmer size across the four clusters
