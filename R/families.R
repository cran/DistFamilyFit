#' Fit a selected family independently to dataset columns
#' @param data Numeric vector, matrix, data.frame or prepared dataset.
#' @param columns Numeric analysis columns.
#' @param families Johnson by default; Pearson, Burr, GLD or all also supported.
#' @param na_action Fail or explicitly omit incomplete analysis rows.
#' @param ... Additional arguments to fit_univariate.
#' @return A named list of independent univariate fits; not a joint model.
#' @export
fit_columns <- function(data, columns = NULL, families = 'Johnson',
                        na_action = c('fail', 'omit'), ...) {
  dots <- list(...)
  min_n <- if (is.null(dots$min_n)) 20L else dots$min_n
  prepared <- prepare_fit_data(data, columns = columns, na_action = match.arg(na_action), min_n = min_n)
  results <- lapply(names(prepared$data), function(nm) {
    one <- prepare_fit_data(prepared, columns = nm, min_n = min_n)
    fit_univariate(one, families = families, ...)
  })
  names(results) <- names(prepared$data)
  attr(results, 'input_audit') <- prepared$audit
  results
}
#' Convert original values to the selected Johnson normal scale
#' @param object Univariate Johnson fit.
#' @param x Original-scale values.
#' @param model Selected Johnson candidate.
#' @return Numeric normal-scale values. Values outside support may be infinite.
#' @export
transform_johnson <- function(object, x, model = object$best) {
  fit <- .ff_select(object, model)
  if (!startsWith(model, 'Johnson')) stop('A Johnson candidate is required.')
  if (!.ff_numeric_vector(x)) stop('x must be numeric.')
  .ff_z_jac((x - fit$origin) / fit$scale, model, fit$theta)$z
}
