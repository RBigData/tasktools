suppressMessages(library(tasktools, quietly=TRUE))

costly = function(x, waittime)
{
  Sys.sleep(waittime)
  print(paste("rank:", comm.rank(), "iteration:", x))
  
  sqrt(x)
}

ret = mpi_napply(10, costly, checkpoint_path="/tmp", preschedule=FALSE, waittime=comm.rank())
comm.print(ret)

finalize()
