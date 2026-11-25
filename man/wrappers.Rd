\name{fit_columns}
\alias{fit_columns}
\alias{fit_johnson_univariate}
\alias{fit_johnson_multivariate}
\alias{transform_johnson}
\title{Column-Wise Fitting and Johnson Convenience Functions}
\description{Fit independent columns, fit Johnson-only models or evaluate a Johnson normal-scale transformation.}
\usage{fit_columns(data, columns = NULL, families = "Johnson",
  na_action = c("fail", "omit"), ...)
fit_johnson_univariate(x, types = c("SU", "SL", "SB"), ...)
fit_johnson_multivariate(data, columns = NULL, types = c("SU", "SL", "SB"), ...)
transform_johnson(object, x, model = object$best)}
\arguments{\item{data}{Numeric matrix, data.frame, vector or prepared data (multivariate requires at least two columns).}
\item{columns}{Analysis column names or indices.}
\item{families}{Johnson by default; Pearson, Burr, GLD, a subset or all.}
\item{na_action}{Fail or omit complete rows explicitly.}
\item{x}{Numeric vector or one-column prepared dataset for fitting; numeric original-scale values for transformation.}
\item{types}{Subset of unbounded (SU), lognormal (SL) and bounded (SB) Johnson forms.}
\item{object}{A univariate fit containing a Johnson candidate.}
\item{model}{Johnson candidate name.}
\item{...}{Arguments forwarded to fit_univariate or fit_multivariate, except arguments already supplied by the wrapper.}}
\value{fit_columns returns a named list of independent univariate fits and an input_audit attribute; it is not a joint model. Complete-case preprocessing is shared across selected columns, and individual fits preserve original-row audit identifiers. Johnson wrappers return their corresponding fit object. transform_johnson returns a numeric vector.}

\examples{
set.seed(2026)
x <- sinh(rnorm(60))
u <- fit_johnson_univariate(x, types = "SU")
transform_johnson(u, c(-1, 0, 1))
d <- data.frame(a = x, b = sinh(rnorm(60)))
separate <- fit_columns(d, families = "Johnson", johnson_types = "SU")
joint <- fit_johnson_multivariate(d, types = "SU")
}
