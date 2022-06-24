# ---------------------------------------------
# R-script to calculate the BCA standard curve
# ---------------------------------------------

# Start by storing the absorbance values in a csv 
# containing two columns: 'Protein' and 'Abs'
# Name the file 'bca_standards.csv' then run:

source('https://git.io/JuEVq')
# This line downloads the function bca_standard, which we will use below.

bca_std <- read.csv('bca_standards.csv', header = TRUE)
bca_std <- bca_std[bca_std$Protein < 1000, ] # this line removes the two largest concentrations of protein.
bca_model <- bca_standard(bca_std, protein_unit = 'ug/ml')

# What just happened?
#
# We are calculating two models. One using all the points, and another using 
# the means for each standard value. The R2 of the mean model gives us an idea 
# of how good our standard curve is. We want it above 0.95.
#
# On the other hand, the R2 of the point model tells us if there is a lot of 
# dispersion between replicates. If the R2 of the m_all model is low, (i.e. 
# under 0.9), then you may need to practice consistent pipetting a bit more.
#
# The equation for both models is the same.
#
# Save the plot, the R2 of both models, and the model equation.



# -------------------------------------------------
# R-script to calculate the protein concentrations
# -------------------------------------------------

# Start by storing the absorbance values in a csv 
# containing two columns: 'Sample' and 'Abs'
# Name the file 'bca_samples.csv' then run:

source('https://git.io/JuEVk')
# This line downloads the function bca analysis functions.

samples <- read.csv('bca_samples.csv', header = TRUE)
sample_means <- calc_bca_means(samples)

sample_protein <- calc_sample_protein(sample = sample_means,
									  sample_unit = 'OD',
									  bca_model = bca_model,
									  bca_unit = 'OD/ug/ul',
									  dilution_factor = 15)

write.csv(sample_protein, 'sample_protein_concentrations.csv')
