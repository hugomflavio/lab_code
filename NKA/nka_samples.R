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
		output <- aggregate(x$Slope, list(x$Treatment), function(i) mean(i, na.rm = TRUE))
		colnames(output) <- c('Treatment', 'Mean.Slope')
		output$Sample <- i
		output$SD <- aggregate(x$Slope, list(x$Treatment), function(i) sd(i, na.rm = TRUE))$x
		output$n <- aggregate(x$Slope, list(x$Treatment), function(i) sum(!is.na(i)))$x
		return(output[,c('Sample', 'Treatment', 'Mean.Slope', 'SD', 'n')])
	})

	output <- do.call(rbind, sample_means)

	if (any(output$SD > 1.5))
		warning('Some samples have high standard deviation (sd > 1.5). You may want to double-check the input data.', call. = FALSE, immediate. = TRUE)

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
							 Control_slope = x$Mean.Slope[x$Treatment == 'Control'],
							 Ouabain_slope = x$Mean.Slope[x$Treatment == 'Ouabain'],
							 NKA_slope = x$Mean.Slope[x$Treatment == 'Control'] - x$Mean.Slope[x$Treatment == 'Ouabain'])
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
OD_to_ADP <- function(nka_slopes, nka_unit = c('OD/min', 'mOD/min'), adp_slope, adp_unit = c('OD/nmol', 'mOD/nmol')) {
    if (!is.data.frame(nka_slopes))
        stop('nka_slope must be a data frame')

	if (any(!(c('Sample', 'Control_slope', 'Ouabain_slope', 'NKA_slope') %in% colnames(nka_slopes))))
        stop("nka_slope must contain the following columns: 'Sample', 'Control_slope', 'Ouabain_slope', 'NKA_slope'.")

    if (length(adp_slope) > 1)
        stop('adp_slope must be an individual value')


    nka_unit <- match.arg(nka_unit)
    adp_unit <- match.arg(adp_unit)

    if (nka_unit == 'OD/min') {
    	nka_slopes$Control_slope <- nka_slopes$Control_slope * 1000
    	nka_slopes$Ouabain_slope <- nka_slopes$Ouabain_slope * 1000
    	nka_slopes$NKA_slope <- nka_slopes$NKA_slope * 1000
    }

    if (adp_unit == 'OD/nmol')
    	adp_slope <- adp_slope * 1000

    nka_slopes$Control_nmolADP_min <- nka_slopes$Control_slope / adp_slope
    nka_slopes$Ouabain_nmolADP_min <- nka_slopes$Ouabain_slope / adp_slope
    nka_slopes$NKA_nmolADP_min <- nka_slopes$NKA_slope / adp_slope

    return(nka_slopes)
}




include_wet_weight <- function(input, sample_weights){
	if (is.character(sample_weights))
		sample_weights <- read.csv(sample_weights, header = TRUE)

	if (any(!(c('Sample', 'Weight') %in% colnames(sample_weights))))
        stop("sample_weights must contain the following columns: 'Sample', 'Weight'.")

	# Find which rows in sample_weights contain the data for your target samples
	weight_link <- match(input$Sample, sample_weights$Sample)

	weight_link

	# transfer the weights
	input$Weight_g <- sample_weights$Weight[weight_link]
	input$Experiment <- sample_weights$Experiment[weight_link]

	# divide the nmolADP_min column by the sample weight to obtain nmol_ADP/g_sample/min
	input$Control_nmolADP_gWT_min <- input$Control_nmolADP_min / input$Weight_g
	input$Ouabain_nmolADP_gWT_min <- input$Ouabain_nmolADP_min / input$Weight_g
	input$NKA_nmolADP_gWT_min <- input$NKA_nmolADP_min / input$Weight_g

	# Now multiply that column by 60 to go from minutes to hours.
	input$Control_nmolADP_gWT_hour <- input$Control_nmolADP_gWT_min * 60
	input$Ouabain_nmolADP_gWT_hour <- input$Ouabain_nmolADP_gWT_min * 60
	input$NKA_nmolADP_gWT_hour <- input$NKA_nmolADP_gWT_min * 60

	# explore the results by opening the data.frame:
	return(input)
}


include_protein <- function(input, sample_protein){
	if (is.character(sample_protein))
		sample_protein <- read.csv(sample_protein, header = TRUE)

	if (any(!(c('Sample', 'Protein_ug_ul') %in% colnames(sample_protein))))
        stop("sample_protein must contain the following columns: 'Sample', 'Protein_ug_ul'.")

	# Find which rows in sample_protein contain the data for your target samples
	protein_link <- match(input$Sample, sample_protein$Sample)

	# transfer the protein concentrations
	input$Protein_ug_ul <- sample_protein$Protein_ug_ul[protein_link]

	# usually the wells receive 10 ul of sample, so you need to multiply this value by 10
	input$Protein_ug <- input$Protein_ug_ul * 10

	# divide the nmolADP_min column by the sample protein to obtain nmol_ADP/ug_protein/min
	input$Control_nmolADP_ugP_min <- input$Control_nmolADP_min / input$Protein_ug
	input$Ouabain_nmolADP_ugP_min <- input$Ouabain_nmolADP_min / input$Protein_ug
	input$NKA_nmolADP_ugP_min <- input$NKA_nmolADP_min / input$Protein_ug

	# Now multiply that column by 60 to go from minutes to hours.
	input$Control_nmolADP_ugP_hour <- input$Control_nmolADP_ugP_min * 60
	input$Ouabain_nmolADP_ugP_hour <- input$Ouabain_nmolADP_ugP_min * 60
	input$NKA_nmolADP_ugP_hour <- input$NKA_nmolADP_ugP_min * 60

	# explore the results by opening the data.frame:
	return(input)
}
