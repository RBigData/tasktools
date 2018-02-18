suppressMessages(library(pbdMPI))
suppressMessages(library(tasktools))

costly = function(x, waittime)
{
  Sys.sleep(waittime)
  rank = comm.rank()
  cat(paste("iter", i, "executed on rank", rank, "\n"))
  
  sqrt(x)
}

ret = mpi_napply(5, costly, preschedule=FALSE, waittime=comm.rank())
comm.cat("\n", quiet=TRUE)
comm.print(unlist(ret))

finalize()
