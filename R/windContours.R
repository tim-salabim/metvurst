
windContours <- function (hour = hour, 
                          wd = wd, 
                          ws = ws,
                          add.var,
                          smooth.contours = 1.2,
                          smooth.fill = 1.2,
                          spacing = 2,
                          centre = "S",
                          speedlim = 7,
                          labels = T,
                          stripname = "",
                          keytitle = "",
                          keyint = c(0, 15),
                          keyspacing = 1,
                          ncuts = 0.1,
                          gapcolor = "grey50",
                          colour = brewer.pal(9, "Greys"),
                          ...) {
  
  
  stopifnot(require("latticeExtra"))
  stopifnot(require("fields"))
  stopifnot(require("abind"))
  stopifnot(require("gridBase"))
  stopifnot(require("RColorBrewer"))
  
  cols <- colorRampPalette(colour)
  
  dircat_s <- ordered(ceiling(wd/10), levels=1:36, labels=1:36)
  dircat_n <- ordered(ceiling(wd/10), levels=c(19:36, 1:18), labels=1:36)
  dircat_w <- ordered(ceiling(wd/10), levels=c(10:36, 1:9), labels=1:36)
  dircat_e <- ordered(ceiling(wd/10), levels=c(28:36, 1:27), labels=1:36)
  
  dircat <- {if (centre=="N") dircat_n else
    if (centre=="E") dircat_e else
      if (centre=="S") dircat_s else
        dircat_w }

  labels_s <- c(45,90,135,180,225,270,315,360)
  labels_n <- c(225,270,315,360,45,90,135,180)
  labels_e <- c(315,360,45,90,135,180,225,270)
  labels_w <- c(135,180,225,270,315,360,45,90)
  
  label <- {if (centre=="N") labels_n else
    if (centre=="E") labels_e else
      if (centre=="S") labels_s else
        labels_w }
    
  tab.wd <- xtabs(~ dircat + hour)
  tab.wd_smooth <- image.smooth(tab.wd, theta = smooth.contours, 
                                xwidth = 0, ywidth = 0)

  freq.wd <- matrix(prop.table(tab.wd_smooth$z,2)[, 24:1]*100,
                    nrow=36,ncol=24)

  tab.add <- if (missing(add.var)) tab.wd else
    xtabs(add.var ~ dircat + hour) / tab.wd
  
  tab.add_smooth <- image.smooth(tab.add, theta = smooth.fill, 
                                 xwidth = 0, ywidth = 0)
  
  mat.add <- if (missing(add.var)) 
    matrix(prop.table(tab.add_smooth$z, 2)[, 24:1] * 100, 
           nrow = 36, ncol = 24) else
      tab.add_smooth$z[, 24:1]
  
  zlevs.fill <- if (missing(keyint)) seq(floor(min(mat.add)), 
                                         ceiling(max(mat.add)),
                                         by = ncuts)
                  else seq(keyint[1], keyint[2], by = ncuts)
  
  zlevs.conts <- if (missing(keyint)) seq(floor(min(freq.wd)), 
                                          ceiling(max(freq.wd)),
                                          by = spacing)
                  else seq(keyint[1], keyint[2], by = spacing)
  
  panel.filledcontour <- function(x, y, z, subscripts, at, fill.cont = T,
                                  col.regions = cols, 
                                  contours = T, 
                                  col = col.regions(length(zlevs.fill)), 
                                  ...)
  {
    stopifnot(require("gridBase"))
    z <- matrix(z[subscripts],
                nrow = length(unique(x[subscripts])),
                ncol = length(unique(y[subscripts])))
    if (!is.double(z)) storage.mode(z) <- "double"
    opar <- par(no.readonly = TRUE)
    on.exit(par(opar))
    if (panel.number() > 1) par(new = TRUE)
    par(fig = gridFIG(), omi = c(0, 0, 0, 0), mai = c(0, 0, 0, 0))
    cpl <- current.panel.limits()
    plot.window(xlim = cpl$xlim, ylim = cpl$ylim,
                log = "", xaxs = "i", yaxs = "i")
    # paint the color contour regions
    if (isTRUE(fill.cont)) 
      .filled.contour(as.double(do.breaks(cpl$xlim, 
                                          nrow(z) - 1)),
                      as.double(do.breaks(cpl$ylim, 
                                          ncol(z) - 1)),
                      z, levels = as.double(zlevs.fill), 
                      col = col)
    else NULL
    if (isTRUE(fill.cont)) 
      .filled.contour(as.double(do.breaks(cpl$xlim, 
                                          nrow(z) - 1)),
                      as.double(do.breaks(cpl$ylim, 
                                          ncol(z) - 1)),
                      z, levels = as.double(seq(0,0.2,0.1)), 
                      col = gapcolor)
    else NULL
    #add contour lines
    if (isTRUE(contours)) 
      contour(as.double(do.breaks(cpl$xlim, nrow(z) - 1)),
              as.double(do.breaks(cpl$ylim, ncol(z) - 1)),
              z, levels = as.double(zlevs.conts), 
              add=T,
              col = "grey10", # color of the lines
              drawlabels = labels  # add labels or not
              )
    else NULL
    if (isTRUE(contours))
      contour(as.double(do.breaks(cpl$xlim, nrow(z) - 1)),
              as.double(do.breaks(cpl$ylim, ncol(z) - 1)),
              z, levels = as.double(0.5), 
              add=T,
              col = "grey10", lty = 3,# color of the lines
              drawlabels = labels  # add labels or not
              )
    else NULL
  }

  out.fill <- levelplot(mat.add, 
                        panel = function(fill.cont, contours, ...) {
                          grid.rect(gp=gpar(col=NA, fill=gapcolor))
                          panel.filledcontour(fill.cont = T, 
                                              contours = F, ...)
                          },
                        col.regions = cols,
                        plot.args = list(newpage = FALSE))
 
  out.conts <- levelplot(freq.wd, 
                         panel = function(fill.cont, contours, ...) {
                           panel.filledcontour(fill.cont = F, 
                                               contours = T, ...)
                           },
                           col.regions = cols,
                           plot.args = list(newpage = FALSE),
                         colorkey = list(space = "top", at = zlevs.fill, 
                                         width = 1, height = 0.75, 
                                         labels = 
                                           list(at = 
                                                  seq(zlevs.fill[1],
                                                      zlevs.fill[length(zlevs.fill)],
                                                      spacing),
                                                cex = 0.7),
                                         col = cols))
  
  out.speed <- bwplot(rev(hour) ~ ws, xlim = c(-0.25, speedlim), 
                      ylim = 24.5:0.5, scales = list(x = list(draw = T), 
                                                     y=list(draw = F)), 
                      xlab = NULL, ylab = NULL)
  
  out.blank <- xyplot(hour ~ ws, xlim = c(-0.5, speedlim), ylim = 24.5:0.5, 
                      scales = list(x = list(draw = T), y=list(draw= F )), 
                      xlab = NULL, ylab = NULL, type = "n")
  
  addvar.combo <- c(out.fill, out.blank, x.same = F, y.same = F)
  addvar.out <- update(addvar.combo, layout = c(2, 1))
  conts.combo <- c(out.conts, out.speed, x.same = F, y.same = F)
  
  out.global <- update(conts.combo, layout = c(2, 1), strip = F, 
                       strip.left = strip.custom(
                         bg = "grey40", par.strip.text = list(col = "white", 
                                                              font = 2), 
                         strip.names = F, strip.levels = T, 
                         factor.levels = c("A", stripname)),
                       scales = list(x = list(draw = F), y = list(draw = F)),
                       par.settings = list(
                         layout.heights = list(axis.xlab.padding = 6), 
                         layout.widths = list(strip.left = c(0, 1)),
                         plot.symbol = list(pch = "*", col = "black"), 
                         box.umbrella = list(lty = 1, col = "grey40"),
                         box.rectangle = list(col = "grey40")),
                       pch = 20, fill = "grey70", cex = 0.7,
                       xlab = list(c("Direction [degrees]", 
                                     "Speed [m/s]"), cex = 1), 
                       ylab = "Hour\n\n", main = list(keytitle, cex = 1))
  
  y.at <- seq(22, 3, -3)
  y.labs <- seq(3, 21, 3)
  
  axislabGLOBAL <-  function() {  
    trellis.focus("panel", 1, 1, clip.off = T, highlight = F)
    panel.axis(side = "bottom", outside = T, at = seq(4.5, 36 ,by = 4.5), 
               labels = label, text.cex = 0.8)
    panel.axis(side = "left", outside = T, at = y.at, labels = y.labs, 
               text.cex = 0.8, check.overlap = T)
    trellis.focus("panel", 2, 1, clip.off = T, highlight = F)
    panel.axis(side = "bottom", outside = T, 
               at = pretty(0:speedlim), rot = 0,
               labels = pretty(0:speedlim), text.cex = 0.8)
    panel.axis(side = "right", outside = T, at = y.at, labels = NULL, 
               text.cex = 0.8)
    trellis.unfocus()
  }
  
  par(bg = "white")
  plot.new()
  print(out.global + as.layer(addvar.out, x.same = F, y.same = T, 
                              axes = NULL, under = T))
  axislabGLOBAL()
}

