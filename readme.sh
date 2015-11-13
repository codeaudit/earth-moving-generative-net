. /Users/daniel/experiments/rbm/daniel-experiments/lasagne-demo/venv/bin/activate

# Attempt at faces:
# http://www.hcii-lab.net/data/SCUT-FBP/EN/introduce.html
cd ~/experiments/rbm/daniel-experiments/face/SCUT-FBP
wget http://www.hcii-lab.net/data/SCUT-FBP/download/Data_Collection.zip
wget http://www.hcii-lab.net/data/SCUT-FBP/download/Rating_Collection.zip
unzip -q Data_Collection.zip
cd Data_Collection
mkdir ../thumb
mogrify -path ../thumb -thumbnail 28x28 -extent 28x28 -gravity Center -colorspace gray *.jpg

cd ~/experiments/rbm/daniel-experiments/kohonen
montage ../face/SCUT-FBP/thumb/SCUT-FBP-*[0-7].jpg -geometry 28x28+0+0 ../face/SCUT-FBP/tile.jpg

mkdir ~/experiments/rbm/daniel-experiments/face/SCUT-FBP/thumb.big
mogrify -path ~/experiments/rbm/daniel-experiments/face/SCUT-FBP/thumb.big -thumbnail 32x42 -extent 32x42 -gravity Center -colorspace gray -format png ~/experiments/rbm/daniel-experiments/face/SCUT-FBP/Data_Collection/*.jpg
# -> this became exp.bigfaces.n100 after learning.

cd exp.bigfaces.n100
ssh kruso.mokk.bme.hu mkdir ./public_html/kohonen
for dir in xy yz xz s ; do convert $dir[1-9]0000.png $dir[0-9][0-9]0000.png -delay 10 -loop 0 $dir.gif ; done
scp *.gif kruso.mokk.bme.hu:./public_html/kohonen/


# Second attempt at faces:
# https://www.kaggle.com/c/facial-keypoints-detection/data
# http://danielnouri.org/notes/2014/12/17/using-convolutional-neural-nets-to-detect-facial-keypoints-tutorial/#the-data
cd ~/experiments/rbm/daniel-experiments/face/kaggle-facial-keypoints-detection
( cat training.csv | awk 'BEGIN{FS=","} { print $NF }' | tail -n +2 ; cat test.csv | cut -f2 -d',' | tail -n +2 ) > pixels.txt
# -> 7049 train + 1784 test = 8832 96x96x1 images.


# Back at digits again, playing with larger n:
# exp.20dCubeMixture.2layerTanh.n100.digit7 is a stupid mistake. Both
python generative-mlp.py exp.20dCubeMixture.2layerTanh.n100.digit7 100 > cout.exp.20dCubeMixture.2layerTanh.n100.digit7
# and
python generative-mlp.py exp.20dCubeMixture.2layerTanh.n100.digit7 300 > cout.exp.20dCubeMixture.2layerTanh.n300.digit7
# were pointing to this dir. The n300 started later, so it's overwritten the other, except for
# the latest images, *101700.png - *102800.png. n300 is definitely worse,
# more prone to forked lines. Why?

# Now running:
python generative-mlp.py exp.20dCubeMixture.2layerTanh.n100.digit3 100 > cout.exp.20dCubeMixture.2layerTanh.n100.digit3
python generative-mlp.py exp.20dGaussian.2layerTanh.n300.digit3 300 > cout.exp.20dGaussian.2layerTanh.n300.digit3
# UPDATE: Dumb me, that's n300 right there.
# Have to do Gaussian again with n100. See below.

# The filenames tell all, hopefully. For the record:
# 100 hidden units, learning_rate=0.02, momentum=0.5
# scale of normal distribution 1/4, findGenForData True, overSamplingFactor 1.

# UPDATE: Disregard this paragraph, it compares gauss.n300 to mixture.n100.
# -> After some 2000 epochs, the main difference is that mixture does the forks,
# gauss doesn't, but gauss is super non-diverse.
# After some 10000-30000 epochs (pretty subjective when) mixture stops doing the forks.
# The weirdest is that around here, gauss starts the fork thing, while still not
# being as diverse as mixture. All in all, it's objectively worse.

# UPDATE: Apples to apples aka n100 to n100 comparison
# between mixture and gauss.
# and also between gauss.n300 and gauss.n100.
python generative-mlp.py exp.20dGaussian.2layerTanh.n100.digit3 100 > cout.exp.20dGaussian.2layerTanh.n100.digit3
# -> EVALUATE!

# Okay, let's go all in, how about getting rid of the continuous component?
python generative-mlp.py exp.20dBoolean.2layerTanh.n100.digit3 100 > cout.exp.20dBoolean.2layerTanh.n100.digit3
python generative-mlp.py exp.50dBoolean.2layerTanh.n100.digit3 100 > cout.exp.50dBoolean.2layerTanh.n100.digit3
# -> EVALUATE!

# Does this fully-boolean-craziness work with more diverse data as well?
python generative-mlp.py exp.50dBoolean.2layerTanh.n100.digitAll 100 > cout.exp.50dBoolean.2layerTanh.n100.digitAll
# -> EVALUATE!

python generative-mlp.py exp.20dCubeMixture.2layerTanh.n100.digit2 100 > cout.exp.20dCubeMixture.2layerTanh.n100.digit2
python generative-mlp.py exp.50dCubeMixture.2layerTanh.n100.digit2 100 > cout.exp.50dCubeMixture.2layerTanh.n100.digit2
# -> Waiting for results. EVALUATE!

# Lots of work done on quantifying generation performance.
# We sample train and validation (unseen), greedily approximate them with generated samples,
# and quantify/visualize difference between gold and nearest generated (surrogate).
# Specifically, we log total L2 diff on train and valid,
# we visualize difference, and histogram L2 distances between gold and surrogate.
python generative-mlp.py exp.20dCubeMixture.2layerTanh.n100.digit2.moreVis 100 > cout.exp.20dCubeMixture.2layerTanh.n100.digit2.moreVis

cd exp.20dCubeMixture.2layerTanh.n100.digit2.moreVis
dir=diff_validation ; convert input.png $dir[1-9]000.png $dir[0-9][0-9]000.png $dir[0-9][0-9][0-9]000.png -delay 10 -loop 0 $dir.gif
# (inputs.png is only there as an almost subliminal signal to mark the beginning of the sequence.)

# -> ANALYZE A BIT MORE, but at first glance, it seem like it does not
# really converge after an initial phase. It's very adamant in NOT
# learning outliers. If it does not like something, it consistently
# behaves like it were not there. Why?

# For all digits, sampleTotal1e5 (as above):
python generative-mlp.py exp.20dCubeMixture.2layerTanh.n100.digitAll.moreVis 100 > cout.exp.20dCubeMixture.2layerTanh.n100.digitAll.moreVis
# Same but sampleTotal1e6, let's give the model a bit more chance to reproduce weird things:
python generative-mlp.py exp.20dCubeMixture.2layerTanh.n100.digitAll.moreVis.sampleTotal1e6 100 > cout.exp.20dCubeMixture.2layerTanh.n100.digitAll.moreVis.sampleTotal1e6
# -> Setting plotEach=1000 was dumb here, but we'll live with it.

# Visually inspecting the above two, it seems like sampleTotal1e6 over sampleTotal1e5
# causes just a tiny improvement in matching. (1. When the general shape is
# recognised, the details are similar. 2. It's rare that 1e6 recognizes the
# general shape while 1e5 does not.)

# Quantitatively:
paste <( grep t < cout.exp.20dCubeMixture.2layerTanh.n100.digitAll.moreVis) <( grep t < cout.exp.20dCubeMixture.2layerTanh.n100.digitAll.moreVis.sampleTotal1e6) | grep -v time | sed "s/_distance//g"
epoch 0 train 3539.577401 validation 3477.146151        epoch 0 train 3522.447895 validation 3458.440632
epoch 1000 train 2213.074515 validation 2232.757161     epoch 1000 train 2185.971621 validation 2206.666417
epoch 2000 train 2142.505005 validation 2149.576490     epoch 2000 train 2107.168020 validation 2124.794779
epoch 3000 train 2135.671001 validation 2104.446155     epoch 3000 train 2045.129582 validation 2079.306816
epoch 4000 train 2067.423567 validation 2073.011328     epoch 4000 train 2034.931709 validation 2050.239458
epoch 5000 train 2073.096339 validation 2053.568913     epoch 5000 train 2020.982528 validation 2032.500311
epoch 6000 train 2030.102489 validation 2039.459535     epoch 6000 train 2024.169692 validation 2019.274401
epoch 7000 train 2009.205883 validation 2029.150878     epoch 7000 train 1999.691904 validation 2010.084477
epoch 8000 train 2030.954336 validation 2016.807750     epoch 8000 train 2008.445006 validation 2000.994180
epoch 9000 train 1996.428312 validation 2007.845411     epoch 9000 train 1975.903737 validation 1992.986778
epoch 10000 train 2004.636604 validation 2001.809792    epoch 10000 train 1971.208121 validation 1988.213054
epoch 11000 train 1970.277075 validation 1996.890203    epoch 11000 train 1941.435286 validation 1983.694747
epoch 12000 train 1991.091591 validation 1990.768504    epoch 12000 train 1959.057641 validation 1980.160241
epoch 13000 train 1951.329268 validation 1986.618364    epoch 13000 train 1965.147074 validation 1974.976362
epoch 14000 train 1971.516946 validation 1982.143524    epoch 14000 train 1941.614413 validation 1972.079845
epoch 15000 train 2034.801743 validation 1982.433723    epoch 15000 train 1988.605444 validation 1968.329759
epoch 16000 train 1962.617783 validation 1976.536872    epoch 16000 train 1944.039658 validation 1965.219307
epoch 17000 train 1958.752054 validation 1974.458151    epoch 17000 train 1942.624157 validation 1962.432814
epoch 18000 train 1969.002308 validation 1972.265950    epoch 18000 train 1919.335813 validation 1960.542414
epoch 19000 train 1973.435493 validation 1971.694208    epoch 19000 train 1948.049374 validation 1957.739240
epoch 20000 train 1949.355630 validation 1968.837136    epoch 20000 train 1965.053454 validation 1955.413557
epoch 21000 train 1951.518872 validation 1967.355088    epoch 21000 train 1949.744274 validation 1952.960039
# The validation set is fixed, the train is a random 400 sample of whole train,
# that's why train is much more jumpy. But both are still converging,
# after 21000 epochs 27 hours. Slooow convergence, zero overfitting.

# Let's take a look at digit2, it had more time for less data.
cat cout.exp.20dCubeMixture.2layerTanh.n100.digit2.moreVis | grep train | grep "[24680]0000 " | less
epoch 20000 train_distance 2101.250673 validation_distance 2120.222100
epoch 40000 train_distance 2029.797620 validation_distance 2046.173394
epoch 60000 train_distance 1974.057262 validation_distance 2019.035806
epoch 80000 train_distance 1988.527564 validation_distance 1998.971389
epoch 100000 train_distance 1922.723794 validation_distance 1985.801420
epoch 120000 train_distance 1947.624636 validation_distance 1976.859255
epoch 140000 train_distance 1968.396235 validation_distance 1971.583964
epoch 160000 train_distance 1936.777050 validation_distance 1968.063181
epoch 180000 train_distance 1942.150860 validation_distance 1963.848308
epoch 200000 train_distance 1927.290592 validation_distance 1962.477934
epoch 220000 train_distance 1937.469074 validation_distance 1961.097084
epoch 240000 train_distance 1913.067156 validation_distance 1959.697684
epoch 260000 train_distance 1932.563189 validation_distance 1957.309960
# -> Still converging, but the rate is worthless now, after some 29 hours.

####

# TODO With our new evaluation weapons, let's re-attack the issue of
# how to assign surrogates and samples to each other.
# The most important is to take a second look at m.
# (Now that we moved theano graph compilation out of the inner loop.)
# Remember, m is the number of generated samples to choose from
# when finding pairs to n gold points.
# The learning rate should also be checked.
# Things like findGenForData, overSamplingFactor, and maybe
# an epoch-dependent n (minibatch sampling size) or learning rate (a la Kohonen).

####

# Okay, focusing on m. At the early phase of training, it's probably
# not smart to have a large m, as that means that many generated point
# stay at their bad place. Further in the training, it is smart,
# as that helps to learn small details.
# That's theorizing, but let's start with something super simple: m=1000 n=100.

# From now on, moreVis is taken as given, so the parent exp of
# exp.20dCubeMixture.2layerTanh.n100.m10000.digitAll
# is exp.20dCubeMixture.2layerTanh.n100.digitAll.moreVis (the one with sampleTotal1e5)
# diff: plotEach=100 (was 1000), m=1000 (was m=n=100).
python generative-mlp.py exp.20dCubeMixture.2layerTanh.n100.m1000.digitAll 100 > cout.exp.20dCubeMixture.2layerTanh.n100.m1000.digitAll
# -> For some reason, this is so slow that it doesn't even make sense to
# compare it with its parent exp.20dCubeMixture.2layerTanh.n100.digitAll.moreVis.
# 680 epochs in 6 hours, versus the old 26000 epochs in 31 hours, 10000 epochs per 12 hours.
# And these new 680-epoch are comparable in quality to the old 2000-epoch results, achieved in
# just 2.5 hours.
# Maybe the ridiculous slowness is just a bug, but let's postpone figuring this out
# after making autoencoder work.

####

# Spearmint-ize
# (Spearmint because I couldn't figure out how to use kwargs with hyperopt)

# Had to rename generative-mlp.py to generativeMLP.py
# so that it can be imported as a module.

# We are in the lasagne-demo venv.
brew install mongodb
pip install pymongo
git clone git@github.com:HIPS/Spearmint.git
pip install -e Spearmint
mkdir mongodb
cd mongodb
mongod --fork --logpath ./log --dbpath .
cd ..
mkdir spearmintOutput

# Reads config.json which references spearmintTask.py
# and writes to a directory named "output".
# Also spearmintTask.py is set up so that it creates directories for each
# job, dirname ./spearmintOutput/LR0.010-n10 or such.
python Spearmint/spearmint/main.py .

# Cleanup command resets experiment:
Spearmint/spearmint/cleanup.sh .
# TODO This . was not intended for this, there should be a proper subdir for it.

# It's running now. spearmintOutput/log.cerr is where the current best is visible.

# -> Stopped, it has basically converged. Moved everything to spearmintExps/epoch200
# I copied the config.json there as well.
# Turns out the best is the maximal allowed inDim 50 and the maximal allowed minibatchSize (!) 100.
# (We've seen smaller minibatchSizes to be better when inDim was small, haven't we? Not sure anymore.)
# Learning rate converged to ~10, it was constrained to [0.2, 50].

Spearmint/spearmint/cleanup.sh .
python Spearmint/spearmint/main.py . > spearmintOutput/log.cout 2> spearmintOutput/log.cerr
# - logs of individual runs are in spearmintOutput/*/log.txt
# - spearmint current best is in spearmintOutput/log.cerr
# - jobs are logged in ./output/*. It's really only useful for two things:
#   it has cerrs of my jobs, and it has the running times.
# - if we want to graph or something, mongodb is the way, dbname is in config.json

# Hideous but mostly harmless hack while I learn to query the mongodb or write better logging:
grep final spearmintOutput/*/log.txt | sed "s/\/log.txt:final performance / /" | sed "s/spearmintOutput\///" | tr ' -' '\t' | awk '{ print $NF "\t" $0 }' | sort -n

# TODOS
# - run the current best for a large number of epochs.
# - tune the last important untuned parameter: the variance of the input gaussian,
#   or more generally, the input distribution. (value is not very sensitive to inDim,
#   so we might as well fix it as small.)
# - figure out a metric that punishes memorizing samples.
# - log running times in log.txt. maybe we can play tricks with taking
#   the median of epoch runtimes instead of sum, that would approximate CPU time pretty well.
# - save git sha + diff in exp dir.
# - revive the mainLowDim codepath.

# Which conf is currently the best?
grep final spearmintOutput/*/log.txt | awk '{ print $NF,$0 }' | grep -v "^nan" | sort -n | head -1 | sed "s/log\.txt.*/conf.txt/"
open `grep final spearmintOutput/*/log.txt | awk '{ print $NF,$0 }' | sort -n | grep -v "^nan" | head -10 | cut -f2 -d' ' | cut -f1 -d':' | sed "s/log\.txt/s400.png/"`
# -> Visually, some of them are more perfect but less diverse,
# some of them are varying a lot in brightness,
# TODO which parameters influence these?

# Seems like epoch200 and epoch400 does not tell much about the later convergence
# properties of a param-setting. How about epoch1600?

# I took the current best, rounded the params a bit, and the result is
# deepDives/conf1.txt
# output is deepDives/conf1-hls200-inDim20-lr10-mom0.6-n300-os4.0
# The above is the general workflow: Take promising confs, tune them,
# set expName to deepDives/confN-DETAILED_DESCRIPTION_PATH,
# put them into deepDives/confN.txt, add that to git.
# When it has run, maybe add final round output to git as well.

# As seen on
# https://docs.google.com/spreadsheets/d/1IWE7_Xeh81Pa9MgaV2QsDKJSHYmkQjBQring_xdC3CY/edit#gid=0
# , overfitting kicks in a epoch12000.
# epoch TMean   TMedian VMean   VMedian (10-moving averages)
# 12000     4.1544335       4.2569459       4.19644         4.22872
# 87200     4.1218603       4.227801        4.2057856       4.2594421

# conf2 is same as conf1 except for the smaller learning rate 10->1.
# Surprisingly the convergence is not that much slower.
# 
# Also surprisingly, it seems like it will never reach conf1 accuracy.
# (conf2 vmean settling near 4.27 at epoch24000 but already at 4.28 at epoch1000.
# while conf1 vmean stopped at 4.19 at epoch14000.)

# I fixed a visualization UX issue: s*.png are now generated from
# the same random numbers, so that they form an animation.
# The flipside is the we now see a smaller part of the generated space.
# spearmintExps/epoch1600/output/00000136.out aka
# spearmintExps/epoch1600/hls117-inDim88-lr2.12805643612-mom0.647445989185-n300-os3.9988942992
# is the first such one.

mv spearmintOutput spearmintExps/epoch1600
mv output spearmintExps/epoch1600/

# Let's try conf1 with layerNum=3, and call it conf3.
# ...Wow. That's amazing. At vmean 4.12 at epoch2800.
# Maybe only the bigger number of parameters? Should check.

# conf3 vmean plateaued between epoch4400 and epoch12000 at 4.10,
# and then slowly crawled up to 4.13.

# The new spearmint run epochCount4800_depth3_useReLUFalse_everyNthInput10
# runs on commit 414fb5df9d8bec71f1c05ae199f6f891ca3a5cb1.
# It is different from the parent epochCount1600_useReLUFalse_everyNthInput10
# in the following ways:
# layerNum 2 -> 3, epoch 1600 -> 4800, plotEach 400 -> 800
# learningRate.max 200.0 -> 20.0.
# indim (20,100) -> (10,50)
# and uses vmean instead of vmedian as value.
# Be careful when you compare with the previous spearmint run's vmedians.
# (They move together anyway, but vmedian is super bumpy. A typical difference between the two:
# vmedian is 0.06 larger than vmean, regardless of the current epoch.)

mkdir spearmintOutput
python Spearmint/spearmint/main.py . > spearmintOutput/log.cout 2> spearmintOutput/log.cerr

# Weirdly, its top contender after 9 runs,
# 4.489997 spearmintOutput/hls300-inDim10-lr6.34021189647-mom0.5-n300-os3.58636953526
# has parameters quite similar to
# 4.106030 deepDives/conf3-d3-hls200-inDim20-lr10-mom0.6-n300-os4.0
# , but the numbers are much-much worse at epoch4800:
# conf3     epoch 4800 trainMean 3.938845 trainMedian 4.025593 validationMean 4.106030 validationMedian 4.138099
# spearmint epoch 4800 trainMean 4.452593 trainMedian 4.579250 validationMean 4.489997 validationMedian 4.532965
# UPDATE: I seriously botched this: layerNum 3 was the main idea,
# but I actually used layer2. Useless, I put it into Attic/botched.depth2insteadofdepth3
# See below notes on epochCount4800_depth3_4_useReLUFalse_everyNthInput10 about how I fixed this.

# deepDives/conf4 is the same as the successful conf3, but with the faces dataset.
# One weird thing is that the output has lots of damaged pixels which are always black.
# (Probably always negative, and clipped to 0.) These go away, but very very slowly:
# at epoch5000 we have ~25 damaged pixels, epoch12000 ~10, epoch20000 exactly 2.
# Unfortunately the result of conf4 is not very convincing. Some of the time it's
# just rote learning, other times the nearest generated sample is a linear combination
# of two rote-learned faces. At least it's pretty good at rote learning:
# reproduces quite a few details of the train sample.
# Of course, what did I expect with just 400 training samples and minibatchsize n300?

# Motivated by this, I implemented the following benchmark and visualization:
# Same as diff_validation, but with the train dataset taking the place of the generated
# samples. Needs some refactor. I'll call this the nnbaseline, nn as in nearest neighbor.
# It only has to be run once for each dataset, but it's not a big deal if we run it
# once for each traning session.
# Values:
# inputType=mnist, inputDigit=None, everyNthInput=10, gridSizeForSampling=20
# nnbaselineMean 4.863300 nnbaselineMedian 5.040003
# -> Why is gridSizeForSampling relevant? Because of a stupid mixing of
# responsibilities, we use only the first gridSizeForSampling**2 validation points.
# -> mnist() random seed set to 1. We do randomization there, but reproducibly.

# That sound like good news, and it probably is: our current best is
# epoch 6400 trainMean 3.906343 trainMedian 4.017440 validationMean 4.103766 validationMedian 4.130489
# , which was probably meta-overfitted a bit, but still better.
# But before we start to celebrate, this is probably an artifact:
# Our generated samples are smoothed, less sharp compared to the gold samples,
# so a close but imperfect match is scored higher than when we compare two gold ones.

# inputType=image, imageDirectory=../face/SCUT-FBP/thumb.big/, everyNthInput=1, gridSizeForSampling=20
# nnbaselineMean 6.403875 nnbaselineMedian 6.177893
# nnbaselineMean 5.891883 nnbaselineMedian 5.616794 (different seed: 1)
# nnbaselineMean 5.928859 nnbaselineMedian 5.845743 (another seed: 2)
# our current best: (bestish, didn't want to meta-overfit by picking the specific best)
# epoch 28000 trainMean 3.643037 trainMedian 3.592704 validationMean 4.875953 validationMedian 4.736241
# -> This is impressive, but not directly comparable, I forgot to fix the random seed.
# (Fixed now, but don't know the seed for conf3. Ouch.
# TODO Should be a parameter to make the whole run reproducible.)

# What about visual comparison? mnist looks okay to me. If it's rote learning, it's
# at least quite convincing. The samples conf4 generates are evil, with all this mixing,
# but the diffs look okay when compared to the nnbaseline (which is bad, not enough data points).
# Side remark: Even though the individual s*.png-s are shitty, s.gif is pretty cool,
# mixing looks like constant smooth crossfading there, and the details slowly emerging look great,
# rote learning or not.

for dir in diff_validation diff_train s xy yz xz ; do convert input.png $dir[1-9]00.png $dir[0-9][0-9]00.png $dir[0-9][0-9][0-9]00.png -delay 20 -loop 0 $dir.gif ; done


#####

# Turns out, I seriously botched the epoch4800 spearmint run: used layerNum 2 instead of 3.
# Try again: epochCount4800_depth3_4_useReLUFalse_everyNthInput10
# It is different from the parent epochCount1600_useReLUFalse_everyNthInput10 aka spearmintExps/epoch1600
# in the following ways:
# layerNum 2 -> [3,4], epoch 1600 -> 4800, plotEach 400 -> 800
# learningRate.max 200.0 -> 20.0.
# indim [20,100] -> [10,50]

