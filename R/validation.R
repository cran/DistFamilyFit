# Shared guards used by public entry points.
.ff_numeric_vector <- function(x) {
  is.numeric(x) && !is.complex(x) && is.null(dim(x)) &&
    !inherits(x, c('Date', 'POSIXt', 'difftime'))
}
.ff_validate_prepared <- function(object) {
  if (!is.list(object) || !is.data.frame(object$data) || !is.list(object$audit)) stop('Invalid prepared data object.')
  a <- object$audit; rows <- a$retained_rows
  if (!is.numeric(a$n_input) || length(a$n_input) != 1L || !is.finite(a$n_input) || a$n_input < nrow(object$data) || a$n_input != floor(a$n_input) ||
      !is.numeric(rows) || length(rows) != nrow(object$data) || anyNA(rows) || any(!is.finite(rows)) || any(rows != floor(rows)) ||
      any(rows < 1 | rows > a$n_input) || anyDuplicated(rows)) stop('Prepared data has an invalid original-row audit.')
  if (!ncol(object$data) || anyNA(names(object$data)) || any(!nzchar(trimws(names(object$data)))) || anyDuplicated(names(object$data)) ||
      !all(vapply(object$data, .ff_numeric_vector, logical(1)))) stop('Prepared data must contain uniquely named numeric-vector columns.')
  invisible(object)
}
.ff_validate_control <- function(control) {
  if (!is.list(control) || (length(control) && (is.null(names(control)) || anyNA(names(control)) || any(!nzchar(names(control))) || anyDuplicated(names(control))))) stop('control must be a list of distinct named optim options.')
  allowed <- c('maxit', 'reltol', 'factr', 'pgtol', 'trace', 'REPORT', 'ndeps', 'alpha', 'beta', 'gamma')
  if (any(!names(control) %in% allowed)) stop('Unsupported control option. Objective scaling/direction and parameter scaling cannot be overridden.')
  for (nm in names(control)) {
    value <- control[[nm]]
    if (!is.numeric(value) || !length(value) || any(!is.finite(value))) stop(paste('Non-finite or nonnumeric control option:', nm))
    if (nm == 'ndeps') {
      if (length(value) != 1L || value <= 0) stop('ndeps must be a positive scalar; it is expanded to each optimizer dimension.')
    } else if (length(value) != 1L) stop(paste('Control option must be scalar:', nm))
    if (nm %in% c('maxit', 'REPORT') && (value < 1 || value != floor(value))) stop(paste('Control option must be a positive integer:', nm))
    if (nm == 'trace' && (value < 0 || value != floor(value))) stop('trace must be a nonnegative integer.')
    if (nm %in% c('reltol', 'factr', 'alpha', 'beta', 'gamma') && value <= 0) stop(paste('Control option must be positive:', nm))
    if (nm == 'pgtol' && value < 0) stop('pgtol must be nonnegative.')
  }
  invisible(control)
}
.ff_optim_control <- function(control, method, dimension) {
  .ff_validate_control(control)
  allowed <- if (method == 'L-BFGS-B') c('maxit', 'factr', 'pgtol', 'trace', 'REPORT', 'ndeps') else c('maxit', 'reltol', 'trace', 'REPORT', 'alpha', 'beta', 'gamma')
  out <- control[intersect(names(control), allowed)]
  if (!is.null(out$ndeps)) out$ndeps <- rep(out$ndeps, dimension)
  out
}
