#' Convert hh:mm:ss time to hh.hhh
#'
#' @param input Single string or a vector of strings containing hours:minutes or hours:minutes:seconds.
#' @param unit the desired units of the output, one of "h" (hours), "m", (minutes) or "s" (seconds).
#'
#' @return A number or vector of numbers corresponding to the decimal hour equivalent of the character input.
#'
decimalTime <- function(input, unit = c("h", "m", "s")) {
  unit <- match.arg(unit)
  .converter <- function(x, unit) {
    x <- as.numeric(unlist(strsplit(x, ":")))
    if (length(x) == 2)
      x <- x[1] + x[2]/60
    if (length(x) == 3)
      x <- x[1] + x[2]/60 + x[3]/3600
    if (unit == "h")
      return(x)
    if (unit == "m")
      return(x * 60)
    if (unit == "s")
      return(x * 3600)
  }
  if (missing(input))
    stop("Input appears to be empty.")
  if (length(input) == 1) {
    output <- .converter(as.character(input), unit = unit)
    names(output) <- input
  }
  if (length(input) > 1)
    output <- sapply(as.character(input), function(i) .converter(i, unit = unit))
  return(output)
}

#' load a kinetic file from the spec in N3024
#' 
#' @param file the path to the file
#' 
#' @return a data frame with the wells in the columns and the timesteps in the rows
#' 
read_kinetic <- function(file, skip = 0) {
	input <- readLines(file)

	if (skip > 0)
		input <- input[-c(1:skip)]

	to_read <- input[1:(which(input[] == '')[1] - 1)]
	to_read[1] <- sub('\tT[^\t]*', '\tT', to_read[1])

	output <- read.table(textConnection(to_read), header = TRUE)

	output$Time <- decimalTime(output$Time, unit = 's')
	output$Time <- output$Time - output$Time[1]
	return(output)
}

#' plot kinetic data
#' 
#' @param input the dataframe inported using load_kinetic()
#' @param wells Optional: The wells to be plotted
#' 
#' @return A plot
#' 
plot_kinetic <- function(input, wells) {
	if (!missing(wells)) {
		if (!any(wells %in% colnames(input)))
			stop('Could not find one or more of the required wells in the input columns')

		aux <- input[, c('Time', wells)]
	}
	else {
		aux <- input[, -which(colnames(input) == 'T')]
	}

	pd <- reshape2::melt(aux, id.vars = 'Time')
	colnames(pd) <- c('Time', 'Well', 'Abs')

	p <- ggplot2::ggplot(data = pd, ggplot2::aes(x = Time, y = Abs, group = Well, colour = Well))
	p <- p + ggplot2::geom_line()
	p <- p + ggplot2::geom_point()
	p <- p + ggplot2::theme_bw()
	p
}

#' Calculate slopes from kinetic input
#' 
#' @param input the dataframe inported using load_kinetic()
#' @param wells Optional: The wells to be calculated
#' @param time_unit The input time unit (seconds or minutes)
#' @param abs_unit The input absorbance unit (OD or mOD)
#' 
#' @return A dataframe with the slopes calculated in mOD/min
#' 
calc_kinetic_slopes <- function(input, wells, trim, time_unit = c('seconds', 'minutes'), abs_unit = c('OD', 'mOD')) {
	time_unit <- match.arg(time_unit)
	abs_unit <- match.arg(abs_unit)

	if (!missing(wells)) {
		if (!any(wells %in% colnames(input)))
			stop('Could not find one or more of the required wells in the input columns')

		aux <- input[, c('Time', wells)]
	}
	else {
		aux <- input[, -which(colnames(input) == 'T')]
	}

	df <- reshape2::melt(aux, id.vars = 'Time')
	colnames(df) <- c('Time', 'Well', 'Abs')

	if (!missing(trim)) {
		if (!is.numeric(trim) | length(trim) != 2)
			stop('trim must be numeric and have two values')
		df <- df[df$Time >= trim[1] & df$Time <= trim[2],]
	}

	if (time_unit == 'seconds')
		df$Time <- df$Time/60

	if (abs_unit == 'OD')
		df$Abs <- df$Abs * 1000

	data_list <- split(df, df$Well)


	lm_list <- lapply(data_list, function(x) {
		lm(Abs ~ Time, data = x)
	})

	recipient <- lapply(lm_list, function(x) {
		data.frame(Slope = coef(x)[2], R2 = summary(x)$adj.r.squared)
	})

	output <- do.call(rbind, recipient)

	output$Well <- rownames(output)
	rownames(output) <- 1:nrow(output)

	return(output[,c('Well', 'Slope', 'R2')])
}


#' Shortcut to plot wells 6 at a time
#' 
#' @param x the dataframe inported using load_kinetic()
#' 
#' @return a 4 by 4 plot
#' 
plot_plate <- function(x) {
	library('patchwork') 
	# it is not correct to load a library within a function, but I couldn't
	# find another way to make it work in the 30 seconds I spent searching.

	plot_kinetic(x, wells = paste0('A', 1:6)) +
	plot_kinetic(x, wells = paste0('A', 7:12)) +
	plot_kinetic(x, wells = paste0('B', 1:6)) +
	plot_kinetic(x, wells = paste0('B', 7:12)) +
	plot_kinetic(x, wells = paste0('C', 1:6)) +
	plot_kinetic(x, wells = paste0('C', 7:12)) +
	plot_kinetic(x, wells = paste0('D', 1:6)) +
	plot_kinetic(x, wells = paste0('D', 7:12)) +
	plot_kinetic(x, wells = paste0('E', 1:6)) +
	plot_kinetic(x, wells = paste0('E', 7:12)) +
	plot_kinetic(x, wells = paste0('F', 1:6)) +
	plot_kinetic(x, wells = paste0('F', 7:12)) +
	plot_kinetic(x, wells = paste0('G', 1:6)) +
	plot_kinetic(x, wells = paste0('G', 7:12)) +
	plot_kinetic(x, wells = paste0('H', 1:6)) +
	plot_kinetic(x, wells = paste0('H', 7:12)) +
	plot_layout(nrow = 4)
}


#' combine sample-data and slope-data based on wells
#' 
#' @param samples A dataframe containing sample information (sample name and treatment)
#' @param wells A dataframe containing the calculated slopes
#' 
#' @return a dataframe with both the sample and well data.
#' 
bind_samples_to_wells <- function(samples, wells) {
	link <- match(samples$Well, wells$Well)
	output <- cbind(samples, wells[link, !(colnames(wells) %in% 'Well')])
	return(output)
}


read_plate <- function(file) {
	x <- read.csv(file, row.names = 1)
	x$Row <- rownames(x)
	x <- reshape2::melt(x, id.vars = "Row")
	x$Col <- as.numeric(sub("X", "", x$variable))
	x <- x[order(x$Row, x$Col), ]
	x$Well <- paste0(x$Row, x$Col)
	rownames(x) <- 1:nrow(x)
	x <- x[!is.na(x$value), ]
	return(x[, c("Well", "value")])
}
