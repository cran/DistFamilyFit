#' Johnson transformation followed by a multivariate normal model
#' @param data Numeric matrix or data.frame.
#' @param columns Optional column names or indices. Non-numeric columns fail.
#' @param na_action fail or omit; omit uses complete cases before fitting.
#' @param ridge Explicit nonnegative diagonal regularization; zero by default.
#' @param johnson_types Any subset of SU, SL and SB.
#' @param ks_warning Descriptive marginal warning threshold.
#' @param ... Arguments to fit_univariate, except families, na_action, component.
#' @return A familyfit_multivariate object. Information criteria describe
#'   only the normal model in transformed Z space, conditional on fitted marginals.
#' @export
fit_multivariate <- function(data, columns = NULL, na_action = c('fail', 'omit'), ridge = 0, johnson_types = c('SU', 'SL', 'SB'), ks_warning = 0.2, ...) {
  na_action <- match.arg(na_action)
  dots <- list(...)
  if (any(names(dots) %in% c('families', 'na_action', 'component'))) stop('Multivariate fitting uses Johnson marginals and complete cases; these arguments cannot be overridden through ... .')
  min_n <- if (is.null(dots$min_n)) 20L else dots$min_n
  prepared <- prepare_fit_data(data, columns = columns, na_action = na_action, min_n = min_n)
  X <- as.matrix(prepared$data)
  if (ncol(X) < 2L) stop('At least two numeric columns are required.')
  if (!is.numeric(ridge) || length(ridge) != 1 || !is.finite(ridge) || ridge < 0) stop('ridge must be finite and nonnegative.')
  marginals <- lapply(seq_len(ncol(X)), function(j) fit_univariate(X[, j], families = 'Johnson', johnson_types = johnson_types, ks_warning = ks_warning, ...))
  names(marginals) <- colnames(X)
  if (any(vapply(marginals, function(f) is.na(f$best), logical(1)))) stop('At least one marginal has no numerically usable Johnson fit; inspect individual univariate fits.')
  for (j in seq_along(marginals)) {
    marginals[[j]]$input_audit <- prepared$audit
    marginals[[j]]$audit$n_input <- prepared$audit$n_input
    marginals[[j]]$audit$n_preprocessing_excluded <- prepared$audit$n_input - nrow(X)
    marginals[[j]]$audit$retained_rows <- prepared$audit$retained_rows
    marginals[[j]]$audit$excluded_rows <- prepared$audit$excluded_rows
  }
  Z <- matrix(NA_real_, nrow(X), ncol(X), dimnames = dimnames(X))
  for (j in seq_len(ncol(X))) {
    f <- .ff_select(marginals[[j]], marginals[[j]]$best)
    Z[, j] <- .ff_z_jac((X[, j] - f$origin) / f$scale, f$model, f$theta)$z
  }
  if (any(!is.finite(Z))) stop('Invalid transformed observations; no rows were silently removed.')
  mu <- colMeans(Z); n <- nrow(Z); p <- ncol(Z)
  sample_cov <- stats::cov(Z)
  # Normal MLE covariance differs from the sample covariance by (n-1)/n.
  Sigma <- sample_cov * (n - 1) / n + diag(ridge, p)
  R <- tryCatch(chol(Sigma), error = function(e) NULL)
  selected_rows <- do.call(rbind, lapply(marginals, function(f) f$ranking[f$ranking$model == f$best, c('model', 'KS', 'status', 'note')]))
  rownames(selected_rows) <- names(marginals)
  marginal_warning <- any(selected_rows$status != 'OK')
  ll <- NA_real_; state <- if (marginal_warning) 'Warning: review marginal diagnostics' else 'OK'
  if (marginal_warning) warning('Some selected Johnson marginals have fit or numerical warnings; inspect marginal_diagnostics before interpreting joint dependence.', call. = FALSE)
  distances <- rep(NA_real_, n)
  if (is.null(R) || rcond(Sigma) < 1e-12) {
    state <- 'Singular or ill-conditioned covariance'
    warning('Covariance is singular or ill-conditioned: likelihood unavailable. An explicit ridge may be used.', call. = FALSE)
  } else {
    centered <- sweep(Z, 2, mu)
    quadratic <- rowSums((centered %*% solve(R))^2)
    distances <- quadratic
    ll <- sum(-.5 * (p * log(2 * pi) + 2 * sum(log(diag(R))) + quadratic))
  }
  k <- p + p * (p + 1) / 2
  criteria <- c(logLik_Z = ll, AIC_Z = if (ridge == 0) 2 * k - 2 * ll else NA_real_, BIC_Z = if (ridge == 0) log(n) * k - 2 * ll else NA_real_)
  structure(list(marginals = marginals, Z = Z, mean_Z = mu, covariance_Z = sample_cov,
    correlation_Z = stats::cor(Z), normal_covariance_Z = Sigma, criteria_Z = criteria,
    marginal_diagnostics = selected_rows, mahalanobis_squared = distances,
    joint_diagnostic_distance = if (all(is.finite(distances))) {
      cdf_values <- stats::pchisq(sort(distances), df = p)
      max(seq_len(n) / n - cdf_values, cdf_values - (seq_len(n) - 1) / n)
    } else NA_real_,
    status = state, ridge = ridge, audit = prepared$audit), class = 'familyfit_multivariate')
}
#' @export
print.familyfit_multivariate <- function(x, ...) {
  cat('Johnson multivariate model\n', x$status, '\n', sep = '')
  cat('Complete rows:', x$audit$n_retained, '/', x$audit$n_input, '\n')
  print(vapply(x$marginals, function(f) f$best, character(1)))
  print(x$criteria_Z)
  invisible(x)
}
#' @export
summary.familyfit_multivariate <- function(object, ...) {
  list(marginals = lapply(object$marginals, summary), mean_Z = object$mean_Z,
       covariance_Z = object$covariance_Z, correlation_Z = object$correlation_Z,
       criteria_Z = object$criteria_Z, marginal_diagnostics = object$marginal_diagnostics,
       joint_diagnostic_distance = object$joint_diagnostic_distance, status = object$status, audit = object$audit)
}
#' @export
plot.familyfit_multivariate <- function(x, ...) plot_transformed(x, ...)
