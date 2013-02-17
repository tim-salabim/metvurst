uv2wd <- function(u,v) {

degrees <- function(radians) 180 * radians / pi
    
mathdegs <- degrees(atan2(v, u))
wdcalc <- ifelse (mathdegs>0, mathdegs, mathdegs+360)
wd <- ifelse (wdcalc<270, 270-wdcalc, 270-wdcalc+360)

wd <- round(wd,2) 

return(wd)

}