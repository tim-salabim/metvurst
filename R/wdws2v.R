wdws2uv <- function(wd,ws) {

  radians <- function(degrees) degrees * pi / 180
  u <- -ws*sin(radians(wd))
  u <- round(u,2)
    
  radians <- function(degrees) degrees * pi / 180
  v <- -ws*cos(radians(wd))
  v <- round(v,2)
  
  return(cbind(u, v))

}