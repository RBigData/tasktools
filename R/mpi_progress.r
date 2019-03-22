progress_bar = function(done, tot, chars=30)
{
  n_full = floor(done/tot*chars)
  n_empty = chars - n_full
  
  paste0(
    "[",
    paste0(rep("=", n_full), collapse=""),
    paste0(rep("-", n_empty), collapse=""),
    "]",
    " (", as.integer(done), "/", as.integer(tot), ")\n",
    collapse=""
  )
}



check_is_prescheduled = function(checkpoint_file)
{
  load(checkpoint_file)
  !isTRUE(exists("org.local"))
}



#' mpi_progress
#' 
#' Show a progress bar for MPI tasks that use checkpointing. This is meant to be
#' called by an external process and not the "big job" itself. For example,
#' while the job is running, you might occasionally log in to the login node
#' and run \code{tasktools::mpi_progress("/path/to/checkpoints")}.
#' 
#' @details
#' If all checkpoint files are in a single path, then you simply need to pass
#' that path (as a string) to the function. This is typical if you are using a
#' parallel file system. However, if the R processes use different paths for
#' the checkpoint files, then you can pass all of those paths as a character
#' vector. However, the calling process must be able to access all of those
#' paths (i.e. it can't be node-local).
#' 
#' @param checkpoint_path
#' Path to the checkpoint files. Some extra restrictions here apply that do not
#' apply to the \code{mpi_*ply()} functions themselves. See the details section
#' for more information.
#' 
#' @return
#' Invisibly returns \code{NULL}.
#' 
#' @export
mpi_progress = function(checkpoint_path)
{
  checkpoint_files = dir(checkpoint_path, full.names=TRUE, pattern="^pbd.*.rda")
  tot = 0L
  done = 0L
  
  # prescheduled
  if (check_is_prescheduled(checkpoint_files[1]))
  {
    for (checkpoint in checkpoint_files)
    {
      load(checkpoint)
      tot = tot + length(ret)
      done = done + start
    }
  }
  # not prescheduled
  else
  {
    for (checkpoint in checkpoint_files)
    {
      load(checkpoint)
      done = done + length(ret.local)
    }
    
    tot = n
  }
  
  bar = progress_bar(done, tot, chars=50)
  cat(bar)
  
  invisible()
}
