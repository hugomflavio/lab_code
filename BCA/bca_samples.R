#' Calculate the mean of BCA replicates
#' 
#' @param x a dataframe with a 'Sample' and an 'Abs' column
#' 
#' @return a dataframe with the replicate means.
#' 
calc_bca_means <- function(x) {
    if (!is.data.frame(x))
        stop('input must be a data frame')

	if (any(!(c('Sample', 'Abs') %in% colnames(x))))
        stop("The input must contain the following two columns: 'Sample' and 'Abs'.")

	sample_means <- aggregate(x$Abs, list(x$Sample), function(x) mean(x, na.rm = TRUE))
	colnames(sample_means) <- c('Sample', 'Mean.Abs')
	sample_means <- data.frame(sample_means, SD = unname(aggregate(x$Abs, list(x$Sample), function(x) sd(x, na.rm = TRUE))['x']))
	sample_means <- sample_means[,c('Sample', 'Mean.Abs', 'SD')]

	if (any(sample_means$SD > 1.5))
		warning('Some samples have high standard deviation (sd > 1.5). You may want to double-check the input data.', call. = FALSE, immediate. = TRUE)

	return(sample_means)
}

#' Convert OD to ug protein
#' 
#' @param samples a dataframe obtained from calc_bca_means()
#' @param sample_unit The unit of the samples' absorbance
#' @param bca_slope The calculated protein slope from the bca standards
#' @param bca_unit The unit of the protein slope
#' 
#' @return A table with the protein concentrations for each sample.
#' 
calc_sample_protein <- function(samples, sample_unit = c('OD', 'mOD'), bca_model, bca_unit = c('OD/ug/ul', 'mOD/ug/ul'), dilution_factor = 10) {

    if (!is.data.frame(samples))
        stop('samples must be a data frame')

    if (any(!(c('Sample', 'Mean.Abs') %in% colnames(samples))))
        stop("samples must contain the following two columns: 'Sample', 'Mean.Abs'.")

    if (!inherits(bca_model, 'lm'))
        stop('bca_model must be a linear model object.')

    if (length(dilution_factor) != 1 & length(dilution_factor) != nrow(samples))
        stop('dilution_factor must be of length 1 or length == nrow(samples).')

    sample_unit <- match.arg(sample_unit)
    bca_unit <- match.arg(bca_unit)

    if (sample_unit == 'mOD' & bca_unit == 'OD/ug/ul')
        samples$Mean.Abs <- samples$Mean.Abs / 1000

    colnames(samples)[colnames(samples) == 'Mean.Abs'] <- 'Abs'

    samples$Protein_ug_ul <- predict(bca_model, samples)

    colnames(samples)[colnames(samples) == 'Abs'] <- 'Mean.Abs'

    samples$Protein_ug_ul <- samples$Protein_ug_ul * dilution_factor

    if (sample_unit == 'OD' & bca_unit == 'mOD/ug/ul')
        samples$Protein_ug_ul <- samples$Protein_ug_ul * 1000

    return(samples)
}






# include_protein <- function(x, bca)

