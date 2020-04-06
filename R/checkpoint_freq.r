check_checkpoint_freq = function(checkpoint_freq)
{
  freq = as.integer(checkpoint_freq)
  if (is.na(freq) || length(freq) != 1L || freq < 1L)
    comm.stop("argument 'checkpoint_freq' must be a positive integer")
  
  freq
}
