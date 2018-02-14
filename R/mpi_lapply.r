distribute_X = function(X)
{
  if (comm.rank() == 0)
  {
    size = comm.size()
    id = get.jid(length(X), all=TRUE)
    
    X.local = X[id[[1L]]]
    
    for (rank in 1:(size-1L))
    {
      X.send = X[id[[rank+1L]]]
      send(X.send, rank.dest=rank)
    }
  }
  else
    X.local = recv(rank.source=0)
  
  X.local
}



mpi_lapply_preschedule = function(X, FUN, ..., checkpoint_path=NULL)
{
  n = length(X)
  jobs = distribute_X(X)
  rank = pbdMPI::comm.rank()
  
  if (!is.null(checkpoint_path))
  {
    checkpoint = paste0(checkpoint_path, "/pbd", rank, ".rda")
    ret.local = crlapply(jobs, FUN, FILE=checkpoint, ...)
  }
  else
    ret.local = lapply(jobs, FUN=FUN, ...)
  
  ret = pbdMPI::spmd.gather.object(ret.local, rank.dest=0)
  
  if (rank != 0)
    ret = NULL
  else
    ret = do.call(c, ret)
  
  ret
}



mpi_lapply_nopreschedule = function(X, FUN, ..., checkpoint_path=NULL)
{
  # TODO
  comm.stop("not yet implemented")
}



#' mpi_napply
#' 
#' A distributed \code{lapply()} function.
#' 
#' @details
#' The vector/list \code{X} should be on rank 0. If it is already distributed,
#' then you should just cally \code{lapply()} on the (already) local data.
#' 
#' If \code{preschedule=FALSE} then jobs are likely to be evaluated out of order
#' (that's actually the point). However, the return is reconstructed in the
#' linear order, so that the first element of the return list is the value
#' resulting from evaluating \code{FUN} at 1, the second at 2, and so on.
#' 
#' @param X
#' A list or vector on rank 0 autmoatically distributed to other ranks. Values
#' on other ranks will be ignored (passing \code{NULL} is recommended).
#' @param FUN
#' Function to evaluate.
#' @param ...
#' Additional arguments passed to \code{FUN}.
#' @param checkpoint_path
#' If a path is specified, then each MPI rank will write checkpoints to disk
#' during execution. If this path is global (the same on all ranks), then that
#' path should be accessible to all ranks. However, a local path pointing to
#' node-local storage can also be used. All checkpoint files will be removed on
#' successful completion of the function. If the value is the default
#' \code{NULL}, then no checkpointing takes place.
#' @param preschedule
#' Should the jobs be distributed among the MPI ranks up front? Otherwise, the
#' jobs will be evaluated on a "first come first serve" basis among the ranks.
#' 
#' @return
#' A list on rank 0.
#' 
#' @export
mpi_lapply = function(X, FUN, ..., checkpoint_path=NULL, preschedule=TRUE)
{
  size = comm.size()
  
  check.is.function(FUN)
  check.is.flag(preschedule)
  if (!is.null(checkpoint_path))
    check.is.string(checkpoint_path)
  
  if (size < 2)
    comm.stop("function requires at least 2 ranks")
  
  if (isTRUE(preschedule) || length(X) <= size)
    mpi_lapply_preschedule(X=X, FUN=FUN, checkpoint_path=checkpoint_path, ...)
  else
    mpi_lapply_nopreschedule(X=X, FUN=FUN, checkpoint_path=checkpoint_path, ...)
}
