\name{DistFamilyFit-package}
\alias{DistFamilyFit-package}
\alias{DistFamilyFit}
\docType{package}
\title{Fitting and Comparing Flexible Continuous Distribution Families}
\description{Fit and compare the Pearson, Johnson, Burr and generalized lambda
families of continuous distributions, and use Johnson marginal transformations
for descriptive dependence analysis on a common normal scale. Data preparation
is explicit and every omitted observation is recorded.}
\details{
Start with \code{\link{read_fit_data}} or \code{\link{prepare_fit_data}}. Use
\code{\link{fit_univariate}} to fit the Johnson family (the default), Pearson,
Burr, generalized lambda or all families. \code{\link{fit_columns}} fits several
columns independently. \code{\link{fit_johnson_multivariate}} describes
dependence in the Johnson-transformed space. Fitting functions never draw;
plots are produced only by the separate plotting functions.

\tabular{lll}{
  \strong{Family} \tab \strong{Forms} \tab \strong{Estimation} \cr
  Pearson \tab Types 0 to VII (via \pkg{PearsonDS}) \tab Four-moment matching \cr
  Johnson \tab SU, SL, SB \tab Profiled maximum likelihood \cr
  Burr \tab Type III, Type XII \tab Maximum likelihood \cr
  Generalized lambda \tab FKML parameterization \tab Quantile matching \cr
}

Candidates are ranked by the classical Kolmogorov--Smirnov distance between the
fitted and empirical cumulative distribution functions. The plotting-position
distance \code{D_CDF}, \eqn{\max_i |F(x_{(i)}) - (i - 0.5)/n|}, is also
reported. Both are descriptive in-sample discrepancy measures and not formal
goodness-of-fit tests.

The package implements the methodology of Karakaya Demir, Purutçuoğlu and
Bursalı (2026); please cite this paper when using the package (see
\code{citation("DistFamilyFit")}).
}
\author{
Şule Şevval Karakaya Demir (author and maintainer), Department of Biomedical Engineering, Middle East Technical University, Ankara, Türkiye. \email{sule.karakaya@metu.edu.tr}. ORCID: 0000-0003-1851-4109.

Vilda Purutçuoğlu (author), Department of Biomedical Engineering and Department of Statistics, Middle East Technical University, Ankara, Türkiye. \email{vpurutucu@metu.edu.tr}. ORCID: 0000-0002-0757-0837.

Ahmet Bursalı (author), Intelligent Application DC Department, Huawei Turkey Research and Development Center, İstanbul, Türkiye. \email{ahmet.bursali@huawei.com}. ORCID: 0000-0001-7050-769X.

ORCID stands for Open Researcher and Contributor ID. DC is retained as supplied in the department name; no expansion was provided.
}
\seealso{\code{\link{fit_univariate}}, \code{\link{fit_johnson_multivariate}},
\code{\link{plot_fit}}}
\keyword{package}
\keyword{distribution}
