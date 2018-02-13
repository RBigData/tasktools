mpi_napply_preschedule = function(n, FUN, ..., checkpoint_path=NULL)
{
  rank = pbdMPI::comm.rank()
  jobs = pbdMPI::get.jid(n)
  
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



mpi_napply_nopreschedule = function(n, FUN, ..., checkpoint_path=NULL)
{
  size = pbdMPI::comm.size()
  rank = pbdMPI::comm.rank()
  
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
    }
    else
    {
      ### TODO checkpoint
      org.local = c(org.local, i)
      
      ret.local.i = lapply(X=i, FUN=FUN, ...)
      ret.local = c(ret.local, ret.local.i)
      
      spmd.send.integer(1L, rank.dest=0L)
      
      i = spmd.recv.integer(x.buffer=integer(1), rank.source=0)
      
      if (i == -1L)
        break
    }
  }
  
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
  
  
  ret
}



#' mpi_napply
#' 
#' An "n-apply" function. 
#' 
#' @details
#' TODO
#' 
#' @param n
#' A global, positive integer.
#' @param FUN
#' Function to evaluate.
#' @param ...
#' Additional arguments passed to \code{FUN}.
#' @param checkpoint_path
#' TODO
#' @param preschedule
#' TODO
#' 
#' @return
#' TODO
#' 
#' @export
mpi_napply = function(n, FUN, ..., checkpoint_path=NULL, preschedule=TRUE)
{
  size = comm.size()
  
  #TODO param checking
  
  if (size < 2)
    comm.stop("function requires at least 2 ranks")
  
  if (isTRUE(preschedule) || n <= size)
    mpi_napply_preschedule(n=n, FUN=FUN, checkpoint_path=checkpoint_path, ...)
  else
    mpi_napply_nopreschedule(n=n, FUN=FUN, checkpoint_path=checkpoint_path, ...)
}
