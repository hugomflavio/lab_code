#' Calculate NKA means
#' 
#' @param x A data frame containing three columns: 'Sample', 'Treatment' and 'Slope'.
#' 			The group column should contein either 'Control' or
#' 
#' @return A data frame containing the mean activity slope for each sample*group combination.
#' 
calc_nka_means <- function(x) {
    if (!is.data.frame(x))
        stop('input must be a data frame')

	if (any(!(c('Sample', 'Treatment', 'Slope') %in% colnames(x))))
        stop("The input must contain the following three columns: 'Sample', 'Treatment' and 'Slope'.")

	# split the data by sample
	sample_list <- split(x, x$Sample)

	# calculate the mean values of the replicates
	sample_means <- lapply(names(sample_list), function(i) {
		x <- sample_list[[i]]
		output <- aggregate(x$Slope, list(x$Treatment), function(x) mean(x, na.rm = TRUE))
		colnames(output) <- c('Treatment', 'Mean.Slope')
		output$Sample <- i
		output$SD <- aggregate(x$Slope, list(x$Treatment), function(x) sd(x, na.rm = TRUE))$x
		return(output[,c('Sample', 'Treatment', 'Mean.Slope', 'SD')])
	})

	output <- do.call(rbind, sample_means)

	if (any(output$SD < 0.5))
		warning('Some samples have high standard deviation. You may want to double-check the input data.', call. = FALSE, immediate. = TRUE)

	return(output)
}

#' Calculate the NKA slope by subtrating the Ouabain to the Control
#' 
#' @param x a dataframe with the mean activity slope
#' 
#' @return a data frame with the NKA slopes for each sample.
#' 
calc_nka_slopes <- function(x) {
    if (!is.data.frame(x))
        stop('input must be a data frame')

	if (any(!(c('Sample', 'Treatment', 'Mean.Slope') %in% colnames(x))))
        stop("The input must contain the following three columns: 'Sample', 'Treatment' and 'Mean.Slope'.")

	# split the data by sample
	mean_list <- split(x, x$Sample)

	if (any(sapply(mean_list, nrow) != 2))
		stop('Eeach sample should only have one value per treatement. Please run nka_means() first.')

	NKA_slope <- lapply(mean_list, function(x) {
		output <- data.frame(Sample = x$Sample[1],
							 Slope = x$Mean.Slope[x$Treatment == 'Control'] - x$Mean.Slope[x$Treatment == 'Ouabain'])
		return(output)
	})

	output <- do.call(rbind, NKA_slope)

	return(output)
}

#' convert OD slopes to ADP slopes
#' 
#' @param nka_slope the dataframe with the NKA slopes for each sample
#' @param nka_unit The unit of the NKA slopes
#' @param adp_slope The calculated adp slope from the adp standards
#' @param adp_unit The unit of the ADP slope
#' 
#' @return A table with the NKA slopes but in adp/min rather than OD(mOD)/min
#' 
calc_OD_to_adp <- function(nka_slope, nka_unit = c('OD/min', 'mOD/min'), adp_slope, adp_unit = c('OD/nmol', 'mOD/nmol')) {
    if (!is.data.frame(nka_slope))
        stop('nka_slope must be a data frame')

	if (any(!(c('Sample', 'Slope') %in% colnames(x))))
        stop("nka_slope must contain the following two columns: 'Sample', 'Slope'.")

    if (length(adp_slope) > 1)
        stop('adp_slope must be an individual value')


    nka_unit <- match.arg(nka_unit)
    adp_unit <- match.arg(adp_unit)

    if (nka_unit == 'OD/min')
    	nka_slope$Slope <- nka_slope$Slope * 1000

    if (adp_unit == 'OD/nmol')
    	adp_slope <- adp_slope * 1000

    nka_slope$nmolADP_min <- nka_slope$Slope / abs(adp_slope)

    return(nka_slope)
}
