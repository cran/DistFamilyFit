# Profile the transformed-normal mean and variance analytically.
# Only location/support parameters require numerical optimization.
.ff_profile_johnson <- function(y, model, a, xmin, xmax) {
  span <- xmax - xmin
  if (model == 'JohnsonSU') {
    xi <- a[1]; lam <- exp(a[2]); v <- (y - xi) / lam
    h <- asinh(v); logjac <- -log(lam) - .ff_softplus(2 * log(abs(v))) / 2
  } else if (model == 'JohnsonSL') {
    xi <- xmin - span * exp(a[1]); lam <- 1
    h <- log(y - xi); logjac <- -log(y - xi)
  } else {
    xi <- xmin - span * exp(a[1]); upper <- xmax + span * exp(a[2]); lam <- upper - xi
    h <- log(y - xi) - log(upper - y)
    logjac <- log(lam) - log(y - xi) - log(upper - y)
  }
  s <- sqrt(mean((h - mean(h))^2))
  if (!is.finite(s) || s <= 1e-10 || any(!is.finite(logjac))) stop('Degenerate Johnson transformation.')
  delta <- 1 / s; gamma <- -mean(h) / s
  list(theta = c(gamma, log(delta), xi, log(lam)),
       nll = -sum(stats::dnorm((h - mean(h)) / s, log = TRUE) + log(delta) + logjac))
}
.ff_fit_johnson <- function(y, all_y, model, control) {
  xmin <- min(all_y); xmax <- max(all_y); span <- xmax - xmin
  limits <- c(-12, 12) # numerical search guards on standardized log scales
  if (model == 'JohnsonSU') {
    starts <- list(c(0, 0), c(stats::median(y), -1), c(xmin - .1 * span, -2), c(xmax + .1 * span, -2), c(0, 2))
    lower <- c(xmin - 100 * span, limits[1]); upper <- c(xmax + 100 * span, limits[2])
  } else if (model == 'JohnsonSL') {
    starts <- lapply(c(.001, .01, .1, .5, 1, 5), function(v) log(v))
    lower <- limits[1]; upper <- limits[2]
  } else {
    starts <- list(log(c(.01, .01)), log(c(.1, .1)), log(c(1, 1)), log(c(.01, 1)), log(c(1, .01)))
    lower <- rep(limits[1], 2); upper <- rep(limits[2], 2)
  }
  safe <- function(a) {
    ans <- tryCatch(.ff_profile_johnson(y, model, a, xmin, xmax)$nll, error = function(e) Inf)
    if (is.finite(ans)) ans else 1e100
  }
  controls <- utils::modifyList(list(maxit = 8000, factr = 1e7), .ff_optim_control(control, 'L-BFGS-B', length(lower)))
  fits <- lapply(starts, function(s) tryCatch(stats::optim(s, safe, method = 'L-BFGS-B', lower = lower, upper = upper, control = controls), error = function(e) NULL))
  good <- vapply(fits, function(f) !is.null(f) && f$convergence == 0 && is.finite(f$value) && f$value < 1e99, logical(1))
  if (!any(good)) stop('No converged Johnson profile-likelihood solution.')
  candidates <- fits[good]; vals <- vapply(candidates, function(f) f$value, numeric(1))
  selected <- candidates[[which.min(vals)]]
  # Re-evaluation at the chosen point, independent of optimizer bookkeeping.
  ans <- .ff_profile_johnson(y, model, selected$par, xmin, xmax)
  at_boundary <- any(abs(selected$par - lower) < 1e-4 | abs(selected$par - upper) < 1e-4)
  list(theta = ans$theta, diagnostics = list(converged_starts = sum(good), attempted_starts = length(starts),
    objective_range = range(vals), search_parameters = selected$par, lower = lower, upper = upper,
    boundary = at_boundary, optimizer = 'Profile likelihood / L-BFGS-B',
    note = if (at_boundary) 'Numerical search boundary reached; parameter identifiability and sensitivity need review.' else ''))
}
#' Fit Johnson SU, SL and SB to one variable
#' @param x Numeric vector or one-column prepared dataset.
#' @param types Johnson types to fit, any subset of SU, SL, SB.
#' @param ... Arguments passed to fit_univariate.
#' @return A familyfit_univariate object.
#' @export
fit_johnson_univariate <- function(x, types = c('SU', 'SL', 'SB'), ...) {
  fit_univariate(x, families = 'Johnson', johnson_types = types, ...)
}
#' Fit a Johnson transformed multivariate model
#' @param data Numeric matrix, data.frame or prepared dataset.
#' @param columns Analysis columns.
#' @param types Johnson types to consider for each marginal.
#' @param ... Arguments passed to fit_multivariate.
#' @return A familyfit_multivariate object.
#' @export
fit_johnson_multivariate <- function(data, columns = NULL, types = c('SU', 'SL', 'SB'), ...) {
  fit_multivariate(data, columns = columns, johnson_types = types, ...)
}
