mpi_napply_preschedule = function(n, FUN, ..., checkpoint_path=NULL, checkpoint_freq=1)
{
  rank = pbdMPI::comm.rank()
  jobs = pbdMPI::get.jid(n)
  
  if (!is.null(checkpoint_path))
  {
    checkpoint = paste0(checkpoint_path, "/pbd", rank, ".rda")
    ret.local = crlapply(jobs, FUN, checkpoint_file=checkpoint, checkpoint_freq=checkpoint_freq, ...)
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



mpi_napply_nopreschedule = function(n, FUN, ..., checkpoint_path=NULL)
{
  size = pbdMPI::comm.size()
  rank = pbdMPI::comm.rank()
  
  checkpointing = !is.null(checkpoint_path)
  
  if (checkpointing)
    checkpoint = paste0(checkpoint_path, "/pbd", rank, ".rda")
  
  # init
  if (checkpointing && file.exists(checkpoint))
      load(file=checkpoint)
  else
  {
    if (rank == 0)
    {
      i = size - 1L
      killed = 0L
      
      org.local = 0
      ret.local = NULL
    }
    else
    {
      i = rank
      
      org.local = integer(0)
      ret.local = list()
    }
  }
  
  
  # apply
  while (TRUE)
  {
    if (rank == 0)
    {
      i = i + 1L
      
      spmd.recv.integer(x.buffer=integer(1), rank.source=anysource())
      tag = get.sourcetag()
      sender = tag[1L]
      
      if (i <= n)
        spmd.send.integer(i, rank.dest=sender)
      else
      {
        spmd.send.integer(-1L, rank.dest=sender)
        killed = killed + 1L
        
        if (killed == size - 1L)
          break
      }
      
      if (checkpointing)
        save(file=checkpoint, i, killed, org.local, ret.local)
    }
    else
    {
      org.local = c(org.local, i)
      
      ret.local.i = lapply(X=i, FUN=FUN, ...)
      ret.local = c(ret.local, ret.local.i)
      
      spmd.send.integer(1L, rank.dest=0L)
      
      i = spmd.recv.integer(x.buffer=integer(1), rank.source=0)
      
      if (i == -1L)
        break
      
      if (checkpointing)
        save(file=checkpoint, n, i, org.local, ret.local)
    }
  }
  
  
  # send to rank 0 and reconstruct order
  org = pbdMPI::spmd.gather.object(org.local, rank.dest=0)
  ret.unordered = pbdMPI::spmd.gather.object(ret.local, rank.dest=0)
  
  if (rank != 0)
    ret = NULL
  else
  {
    ret = vector(mode="list", length=n)
    for (i in 2:length(org))
    {
      set = org[[i]]
      for (J in 1:length(set))
      {
        j.unordered = J
        j = set[J]
        ret[[j]] = ret.unordered[[i]][[j.unordered]]
      }
    }
  }
  
  
  if (checkpointing)
    file.remove(checkpoint)
  
  ret
}



#' mpi_napply
#' 
#' A distributed "n-apply" function. Syntactically, this is sugar for a
#' distributed \code{lapply(1:n, FUN)}.
#' 
#' @details
#' If \code{preschedule=FALSE} then jobs are likely to be evaluated out of order
#' (that's actually the point). However, the return is reconstructed in the
#' linear order, so that the first element of the return list is the value
#' resulting from evaluating \code{FUN} at 1, the second at 2, and so on.
#' 
#' @param n
#' A global, positive integer.
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
#' @param checkpoint_freq
#' The checkpoint frequency; a positive integer. The value is assumed to be 1
#' if \code{preschedule=FALSE}.
#' @param preschedule
#' Should the jobs be distributed among the MPI ranks up front? Otherwise, the
#' jobs will be evaluated on a "first come first serve" basis among the ranks.
#' 
#' @return
#' A list on rank 0.
#' 
#' @export
mpi_napply = function(n, FUN, ..., checkpoint_path=NULL, checkpoint_freq=1, preschedule=TRUE)
{
  size = comm.size()
  
  check.is.posint(n)
  check.is.function(FUN)
  check.is.flag(preschedule)
  if (!is.null(checkpoint_path))
  {
    check.is.string(checkpoint_path)
    checkpoint_freq = check_checkpoint_freq(checkpoint_freq)
  }
  
  if (size < 2)
    comm.stop("function requires at least 2 ranks")
  
  if (isTRUE(preschedule) || n <= size)
    mpi_napply_preschedule(n=n, FUN=FUN, checkpoint_path=checkpoint_path, checkpoint_freq=checkpoint_freq, ...)
  else
    mpi_napply_nopreschedule(n=n, FUN=FUN, checkpoint_path=checkpoint_path, ...)
}
