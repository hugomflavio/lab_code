#' Calculate a generic standard curve, show the R2 and the plot
#' 
#' This function also exports the intercept and slope of the model.
#' 
#' @param data The input dataframe
#' @param x The concentration column name
#' @param abs The absorbance column name
#' @param plot logical: Should a simple plot of the models be printed? Defaults to TRUE
#' 
#' @return the model slope and intercept
#' 
std_curve <- function(data, x, abs, plot = TRUE) {
      if (!is.data.frame(data))
            stop('"data" must be a data frame')

      data <- data[c(abs, x)]
      colnames(data) <- c("abs", "x")

      mean_points <- aggregate(data$abs, list(data$x), mean)
      colnames(mean_points) <- c('x', 'abs')

      # We are calculating two models. One using all the points, and
      # another using the means for each standard value.
      m_all <- lm(abs ~ x, data = data)
      m_mean <- lm(abs ~ x, data = mean_points)

      message(paste(' Mean model R2:', round(summary(m_mean)$r.squared, 4)))
      message(paste('Point model R2:', round(summary(m_all)$r.squared, 4)))
      message(paste('Model equation: abs =', round(coef(m_mean)[2], 4), 
            '* x', ifelse(coef(m_mean)[1] < 0, '-', '+'),
            round(abs(coef(m_mean)[1]), 4)))
      message(paste0('                x = (abs ',
            ifelse(coef(m_mean)[1] < 0, '+ ', '- '),
            round(abs(coef(m_mean)[1]), 4),
            ") / ", round(coef(m_mean)[2], 4))
      )

      if (plot) {
            data$pred <- predict(m_all, data)
            mean_points$pred <- predict(m_mean, mean_points)

            plot(abs ~ x, data = data)
            points(abs ~ x, data = mean_points, col = 'red', pch = 16)
            lines(pred ~ x, data = data, col = 'red')
      }

      return(coef(m_mean))
}


#' Predict concentration of substance x from the recorded absorbances, 
#' using the coefficients of a model abs ~ x.
#' 
#' @param abs The input absorbances
#' @param coefs A vector of size two containing the intercept and slope of the standard model.
#' 
#' @return the predicted concentrations
#' 
abs_predict <- function(abs, coefs, add_to_plot = FALSE, col = "red") {
      con <- (abs - coefs[1]) / coefs[2]

      if (add_to_plot){
            for (i in 1:length(con)) {
                  lines(x = c(0, con[i], con[i]), y = c(abs[i], abs[i], 0), lty = "dashed", col = col)
                  points(x = con[i], y = abs[i], col = col, pch = 16)
            }
      }

      return(con)
}
