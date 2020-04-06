#' tasktools-package
#' 
#' @description
#' Tools for task-based parallelism with MPI via pbdMPI.
#' Several utilities are provided, each with an apply-like interface. There is
#' support for pre-scheduling tasks as well as a "load-balancing" mode that
#' farms them out from a central process. Finally, the functions support
#' checkpointing, which allows the task runs to be interrupted and restarted
#' from their last completed task.
#' 
#' @importFrom crlapply crlapply
#' @import pbdMPI
#' 
#' @docType package
#' @name tasktools-package
#' @author Drew Schmidt
#' @keywords package
NULL
