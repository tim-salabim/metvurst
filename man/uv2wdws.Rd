\name{uv2wdws}
\alias{uv2wdws}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{helper function to cenvert u & v wind components to wind direction and speed
%%  ~~function to do ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
uv2wdws(u, v)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{u}{
%%     ~~Describe \code{u} here~~
}
  \item{v}{
%%     ~~Describe \code{v} here~~
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
function (u, v) 
{
    degrees <- function(radians) 180 * radians/pi
    mathdegs <- degrees(atan2(v, u))
    wdcalc <- ifelse(mathdegs > 0, mathdegs, mathdegs + 360)
    wd <- ifelse(wdcalc < 270, 270 - wdcalc, 270 - wdcalc + 360)
    wd <- round(wd, 2)
    ws <- sqrt(u^2 + v^2)
    ws <- round(ws, 2)
    return(as.data.frame(cbind(wd, ws)))
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
