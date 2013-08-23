strip <- function(x, 
                  date,
                  fun = mean,
                  range,
                  cond = rep(" ", length(x)),
                  arrange = c("long", "wide"),
                  colour = rev(brewer.pal(11, "Spectral")),
                  ...) {
  
################################################################################
##  
##  This program plots meteorological parameters as
##  a function of time of day (y-axis) and day of year (x-axis). Values are
##  colour shaded from minimum to maximum. It is possible to supply a
##  conditioning variable (as this function uses trellis plotting).
##  NOTE: observations must be hourly or higher frequency!
##  
##  parameters are as follows:
##  
##  x (numeric):          Object to be plotted (e.g. temperature).
##  date (character):     Date(time) of the observations.
##                        Format must be 'YYYY-MM-DD hh:mm(:ss)'
##  fun (default mean):   The function to be used for aggregation to hourly 
##                        observations (if original is of higher fequency).
##  cond (factor):        Conditioning variable.
##	arrange (character):  One of "wide" or "long". For plot layout.
##  colour (character):   a vector of color names.
##  ...                   Further arguments to be passed to levelplot
##                        (see ?lattice::leveplot for options).
##
################################################################################
##
##  Copyright (C) 2012 Tim Appelhans, Thomas Nauss
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
##  Please send any comments, suggestions, criticism, or (for our sake) bug
##  reports to tim.appelhans@gmail.com
##
################################################################################

########## FUNCTION BODY #######################################################
  
  ## load packages needed (produce error message if not installed)
  stopifnot(require(latticeExtra))
  stopifnot(require(grid))
  stopifnot(require(reshape))
  stopifnot(require(plyr))
  stopifnot(require(RColorBrewer))


  ## set system locale time zone to "UTC" for time handling w/out
  ## daylight saving - save current (old) time zone setting
  Old.TZ <- Sys.timezone()
  Sys.setenv(TZ = "UTC")
  
  df <- data.frame(x, date, cond)
  condims <- as.character(unique(cond))
  condims <- subset(condims, condims != "" | condims != NA)

  minx <- if (missing(range)) min(na.exclude(df$x)) else range[1]
  maxx <- if (missing(range)) max(na.exclude(df$x)) else range[2]

  xlist <- split(df, df$cond, drop = T)
  
  ls <- lapply(seq(xlist), function(i) {

    date <- as.character(xlist[[i]]$date)
    x <- xlist[[i]]$x
    origin <- paste(substr(date[1], 1, 4), "01-01", sep = "-")
    unldate <- lapply(as.POSIXlt(date), "unlist")
    hour <- unldate$hour   

    ## calculate different times objects
    juldays <- as.Date(date, origin = as.Date(origin))
    jul <- format(juldays, "%j")  
    
    ## create regular time series for year of origin
    date_from <- as.POSIXct(origin)
    year <- substr(origin, 1, 4)
    date_to <- as.POSIXct(paste(year, "12-31", sep = "-"))
    deltat <- 60 * 60
    tseries <- seq(from = date_from, to = date_to, 
                   by = deltat)

    strip_z <- matrix(NA, nrow = 25, ncol = length(unique(as.Date(tseries))))

    date_x <- as.Date(date)
    hour_x <- ifelse(hour < 10, paste("0", hour, sep = ""), 
                     as.character(hour))
    datetime_x <- paste(date_x, hour_x, sep = " ")
    datetime_x <- paste(datetime_x, "00", sep = ":")

    z_x <- aggregate(x ~ datetime_x, FUN = fun)

    index_hour <- substr(z_x$datetime_x, 12, 13)
    index_date <- as.Date(z_x$datetime_x)
  
    mat_x <- cbind((as.integer(index_hour) + 1), 
                   julian(index_date + 1, origin = as.Date(origin)))

    strip_z[mat_x] <- z_x$x
    
    xblockx <- sort(julian(tseries, origin = as.Date(origin)))
    xbar <- format(tseries, "%b")
    xlabs <- format(unique(xbar, "%b"))
    xat <- seq.Date(as.Date(date_from), as.Date(date_to), by = "month")
    xat <- as.integer(julian(xat, origin = as.Date(origin))) + 15
    
    clr <- colorRampPalette(colour)(1000)
    
    levelplot(t(strip_z), ylim = c(24.5, -0.5), 
              col.regions = clr,
              strip = F, ylab = "Hour of day", xlab = NULL, asp = "iso",
              at = seq(minx, maxx, 0.1),
              strip.left = strip.custom(
                bg = "black", factor.levels = toupper(condims),
                par.strip.text = list(col = "white", font = 2, cex = 0.8)),
              as.table = T, cuts = 200, between = list(x = 0, y = 0),
              scales = list(x = list(at = xat, labels = xlabs),
                            y = list(at = c(18, 12, 6))),
              colorkey = list(space = "top", width = 1, height = 0.7,
                              at = seq(minx, maxx, 0.1)), 
              panel = function(x, ...) {
                grid.rect(gp=gpar(col=NA, fill="grey50"))
                panel.levelplot(x, ...)
                panel.xblocks(xblockx, y = xbar, height = unit(1, "native"),
                              col = c("black", "white"), block.y = -0.5,
                              border = "black", last.step = 1.25, lwd = 0.3)
                
                panel.abline(h = c(6, 18), lty = 2, lwd = 0.5, col = "grey90")
              },  
              ...)
  })

  out <- ls[[1]]
  out2 <- out
  if (length(ls) > 1) {
    for (i in 2:(length(xlist)))
      out <- c(out, ls[[i]], x.same = T, y.same = T, 
               layout = switch(arrange,
                               "long" = c(1,length(condims)),
                               "wide" = NULL))
  } else out

  out <- update(out, scales = list(y = list(rot = list(0, 0)), tck = c(0, 0)),
                ylim = c(24.5, -0.5))

  ifelse(length(ls) > 1, return(out), return(out2))
  
  ## revert system local time zone setting to original
  Sys.setenv(TZ = Old.TZ)
  
  
}
