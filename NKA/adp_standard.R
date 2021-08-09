#' Calculate adp standard models, show the R2 and the plot
#' 
#' This function also exports the slope of the ADP model.
#' 
#' @param x A dataframe containing the ADP concentrations and respective 
#' recorded Abs. Must contain two columns: 'ADP' and 'Abs'.
#' 
#' @param plot logical: Should a simple plot of the models be printed?
#' 
#' @return the adp slope
#' 
adp_standard <- function(x, plot = TRUE) {
      if (!is.data.frame(x))
            stop('input must be a data frame')

      if (any(!(c('ADP', 'Abs') %in% colnames(x))))
            stop("The input must contain an 'ADP' and an 'Abs' column.")

      mean_points <- aggregate(x$Abs, list(x$ADP), mean)
      colnames(mean_points) <- c('ADP', 'Abs')

      # We are calculating two models. One using all the points, and
      # another using the means for each standard value.
      m_all <- lm(Abs ~ ADP, data = x)
      m_mean <- lm(Abs ~ ADP, data = mean_points)

      message(paste(' Mean model R2:', round(summary(m_mean)$r.squared, 4)))
      message(paste('Point model R2:', round(summary(m_all)$r.squared, 4)))
      message(paste('Model equation: y =', round(coef(m_mean)[2], 4), 
            '* ADP', ifelse(coef(m_mean)[1] < 0, '-', '+'),
            round(abs(coef(m_mean)[1]), 4)))

      if (plot) {
            x$pred <- predict(m_all, x)
            mean_points$pred <- predict(m_mean, mean_points)

            plot(Abs ~ ADP, data = x)
            points(Abs ~ ADP, data = mean_points, col = 'red', pch = 16)
            lines(pred ~ ADP, data = x, col = 'red')
      }

      output <- coef(m_mean)[2]
      names(output) <- 'ADP.slope'
      return(output)
}
