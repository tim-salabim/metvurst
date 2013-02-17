\name{strip}
\alias{strip}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{create hour ~ day heatmaps of environmental data
%%  ~~function to do ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
strip(x, date, fun = mean, range, cond = rep(" ", length(x)), arrange = c("long", "wide"), colour = rev(brewer.pal(11, "Spectral")), ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{x}{
%%     ~~Describe \code{x} here~~
}
  \item{date}{
%%     ~~Describe \code{date} here~~
}
  \item{fun}{
%%     ~~Describe \code{fun} here~~
}
  \item{range}{
%%     ~~Describe \code{range} here~~
}
  \item{cond}{
%%     ~~Describe \code{cond} here~~
}
  \item{arrange}{
%%     ~~Describe \code{arrange} here~~
}
  \item{colour}{
%%     ~~Describe \code{colour} here~~
}
  \item{\dots}{
%%     ~~Describe \code{\dots} here~~
}
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function (x, date, fun = mean, range, cond = rep(" ", length(x)), 
    arrange = c("long", "wide"), colour = rev(brewer.pal(11, 
        "Spectral")), ...) 
{
    cat("\n", "Module   :  strip", "\n", "Author   :  Tim Appelhans <tim.appelhans@gmail.com>, Thomas Nauss", 
        "\n", "Version  :  2012-01-06", "\n", "License  :  GNU GPLv3, see http://www.gnu.org/licenses/", 
        "\n")
    stopifnot(require(latticeExtra))
    stopifnot(require(grid))
    stopifnot(require(reshape))
    stopifnot(require(plyr))
    stopifnot(require(RColorBrewer))
    Old.TZ <- Sys.timezone()
    Sys.setenv(TZ = "UTC")
    df <- data.frame(x, date, cond)
    condims <- as.character(unique(cond))
    condims <- subset(condims, condims != "" | condims != NA)
    years <- substr(df$date, 1, 4)
    uniyears <- unique(years)
    df$years <- years
    minx <- if (missing(range)) 
        min(na.exclude(df$x))
    else range[1]
    maxx <- if (missing(range)) 
        max(na.exclude(df$x))
    else range[2]
    xlist <- split(df, df$years, drop = T)
    xlist <- sapply(seq(xlist), function(i) {
        split(xlist[[i]], xlist[[i]]$cond, drop = T)
    })
    ls <- lapply(seq(xlist), function(i) {
        date <- as.character(xlist[[i]]$date)
        x <- xlist[[i]]$x
        origin <- paste(substr(date[1], 1, 4), "01-01", sep = "-")
        unldate <- lapply(as.POSIXlt(date), "unlist")
        hour <- unldate$hour
        juldays <- as.Date(date, origin = as.Date(origin))
        jul <- format(juldays, "\%j")
        date_from <- as.POSIXct(origin)
        year <- substr(origin, 1, 4)
        date_to <- as.POSIXct(paste(year, "12-31", sep = "-"))
        deltat <- 60 * 60
        tseries <- seq(from = date_from, to = date_to, by = deltat)
        strip_z <- matrix(NA, nrow = 25, ncol = length(unique(as.Date(tseries))))
        date_x <- as.Date(date)
        hour_x <- ifelse(hour < 10, paste("0", hour, sep = ""), 
            as.character(hour))
        datetime_x <- paste(date_x, hour_x, sep = " ")
        datetime_x <- paste(datetime_x, "00", sep = ":")
        z_x <- aggregate(x ~ datetime_x, FUN = fun)
        index_hour <- substr(z_x$datetime_x, 12, 13)
        index_date <- as.Date(z_x$datetime_x)
        mat_x <- cbind((as.integer(index_hour) + 1), julian(index_date + 
            1, origin = as.Date(origin)))
        strip_z[mat_x] <- z_x$x
        xblockx <- sort(julian(tseries, origin = as.Date(origin)))
        xbar <- format(tseries, "\%b")
        xlabs <- format(unique(xbar, "\%b"))
        xat <- seq.Date(as.Date(date_from), as.Date(date_to), 
            by = "month")
        xat <- as.integer(julian(xat, origin = as.Date(origin))) + 
            15
        levelplot(t(strip_z), ylim = c(24.5, -0.5), col.regions = colour, 
            strip = F, ylab = "Hour of day", xlab = NULL, asp = "iso", 
            at = seq(minx, maxx, 0.1), strip.left = strip.custom(bg = "black", 
                factor.levels = toupper(condims), par.strip.text = list(col = "white", 
                  font = 2, cex = 0.8)), as.table = T, cuts = 200, 
            between = list(x = 0, y = 0), scales = list(x = list(at = xat, 
                labels = xlabs), y = list(at = c(18, 12, 6))), 
            colorkey = list(space = "top", width = 1, height = 0.7, 
                at = seq(minx, maxx, 0.1)), panel = function(x, 
                ...) {
                grid.rect(gp = gpar(col = NA, fill = "grey50"))
                panel.levelplot(x, ...)
                panel.xblocks(xblockx, y = xbar, height = unit(1, 
                  "native"), col = c("black", "white"), block.y = -0.5, 
                  border = "black", last.step = 1.25, lwd = 0.3)
                panel.abline(h = c(6, 18), lty = 2, lwd = 0.5, 
                  col = "grey90")
            }, ...)
    })
    out <- ls[[1]]
    out2 <- out
    if (length(ls) > 1) {
        for (i in 2:(length(xlist))) out <- c(out, ls[[i]], x.same = T, 
            y.same = T, layout = switch(arrange, long = c(1, 
                length(condims)), wide = NULL))
    }
    else out
    out <- update(out, scales = list(y = list(rot = list(0, 0)), 
        tck = c(0, 0)), ylim = c(24.5, -0.5))
    ifelse(length(ls) > 1, print(out), print(out2))
    Sys.setenv(TZ = Old.TZ)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
