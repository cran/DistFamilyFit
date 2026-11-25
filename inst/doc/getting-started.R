### R code from vignette source 'getting-started.Rnw'

###################################################
### code chunk number 1: setup
###################################################
library(DistFamilyFit)
set.seed(2026)


###################################################
### code chunk number 2: read-template
###################################################
path <- system.file('extdata', 'input_template.csv', package = 'DistFamilyFit')
prepared <- read_fit_data(path, columns = c('variable_1', 'variable_2'))
head(prepared$data, 3)
prepared$audit$n_retained


###################################################
### code chunk number 3: prepare-memory
###################################################
raw <- data.frame(id = seq_len(60), value = sinh(rnorm(60)))
clean <- prepare_fit_data(raw, columns = 'value')
clean$audit$ignored_columns


###################################################
### code chunk number 4: univariate
###################################################
x <- sinh(rnorm(120))
u <- fit_univariate(x)
u$ranking[, c('model', 'KS', 'status')]


###################################################
### code chunk number 5: select-family
###################################################
b <- fit_univariate(exp(x / 2), families = 'Burr')
g <- fit_univariate(x, families = 'GLD')
j <- fit_johnson_univariate(x, types = c('SU', 'SB'))
comparison <- fit_univariate(x, families = c('Johnson', 'GLD'))
if (requireNamespace('PearsonDS', quietly = TRUE)) {
  p <- fit_univariate(x, families = 'Pearson')
}


###################################################
### code chunk number 6: evaluate
###################################################
cdf_fit(u, c(-1, 0, 1))
quantile_fit(u, c(.1, .5, .9))
density_fit(u, c(-1, 0, 1))
transform_johnson(u, c(-1, 0, 1))


###################################################
### code chunk number 7: cdf-plot
###################################################
(function() {
  oldpar <- par(no.readonly = TRUE)
  on.exit({
    par(oldpar)
    par(mfg = oldpar$mfg, new = oldpar$new)
  }, add = TRUE)
plot_fit(u, type = 'cdf')
})()



###################################################
### code chunk number 8: comparison-plot
###################################################
(function() {
  oldpar <- par(no.readonly = TRUE)
  on.exit({
    par(oldpar)
    par(mfg = oldpar$mfg, new = oldpar$new)
  }, add = TRUE)
plot_comparison(comparison)
})()



###################################################
### code chunk number 9: multivariate
###################################################
z <- rnorm(120)
w <- .6 * z + sqrt(1 - .6^2) * rnorm(120)
paired <- data.frame(first = sinh(z), second = sinh(w))
m <- fit_johnson_multivariate(paired, types = 'SU')
m$marginal_diagnostics[, c('model', 'KS', 'status')]
round(m$correlation_Z, 3)


###################################################
### code chunk number 10: joint-plot
###################################################
(function() {
  oldpar <- par(no.readonly = TRUE)
  on.exit({
    par(oldpar)
    par(mfg = oldpar$mfg, new = oldpar$new)
  }, add = TRUE)
plot_transformed(m, type = 'mahalanobis')
})()



###################################################
### code chunk number 11: subsample
###################################################
big <- sinh(rnorm(2000))
s1 <- fit_univariate(big, johnson_types = 'SU', max_fit_n = 300, seed = 1)
s1$audit$n_estimation
