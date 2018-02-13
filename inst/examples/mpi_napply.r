suppressMessages(library(pbdMPI))
suppressMessages(library(tasktools))

testfun = function(i)
{
  rank = comm.rank()
  cat(paste("iter", i, "executed on rank", rank, "\n"))
  rank
}

out = mpi_napply(5, testfun, preschedule=FALSE)
comm.cat("\n", quiet=TRUE)
comm.print(out)

finalize()
