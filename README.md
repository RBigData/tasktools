# tasktools

* **Version:** 0.1-0
* **Status:** [![Build Status](https://travis-ci.org/rbigdata/tasktools.png)](https://travis-ci.org/rbigdata/tasktools)
* **License:** [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause)
* **Author:** Drew Schmidt


Tools for task-based parallelism with MPI via pbdMPI.


## Installation

<!-- To install the R package, run:

```r
install.packages("tasktools")
``` -->

The development version is maintained on GitHub, and can easily be installed by any of the packages that offer installations from GitHub:

```r
### Pick your preference
devtools::install_github("rbigdata/tasktools")
ghit::install_github("rbigdata/tasktools")
remotes::install_github("rbigdata/tasktools")
```



## Package Use

We'll take a very simple example with a fake "expensive" function:

```r
costly = function(x, waittime)
{
  Sys.sleep(waittime)
  print(paste("iteration:", x))
  
  sqrt(x)
}

crlapply::crlapply(1:10, costly, FILE="/tmp/cr.rdata", waittime=0.5)
```

We can save this to the file `example.r`. We'll run it and kill it a few times:

```bash
$ r example.r
[1] "iteration: 1"
[1] "iteration: 2"
[1] "iteration: 3"
[1] "iteration: 4"
^C
$ r example.r
[1] "iteration: 5"
[1] "iteration: 6"
[1] "iteration: 7"
^C
$ r example.r
[1] "iteration: 8"
[1] "iteration: 9"
[1] "iteration: 10"
[[1]]
[1] 1

[[2]]
[1] 1.414214

[[3]]
[1] 1.732051

[[4]]
[1] 2

[[5]]
[1] 2.236068

[[6]]
[1] 2.44949

[[7]]
[1] 2.645751

[[8]]
[1] 2.828427

[[9]]
[1] 3

[[10]]
[1] 3.162278
```
