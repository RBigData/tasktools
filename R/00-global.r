# suppress false positive NOTE generated from mpi_progress()
utils::globalVariables(c("n", "ret", "ret.local", "start"))
