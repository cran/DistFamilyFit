\name{cdf_fit}
\alias{cdf_fit}
\alias{density_fit}
\alias{quantile_fit}
\title{Evaluate Fitted Distributions in Original Data Units}
\description{Evaluate CDFs, densities and quantiles of successfully fitted univariate candidates.}
\usage{cdf_fit(object, x, model = object$best)
density_fit(object, x, model = object$best, log = FALSE)
quantile_fit(object, p, model = object$best)}
\arguments{
\item{object}{Univariate fit.}
\item{x}{Numeric evaluation points.}
\item{p}{Probabilities in [0,1].}
\item{model}{Candidate name.}
\item{log}{Return log density.}}
\value{Numeric values in original data units.}

\examples{
set.seed(2026)
f <- fit_johnson_univariate(sinh(rnorm(60)), types = "SU")
cdf_fit(f, c(-1, 0, 1))
density_fit(f, c(-1, 0, 1))
quantile_fit(f, c(.1, .5, .9))
}
