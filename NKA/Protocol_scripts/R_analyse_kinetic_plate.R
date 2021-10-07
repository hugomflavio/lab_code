# ---------------------------------------------------------------
# R-script to calculate the protein activity from raw absorbance
# ---------------------------------------------------------------

# NOTE: This script is meant to work specifically with the kinetic output of the
#       spec in room N3024.

# Note: You need to have packages reshape2, ggplot2 and patchwork installed to run 
# this script. You can install them with:
# install.packages(c('reshape2', 'ggplot2', 'patchwork'))

# Then load the kinetic functions
source('https://git.io/JEn0P')

# Load the txt file with the kinetic data for the plate. Change the name accordingly
x <- load_kinetic('nka_samples.txt')

# Automatically plot the plate, 6 wells at a time:
plot_plate(x)

# If you are using Rstudio, there is a button to have the plot appear 
# in a pop-up window. This window can stay opened throughout your session.

# Alternatively, you can plot specific wells one plot at a time using plot_kinetic(). e.g.:
# plot_kinetic(x, wells = c('A1', 'B1'))

# Based on the plots above, decide if you need to trim some data
# or not, using the trim argument below (replace 0 and Inf with the desired
# start and stop seconds).
plate_slopes_list <- list(
	calc_kinetic_slopes(x, wells = paste0('A',  1:6), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('A', 7:12), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('B',  1:6), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('B', 7:12), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('C',  1:6), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('C', 7:12), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('D',  1:6), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('D', 7:12), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('E',  1:6), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('E', 7:12), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('F',  1:6), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('F', 7:12), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('G',  1:6), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('G', 7:12), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('H',  1:6), trim = c(0, Inf)),
	calc_kinetic_slopes(x, wells = paste0('H', 7:12))
	)
# NOTE: The function  cal_kinetic_slopes assumes the absorbance is in OD and the 
# time is in seconds. If this is not the case for you, you need to use the 
# arguments time_unit (possible values: 'seconds', 'minutes'), and abs_unit 
# (possible values: 'OD', 'mOD') to specify the units. calc_kinetic_slopes 
# will then automatically convert the results to mOD/min.

# This line just finishes formatting the input above
plate_slopes <- do.call(rbind, plate_slopes_list)

# Now prepare the well-plate correspondence. 
# - In the table below, the first column ('Well') contains the wells ordered 
#   by row (i.e. A1, A2, ... H11, H12). 
# - The 'Sample' column has been pre-organized to repeat each sample name 
#   six times (i.e. A01 goes from well A1 to A6). If some wells were left empty, 
#   just give them a random sample name, and it will be discarded.
# - The 'Group' column has been pre-organized to repeat 'Control' and 'Ouabain'
#   three times each, throughout the length of the column.
#
# Change this table as needed to fit the samples analysed in the plate.
#
plate_samples <- data.frame(Well = paste0(rep(LETTERS[1:8], each = 12), 1:12),
						    Sample = c(
									rep('A01', 6),
									rep('A02', 6),
									rep('A03', 6),
									rep('A04', 6),
									rep('A05', 6),
									rep('A06', 6),
									rep('A07', 6),
									rep('A08', 6),
									rep('A09', 6),
									rep('A10', 6),
									rep('A11', 6),
									rep('A12', 6),
									rep('A13', 6),
									rep('A14', 6),
									rep('A15', 6),
									rep('A16', 6)),
						    Treatment = rep(rep(c('Control', 'Ouabain'), each = 3), 16))

# This will combine the information on the slopes and sample names.
df <- bind_samples_to_wells(plate_samples, plate_slopes)

# At this point, you can export the results and move to excel, if you want to.
# Use this line to export (change the file name to avoid overwritting):
# write.csv(df, 'my_plate.csv', row.names = FALSE)


# -----


# If you want to continue in R, load the nka analysis functions and keep going
source('https://git.io/JEnEn')

# calculate the sample*treatment means using clac_nka_means()
mean_slopes <- calc_nka_means(df)

# If you get a warning for high SD, open the mean_slopes and see which samples have a high SD.
mean_slopes

# Then, open the df and check the individual values for those samples
df

# If you want to discard some rows, remove them using the subsetting command. E.g.
# df <- df[c(1, 3), ] # Where 1 and 3 are the rows you want to remove.
# If you remove rows, go back to the calc_nka_means() line and remake mean_slopes.

# Once you are happy with the content of mean_slopes, run the function below to
# calculate the NKA slope (i.e. Control - Ouabain).
nka_slopes <- calc_nka_slopes(mean_slopes)


# Now that we have the slopes in mOD/min, we want to convert them all the way to
# nmol_ADP/g_tissue/hour, or nmol_ADP/ug_protein/hour (which requires BCA results).

# First, going from OD to ADP. For this, you need the slope from your ADP standard,
# which you should have calculated when you ran the R_adp_standards.R Script.
# If you still have the adp_slope object, keep going. Otherwise, you can either run
# the adp_standard.R script again, or, if you have the slope written down somewhere,
# you can simply recreate the adp_slope object using e.g.:
# adp_slope <- -0.01613 (keep as many decimal points as possible)

# If you obtained the adp_slope from the scripts provided in this protocol, it will
# likely be in OD/nmol ADP. If it is, we can use the function below to convert it on-the-fly
# to mOD/nmol ADP by using the argument adp_unit (possible values: 'mOD/nmol', 'OD/nmol').
# If the slope is in a unit other than these two I mentioned, please convert it manually 
# to one of them before proceeding.

# The OD_to_ADP function assumes the nka slopes are provided in mOD/min. If this is not the case,
# you can specify another unit using the nka_unit argument (possible values: ('mOD/min', 'OD/min')).
# If your slopes are in another unit, please convert them manually before proceeding.

adp_slopes_df <- OD_to_ADP(nka_slopes = nka_slopes,
						   nka_unit = 'mOD/min',
						   adp_slope = adp_slope,
						   adp_unit = 'OD/nmol')

# Now, you can choose to either integrate the wet sample weight, or the protein concentration.
# Note: You can run both methods to obtain both units, which are sometimes provided side-by-side in papers.

# Let's use the wet weight method first. 

	# Create a csv that contains two columns:
	# - 'Sample': The name of the sample
	# - 'Weight': The weight of the sample, in grams.
	# 
	# Note: You can make one single table for all the samples; R will pick the ones that match your plate.
	#
	# change the name of the file in the line below as needed.
	sample_weights <- read.csv('sample_weights.csv', header = TRUE)

	# Find which rows in sample_weights contain the data for your target samples
	weight_link <- match(adp_slopes_df$Sample, sample_weights$Sample)

	# Confirm that R found the matches. If there are NAs in the object below,
	# something went wrong. Verify that the sample names are equal on both tables!
	weight_link

	# transfer the weights
	adp_slopes_df$Weight_g <- sample_weights$Weight[weight_link]
	adp_slopes_df$Experiment <- sample_weights$Experiment[weight_link]

	# divide the nmolADP_min column by the sample weight to obtain nmol_ADP/g_sample/min
	adp_slopes_df$nmolADP_gWT_min <- adp_slopes_df$nmolADP_min / adp_slopes_df$Weight_g

	# Now multiply that column by 60 to go from minutes to hours.
	adp_slopes_df$nmolADP_gWT_hour <- adp_slopes_df$nmolADP_gWT_min * 60

	# explore the results by opening the data.frame:
	adp_slopes_df

	# Again, you can stop here and export the data into excel, if you want to.
	# write.csv(adp_slopes_df, 'plate1_wetweight_results.csv', row.names = FALSE)


# Now with the protein concentration instead.

	# For this, you need to have run a BCA, and obtained the ug_protein concentrations
	# for each sample. You will need a table with two columns:
	# - 'Sample': The name of the sample
	# - 'Protein': The protein concentration, in ug.
	#
	# Note: You can make one single table for all the samples; R will pick the ones that match your plate.

	# If you ran the bca samples script provided for the BCA protocol, you should have an R object
	# with this information already. If you do, uncomment and edit the line below to rename the object
	# to sample_protein:
	# sample_protein <- previous_name_of_the_object.

	# Alternatively, if you have the table in a csv, uncomment and edit the line below 
	# to load the dataset into R:
	# sample_protein <- read.csv('sample_protein.csv', header = TRUE)

	# Find which rows in sample_protein contain the data for your target samples
	protein_link <- match(adp_slopes_df$Sample, sample_protein$Sample)

	# Confirm that R found the matches. If there are NAs in the object below,
	# something went wrong. Verify that the sample names are equal on both tables!
	weight_link

	# transfer the protein concentrations
	adp_slopes_df$Protein_ug <- sample_protein$Protein[protein_link]

	# divide the nmolADP_min column by the sample protein to obtain nmol_ADP/g_sample/min
	adp_slopes_df$nmolADP_ugP_min <- adp_slopes_df$nmolADP_min / adp_slopes_df$Protein_ug

	# Now multiply that column by 60 to go from minutes to hours.
	adp_slopes_df$nmolADP_ugP_hour <- adp_slopes_df$nmolADP_ugP_min * 60

	# explore the results by opening the data.frame:
	adp_slopes_df

	# Again, you can stop here and export the data into excel, if you want to.
	# write.csv(adp_slopes_df, 'plate1_protein_results.csv', row.names = FALSE)
