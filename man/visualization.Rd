\name{plot_fit}
\alias{plot_fit}
\alias{plot_comparison}
\alias{plot_dependence}
\alias{plot_transformed}
\title{Distribution and Dependence Visualizations}
\description{Plot distributions after estimation. Fitting functions do not open graphics devices.}
\usage{plot_fit(object, type = c("cdf", "qq", "density"), model = object$best, ...)
plot_comparison(object, models = NULL, ...)
plot_dependence(object, type = c("correlation", "covariance"))
plot_transformed(object, type = c("pairs", "mahalanobis"), ...)}
\arguments{\item{object}{Corresponding univariate or multivariate fit.}
\item{type}{Requested plot type.}
\item{model}{Univariate candidate name.}
\item{models}{Candidates to compare. NULL uses computationally usable candidates.}
\item{...}{Distinct named arguments to the base plotting function; main and axis labels override defaults. Evaluation data cannot be overridden. Density overlays require probability=TRUE/freq=FALSE.}}
\value{Invisibly the input object, except plot_dependence, which invisibly returns the plotted matrix.}
\details{Dependence is displayed in transformed Z space. The Mahalanobis quantile-quantile (Q-Q) plot uses a chi-square reference and is descriptive because parameters and transformations were estimated. It is not a calibrated goodness-of-fit test.}

\examples{
(function() {
  oldpar <- par(no.readonly = TRUE)
  on.exit({
    par(oldpar)
    par(mfg = oldpar$mfg, new = oldpar$new)
  }, add = TRUE)

set.seed(2026)
x <- sinh(rnorm(60))
u <- fit_johnson_univariate(x, types = "SU")
plot_fit(u, type = "qq")
plot_comparison(u)
m <- fit_johnson_multivariate(data.frame(a = x, b = sinh(rnorm(60))), types = "SU")
plot_dependence(m)
plot_transformed(m, type = "mahalanobis")

})()
}
