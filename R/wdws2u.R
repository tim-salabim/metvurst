wdws2u <- function(wd,ws) {
  
  radians <- function(degrees) degrees * pi / 180
  u <- -ws*sin(radians(wd))
  u <- round(u,2)
  return(u)
  
}