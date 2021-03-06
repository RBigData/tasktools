% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mpi_lapply.r
\name{mpi_lapply}
\alias{mpi_lapply}
\title{mpi_napply}
\usage{
mpi_lapply(
  X,
  FUN,
  ...,
  checkpoint_path = NULL,
  checkpoint_freq = 1,
  preschedule = TRUE
)
}
\arguments{
\item{X}{A list or vector on rank 0 autmoatically distributed to other ranks. Values
on other ranks will be ignored (passing \code{NULL} is recommended).}

\item{FUN}{Function to evaluate.}

\item{...}{Additional arguments passed to \code{FUN}.}

\item{checkpoint_path}{If a path is specified, then each MPI rank will write checkpoints to disk
during execution. If this path is global (the same on all ranks), then that
path should be accessible to all ranks. However, a local path pointing to
node-local storage can also be used. All checkpoint files will be removed on
successful completion of the function. If the value is the default
\code{NULL}, then no checkpointing takes place.}

\item{checkpoint_freq}{The checkpoint frequency; a positive integer.}

\item{preschedule}{Should the jobs be distributed among the MPI ranks up front? Otherwise, the
jobs will be evaluated on a "first come first serve" basis among the ranks.}
}
\value{
A list on rank 0.
}
\description{
A distributed \code{lapply()} function.
}
\details{
The vector/list \code{X} should be on rank 0. If it is already distributed,
then you should just cally \code{lapply()} on the (already) local data.

If \code{preschedule=FALSE} then jobs are likely to be evaluated out of order
(that's actually the point). However, the return is reconstructed in the
linear order, so that the first element of the return list is the value
resulting from evaluating \code{FUN} at 1, the second at 2, and so on.
}
