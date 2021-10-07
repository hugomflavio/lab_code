# -------------------------------------------------------
# R-script to calculate the protein activity from slopes
# -------------------------------------------------------

# Start by storing the sample slopes and R2 
# values in a csv containing three columns: 
# 'Sample', 'Treatment', 'Slope' and 'R2'
#
# Sample: The name of the sample
# Treatment: Either 'Control' or 'Ouabain'
# Slope: The recorded slope
# R2: The R2 of the slope (this one is optional)
#
# Name the file 'sample_data.csv'
# then run:

# load the data
samples <- read.csv('sample_data.csv')

# calculate the treatment means
sample_means <- nka_means(samples)

# calculate Control - Ouabain
NKA_slopes <- nka_slopes(sample_means)

# Convert OD slope to ADP slope
# Note: The 'adp_slope' was created in the adp standard script.
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
