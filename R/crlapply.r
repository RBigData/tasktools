check_checkpoint_freq = function(checkpoint_freq)
{
  freq = as.integer(checkpoint_freq)
  if (is.na(freq) || length(freq) != 1L || freq < 1L)
    comm.stop("argument 'checkpoint_freq' must be a positive integer")
  
  freq
}

#' crlapply
#' 
#' An \code{lapply()}-like interface with automatic checkpoint/restart
#' functionality. Checkpoint/restart is a useful strategy for running expensive
#' functions in constrained environments (non-reliable hardware, restricted time
#' limits, etc).
#' 
#' @details
#' The checkpoint file is cleaned up on successful completion of
#' \code{crlapply()}
#' 
#' @param X,FUN,...
#' Same as in \code{lapply()}.
#' @param checkpoint_file
#' The checkpoint file.
#' @param checkpoint_freq
#' The checkpoint frequency; a positive integer.
#' 
#' @return
#' A list.
#' 
#' @export
crlapply = function(X, FUN, ..., checkpoint_file, checkpoint_freq=1)
{
  if (missing(X))
    stop("argument 'X' is missing, with no default")
  if (missing(FUN))
    stop("argument 'FUN' is missing, with no default")
  if (missing(checkpoint_file))
    stop("argument 'FILE' is missing, with no default")
  
  checkpoint_freq = check_checkpoint_freq(checkpoint_freq)
  
  n = length(X)
  
  if (file.exists(checkpoint_file))
    load(file=checkpoint_file)
  else
  {
    start = 1L
    ret = vector(length=n, mode="list")
  }
  
  for (i in start:n)
  {
    ret[[i]] = FUN(X[i], ...)
    
    if (n %% checkpoint_freq == 0)
    {
      start = i+1L
      save(start, ret, file=checkpoint_file)
    }
  }
  
  
  file.remove(checkpoint_file)
  
  ret
}
