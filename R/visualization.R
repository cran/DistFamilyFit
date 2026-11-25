.ff_graphic_call <- function(fun, defaults, extra) {
  if (length(extra)) {
    if (is.null(names(extra)) || anyNA(names(extra)) || any(!nzchar(names(extra))) || anyDuplicated(names(extra))) stop('Additional graphics arguments must have distinct names.')
    if (any(names(extra) %in% c('x', 'y'))) stop('Evaluation data cannot be overridden through graphics arguments.')
    for (nm in names(extra)) defaults[nm] <- extra[nm]
  }
  do.call(fun, defaults)
}
#' Plot one fitted distribution
#' @param object Univariate fit.
#' @param type cdf, qq or density.
#' @param model Candidate to plot, including an explicitly chosen warned model.
#' @param ... Additional arguments to the base plotting function.
#' @return Invisibly the input object; draws a plot only when called.
#' @export
plot_fit <- function(object, type = c('cdf', 'qq', 'density'), model = object$best, ...) {
  type <- match.arg(type); .ff_select(object, model)
  x <- object; dots <- list(...)
  if (type == 'cdf') {
    .ff_graphic_call(graphics::plot, list(x = stats::ecdf(x$data), main = paste('CDF:', model), xlab = 'x', ylab = 'F(x)'), dots)
    grid <- seq(min(x$data), max(x$data), length.out = 400)
    graphics::lines(grid, cdf_fit(x, grid, model), col = 2, lwd = 2)
  } else if (type == 'qq') {
    p <- stats::ppoints(length(x$data))
    .ff_graphic_call(graphics::plot, list(x = quantile_fit(x, p, model), y = x$data, main = paste('Q-Q:', model), xlab = 'Model quantiles', ylab = 'Observed quantiles'), dots)
    graphics::abline(0, 1, col = 2)
  } else {
    if ((!is.null(dots$probability) && !isTRUE(dots$probability)) || (!is.null(dots$freq) && !identical(dots$freq, FALSE))) stop('Density overlays require probability = TRUE and freq = FALSE.')
    .ff_graphic_call(graphics::hist, list(x = x$data, probability = TRUE, main = paste('Density:', model), xlab = 'x'), dots)
    grid <- seq(min(x$data), max(x$data), length.out = 400)
    graphics::lines(grid, density_fit(x, grid, model), col = 2, lwd = 2)
  }
  invisible(object)
}
#' Compare fitted candidate CDFs
#' @param object Univariate fit.
#' @param models Candidates to display; all numerically usable candidates by default.
#' @param ... Arguments to the empirical CDF plot.
#' @return Invisibly the input object.
#' @export
plot_comparison <- function(object, models = NULL, ...) {
  if (!inherits(object, 'familyfit_univariate')) stop('Expected a univariate fit.')
  if (is.null(models)) models <- object$ranking$model[object$ranking$status %in% c('OK', 'Warning')]
  if (!length(models) || anyNA(models) || any(!models %in% names(object$models))) stop('Select existing fitted models.')
  .ff_graphic_call(graphics::plot, list(x = stats::ecdf(object$data), main = 'Distribution family comparison', xlab = 'x', ylab = 'F(x)'), list(...))
  grid <- seq(min(object$data), max(object$data), length.out = 400)
  for (j in seq_along(models)) graphics::lines(grid, cdf_fit(object, grid, models[j]), col = j + 1, lwd = 2)
  graphics::legend('bottomright', legend = c('Empirical', models), col = seq_len(length(models) + 1), lty = 1, lwd = 2, cex = .8)
  invisible(object)
}
#' Plot dependence in Johnson normal space
#' @param object Multivariate fit.
#' @param type Correlation or covariance matrix.
#' @return Invisibly the plotted matrix.
#' @export
plot_dependence <- function(object, type = c('correlation', 'covariance')) {
  if (!inherits(object, 'familyfit_multivariate')) stop('Expected a multivariate fit.')
  type <- match.arg(type)
  M <- if (type == 'correlation') object$correlation_Z else object$covariance_Z
  old <- graphics::par(mar = pmax(graphics::par('mar'), c(max(5, min(15, max(nchar(colnames(M))) * .5 + 1)), max(5, min(15, max(nchar(rownames(M))) * .5 + 1)), 4, 2)))
  on.exit(graphics::par(old), add = TRUE)
  n <- nrow(M); limit <- max(abs(M))
  graphics::image(seq_len(n), seq_len(n), M, zlim = c(-limit, limit),
    col = grDevices::colorRampPalette(c('#2463A0', 'white', '#BD3B32'))(101),
    axes = FALSE, xlab = '', ylab = '', main = paste('Z-space', type))
  graphics::axis(1, at = seq_len(n), labels = colnames(M), las = 2, cex.axis = .7)
  graphics::axis(2, at = seq_len(n), labels = rownames(M), las = 2, cex.axis = .7)
  for (i in seq_len(n)) for (j in seq_len(n)) graphics::text(i, j, format(round(M[i,j], 3), nsmall = 3), cex = .8)
  invisible(M)
}
#' Plot Johnson transformed observations or a joint normal diagnostic
#' @param object Multivariate fit.
#' @param type pairs or mahalanobis.
#' @param ... Arguments to the base plotting function.
#' @return Invisibly the input object.
#' @export
plot_transformed <- function(object, type = c('pairs', 'mahalanobis'), ...) {
  if (!inherits(object, 'familyfit_multivariate')) stop('Expected a multivariate fit.')
  type <- match.arg(type)
  if (type == 'pairs') .ff_graphic_call(graphics::pairs, list(x = object$Z, main = 'Johnson normal-scale variables'), list(...)) else {
    distances <- object$mahalanobis_squared
    if (any(!is.finite(distances))) stop('Joint diagnostic unavailable for singular covariance.')
    theoretical <- stats::qchisq(stats::ppoints(length(distances)), df = ncol(object$Z))
    .ff_graphic_call(graphics::plot, list(x = theoretical, y = sort(distances), xlab = 'Chi-square reference quantiles', ylab = 'Squared Mahalanobis distances', main = 'Joint normal diagnostic (descriptive)'), list(...))
    graphics::abline(0, 1, col = 2)
  }
  invisible(object)
}
