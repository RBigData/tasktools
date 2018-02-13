costly = function(x, waittime)
{
  Sys.sleep(waittime)
  print(paste("iteration:", x))
  
  sqrt(x)
}

crlapply::crlapply(1:10, costly, FILE="/tmp/cr.rdata", waittime=0.5)
