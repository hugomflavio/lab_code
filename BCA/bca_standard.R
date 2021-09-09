#' Calculate bca standard models, show the R2 and the plot
#' 
#' This function also exports the slope of the BCA model.
#' 
#' @param x A dataframe containing the protein concentrations and respective 
#' recorded Abs. Must contain two columns: 'Protein' and 'Abs'.
#' 
#' @param plot logical: Should a simple plot of the models be printed?
#' 
#' @return the protein slope
#' 
bca_standard <- function(x, protein_unit = c('ug/ml', 'ug/ul'), plot = TRUE) {
      if (!is.data.frame(x))
            stop('input must be a data frame')

      if (any(!(c('Protein', 'Abs') %in% colnames(x))))
            stop("The input must contain an 'Protein' and an 'Abs' column.")

      protein_unit = match.arg(protein_unit)

      if (protein_unit == 'ug/ml')
            x$Protein <- x$Protein / 1000

      mean_points <- aggregate(x$Abs, list(x$Protein), mean)
      colnames(mean_points) <- c('Protein', 'Abs')

      # We are calculating two models. One using all the points, and
      # another using the means for each standard value.
      m_all <- lm(Protein ~ Abs, data = x)
      m_mean <- lm(Protein ~ Abs, data = mean_points)

      message(paste(' Mean model R2:', round(summary(m_mean)$r.squared, 4)))
      message(paste('Point model R2:', round(summary(m_all)$r.squared, 4)))
      message(paste('Model equation: y =', round(coef(m_mean)[2], 4), 
            '* Abs', ifelse(coef(m_mean)[1] < 0, '-', '+'),
            round(abs(coef(m_mean)[1]), 4)))
      message('Y unit: ug protein/ul\nX unit: OD')

      if (plot) {
            x$pred <- predict(m_all, x)
            mean_points$pred <- predict(m_mean, mean_points)

            plot(Protein ~ Abs, data = x, ylab = 'Protein (ug/ul)', xlab = 'Absorbance (OD)')
            points(Protein ~ Abs, data = mean_points, col = 'red', pch = 16)
            lines(pred ~ Abs, data = mean_points, col = 'red')
      }

      output <- m_mean
      return(output)
}
