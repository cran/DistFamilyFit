\name{DistFamilyFit-methods}
\alias{print.familyfit_univariate}
\alias{summary.familyfit_univariate}
\alias{plot.familyfit_univariate}
\alias{print.familyfit_multivariate}
\alias{summary.familyfit_multivariate}
\alias{plot.familyfit_multivariate}
\title{Inspect Distribution Fit Objects}
\description{Print fit rankings, inspect detailed summaries and plot fitted distributions or transformed variables.}
\usage{\method{print}{familyfit_univariate}(x, ...)
\method{summary}{familyfit_univariate}(object, ...)
\method{plot}{familyfit_univariate}(x, type = c("cdf", "qq", "density"),
  model = x$best, ...)
\method{print}{familyfit_multivariate}(x, ...)
\method{summary}{familyfit_multivariate}(object, ...)
\method{plot}{familyfit_multivariate}(x, ...)}
\arguments{\item{x, object}{Fit object.}
\item{type}{Univariate plot type.}
\item{model}{Univariate candidate name.}
\item{...}{Additional plotting arguments or unused method arguments.}}
\value{Print/plot invisibly return the input; summary returns a list.}

\examples{
(function() {
  oldpar <- par(no.readonly = TRUE)
  on.exit({
    par(oldpar)
    par(mfg = oldpar$mfg, new = oldpar$new)
  }, add = TRUE)

set.seed(2026)
u <- fit_johnson_univariate(sinh(rnorm(60)), types = "SU")
print(u)
summary(u)
plot(u)

})()
}
