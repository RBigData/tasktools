# tasktools

* **Version:** 0.2-0
* **Status:** [![Build Status](https://travis-ci.org/RBigData/tasktools.png)](https://travis-ci.org/RBigData/tasktools)
* **License:** [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause)
* **Author:** Drew Schmidt


Tools for task-based parallelism with MPI via pbdMPI. Currently we provide these basic functions:

1. `mpi_napply()` --- a distributed `lapply()` that operates on an integer sequence. Supports checkpoint/restart and non-prescheduled workloads.
2. `mpi_lapply()` --- a fully general, distributed `lapply()`.

These functions are conceptually similar to `pbdLapply()` from the [pbdMPI package](https://github.com/RBigData/pbdMPI), but with some key differences. The pbdMPI functions have more modes of operation, allowing for different kinds of distributions of the inputs for the more general `mpi_lapply()`. And naturally, the pbdMPI functions do not handle checkpoint/restart.

In addition to these "ply" functions, also offer `mpi_progress()` to check on the status of running jobs.



## Installation

You can install the stable version from [the HPCRAN](https://hpcran.org) using the usual `install.packages()`:

```r
install.packages("tasktools", repos=c("https://hpcran.org", "https://cran.rstudio.com"))
```

The development version is maintained on GitHub:

```r
remotes::install_github("RBigData/tasktools")
```



## Examples

Complete source code for all of these examples can be found in the `inst/examples` directory of the tasktools source tree. Here we'll take a look at them in pieces. Throughout, we'll use a (fake) "expensive" function for our evaluations:

```r
costly = function(x, waittime)
{
  Sys.sleep(waittime)
  print(paste("iteration:", x))
  
  sqrt(x)
}
```

We can run a checkpointed `lapply()` in serial via `crlapply()` from the [crlapply package](https://github.com/wrathematics/crlapply):

```r
ret = crlapply::crlapply(1:10, costly, FILE="/tmp/cr.rdata", waittime=0.5)
unlist(ret)
```

If we save this source to the file `crlapply.r`. We can run it and kill it a few times to show its effectiveness:

```bash
$ r crlapply.r 
[1] "iteration: 1"
[1] "iteration: 2"
[1] "iteration: 3"
^C
$ r crlapply.r 
[1] "iteration: 4"
[1] "iteration: 5"
[1] "iteration: 6"
[1] "iteration: 7"
^C
$ r crlapply.r 
[1] "iteration: 8"
[1] "iteration: 9"
[1] "iteration: 10"

 [1] 1.000000 1.414214 1.732051 2.000000 2.236068 2.449490 2.645751 2.828427
 [9] 3.000000 3.162278
```

Since we are operating on the integer sequence of values 1 to 10, we can easily parallelize this, even distributing the work across multiple nodes, with `mpi_napply()`:

```r
ret = mpi_napply(10, costly, checkpoint_path="/tmp", waittime=1)
comm.print(unlist(ret))
```

To see exactly what happens during execution, we modify the printing in the "costly" function to be:

```r
cat(paste("iter", i, "executed on rank", comm.rank(), "\n"))
```

Let's run this with 3 MPI ranks. We can again run and kill it a few times to demonstrate the checkpointing:

```bash
$ mpirun -np 3 r mpi_napply.r 
iter 4 executed on rank 1 
iter 7 executed on rank 2 
iter 1 executed on rank 0 
^Citer 2 executed on rank 0 
iter 8 executed on rank 2 
iter 5 executed on rank 1 

$ mpirun -np 3 r mpi_napply.r 
iter 9 executed on rank 2 
iter 3 executed on rank 0 
iter 6 executed on rank 1 
iter 10 executed on rank 2 

 [1] 1.000000 1.414214 1.732051 2.000000 2.236068 2.449490 2.645751 2.828427
 [9] 3.000000 3.162278
```

There is also a non-prescheduling variant. This can be useful if there is a lot of variance among function evaluation for the inputs, and you want the values to be executed on a "first come, first serve" basis. All we have to do is set `preschedule=FALSE`:

```r
ret = mpi_napply(10, costly, preschedule=FALSE, waittime=1)
comm.print(unlist(ret))
```

Now, it's worth noting that in this case, rank 0 behaves as the manager, doling out work. So it is not used in computation:

```bash
iter 1 executed on rank 1 
iter 2 executed on rank 2 
iter 3 executed on rank 1 
iter 4 executed on rank 2 
iter 5 executed on rank 1 
iter 6 executed on rank 2 
iter 7 executed on rank 1 
iter 8 executed on rank 2 
iter 9 executed on rank 1 
iter 10 executed on rank 2 

 [1] 1.000000 1.414214 1.732051 2.000000 2.236068 2.449490 2.645751 2.828427
 [9] 3.000000 3.162278
```

This too supports checkpointing, but hopefully how that works is clear.



## Progress Bar

We also support a kind of progress bar, but it's definitely not what you're thinking. Let's start with an example similar to the one above:

```r
suppressMessages(library(tasktools))

f = function(i) {print(i); Sys.sleep(1); sqrt(i)}
ignore = mpi_napply(20, f, checkpoint_path="/tmp")

finalize()
```

We can put these into the file `slow_sqrt.r` and run it for a bit before manually killing it with `Ctrl`+`c`:

```
$ mpirun -np 3 Rscript slow_sqrt.r

[1] 14
[1] 7
[1] 1
[1] 15
^C[1] 16
[1] 8
[1] 2
```

We can check the progress by invoking `mpi_progress()`:

```bash
$ Rscript -e "tasktools::mpi_progress('/tmp')"
## [=================---------------------------------] (7/20)
```

The progress bar works by scanning the checkpoint files, so we don't actually have to kill the tasks to run the progress bar bit (and in fact for a real workflow, you wouldn't want to). But for the sake of demonstration, this is much simpler.

The above example was run with the default `preschedule=TRUE`, but it will also work if we have `preschedule=FALSE`. There are some caveats to the progress bar, however. Please carefully check the `?tasktools::mpi_progress` documentation.
