.ff_select <- function(object, model) {
  if (!inherits(object, 'familyfit_univariate')) stop('Expected a univariate fit.')
  if (length(model) != 1L || is.na(model) || !model %in% names(object$models)) stop('No valid requested model.')
  object$models[[model]]
}
#' Evaluate a fitted distribution
#' @param object A univariate fit.
#' @param x Numeric evaluation points.
#' @param model Model name; defaults to the selected model.
#' @return Numeric CDF values.
#' @export
cdf_fit <- function(object, x, model = object$best) {
  if (!.ff_numeric_vector(x)) stop('x must be numeric.')
  f <- .ff_select(object, model)
  .ff_p((x - f$origin) / f$scale, f$model, f$theta)
}
#' @rdname cdf_fit
#' @param log Return log density when TRUE.
#' @export
density_fit <- function(object, x, model = object$best, log = FALSE) {
  if (!.ff_numeric_vector(x)) stop('x must be numeric.')
  if (!is.logical(log) || length(log) != 1L || is.na(log)) stop('log must be TRUE or FALSE.')
  f <- .ff_select(object, model)
  out <- .ff_logd((x - f$origin) / f$scale, f$model, f$theta) - base::log(f$scale)
  if (log) out else exp(out)
}
#' Quantiles from a fitted distribution
#' @param object A univariate fit.
#' @param p Probabilities between zero and one.
#' @param model Model name.
#' @return Numeric quantiles in the original data units.
#' @export
quantile_fit <- function(object, p, model = object$best) {
  if (!.ff_numeric_vector(p) || any(!is.finite(p)) || any(p < 0 | p > 1)) stop('p must contain probabilities in [0, 1].')
  f <- .ff_select(object, model)
  f$origin + f$scale * .ff_q(p, f$model, f$theta)
}
#' @export
print.familyfit_univariate <- function(x, ...) {
  cat('Continuous univariate distribution fit\nSelected:', x$best, '\n')
  cat('Computation status:', x$status, '\n')
  cat('Retained / input:', x$audit$n_retained, '/', x$audit$n_input, '\n')
  print(x$ranking[, c('model', 'KS', 'MatchRate', 'AIC', 'status')], row.names = FALSE)
  invisible(x)
}
#' @export
summary.familyfit_univariate <- function(object, ...) {
  list(best = object$best, status = object$status, ranking = object$ranking, audit = object$audit, input_audit = object$input_audit,
       selection = object$selection,
       parameters = object$models)
}
#' @export
plot.familyfit_univariate <- function(x, type = c('cdf', 'qq', 'density'), model = x$best, ...) {
  plot_fit(x, type = match.arg(type), model = model, ...)
}
