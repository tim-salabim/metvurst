#' Visualise large amounts of hourly data as yearly heatmaps
#'
#' @description
#' Produces a heatmap display of hourly time series data showing hour of day on
#' the y-axis and day-of-year in the x-axis
#'
#' @param x the variable to be plotted.
#' @param date the time series variable to be used for plotting. Needs to be 
#'   YYYY-MM-DD HH:MM format
#' @param fun the function to be used in case the time series is higher resolution 
#'   than hourly.
#' @param range the range of x to be plotted. Values outside this range will not
#'   be plotted.
#' @param cond the conditioning variable to be used for creating the various strips.
#'   Usually the year. If not supplied, year will be used by default.
#' @param arrange 'long' (the default) will render all strips in one column.
#'   'wide' will render things depending on device size.
#' @param colour the colour palette to be used for the heatmap.
#' @param n.col.levs the number of colour levels to interpolate to. 
#'   Increase this if the colour palette does not span all data values.
#' @param start the start date of the time series to plot. Only relevant for short
#'   time periods (i.e. sub-year).
#' @param end the end of the time series to plot. Corresponding to \code{start}.
#' 
#' @export strip
#' @name strip
#'
strip <- function(x, 
                  date,
                  fun = mean,
                  range,
                  cond = rep(" ", length(x)),
                  arrange = c("long", "wide"),
                  colour = colorRampPalette(rev(brewer.pal(11, "Spectral"))),
                  n.col.levs = 1000,
                  start,
                  end,
                  ...) {
  
  ## set system locale time zone to "UTC" for time handling w/out
  ## daylight saving - save current (old) time zone setting
  Old.TZ <- Sys.timezone()
  Sys.setenv(TZ = "UTC")
  
  st_missing = missing(start)
  nd_missing = missing(end)
  
  df <- data.frame(x, date, cond)
  condims <- as.character(unique(cond))
  condims <- subset(condims, condims != "" | !is.na(condims))

  minx <- if (missing(range)) min(na.exclude(df$x)) else range[1]
  maxx <- if (missing(range)) max(na.exclude(df$x)) else range[2]

  xlist <- split(df, df$cond, drop = T)

  ls <- lapply(seq(xlist), function(i) {

    date <- as.character(xlist[[i]]$date)
    x <- xlist[[i]]$x
    if (st_missing) {
      origin <- paste(substr(date[1], 1, 4), "01-01", sep = "-")
    } else {
      origin = start
    }
    unldate <- lapply(as.POSIXlt(date), "unlist")
    hour <- sapply(seq(unldate), function(j) unldate[[j]][["hour"]])   

    ## calculate different times objects
    juldays <- as.Date(date, origin = as.Date(origin))
    jul <- format(juldays, "%j")  
    
    ## create regular time series for year of origin
    date_from <- as.POSIXct(origin)
    year <- substr(origin, 1, 4)
    if (nd_missing) {
      date_to <- as.POSIXct(paste(year, "12-31", sep = "-"))
    } else {
      date_to = as.POSIXct(end)
    }
    deltat <- 60 * 60
    tseries <- seq(from = date_from, to = date_to, 
                   by = deltat)

    strip_z <- matrix(NA, nrow = 25, ncol = length(unique(as.Date(tseries))))

    date_x <- as.Date(date)
    hour_x <- sprintf("%02.f", hour)
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
    
    clr <- colour(n.col.levs)
    
    lattice::levelplot(t(strip_z), ylim = c(24.5, -0.5), 
                       col.regions = clr,
                       strip = F, ylab = "Hour of day", xlab = NULL, asp = "iso",
                       at = seq(minx, maxx, 0.1),
                       strip.left = lattice::strip.custom(
                         bg = "black", factor.levels = toupper(condims),
                         par.strip.text = list(col = "white", font = 2, cex = 0.8)),
                       as.table = T, cuts = 200, between = list(x = 0, y = 0),
                       scales = list(x = list(at = xat, labels = xlabs),
                                     y = list(at = c(18, 12, 6))),
                       colorkey = list(space = "top", width = 1, height = 0.7,
                                       at = seq(minx, maxx, 0.1)), 
                       panel = function(x, ...) {
                         grid::grid.rect(gp = grid::gpar(col=NA, fill="grey50"))
                         lattice::panel.levelplot(x, ...)
                         latticeExtra::panel.xblocks(
                           xblockx, y = xbar, height = grid::unit(1, "native"),
                           col = c("black", "white"), block.y = -0.5,
                           border = "black", last.step = 1.25, lwd = 0.3
                         )
                         
                         lattice::panel.abline(
                           h = c(6, 18), lty = 2, lwd = 0.5, col = "grey90"
                         )
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
