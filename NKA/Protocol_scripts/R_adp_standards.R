# ------------------------------------------
# R-script to calculate the standard curve
# ------------------------------------------

# start by storing the absorbance values in a csv 
# containing two columns: 'ADP' and 'Abs'
# Name the file 'adp_standards.csv' then run:

source('https://git.io/JRSJs')
# This line downloads the function adp_standard, which we will use below.

adp_points <- read.csv('adp_standards.csv')
adp_slope <- adp_standard(adp_points)

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
# Save the plot, the R2 of both models, and model equation.
