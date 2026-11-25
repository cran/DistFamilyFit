# DistFamilyFit user guide

DistFamilyFit fits and compares four flexible families of continuous
distributions: Johnson (the default), Pearson, Burr and the generalized lambda
distribution (GLD). Dependence between several variables is described after
mapping each variable to a common normal scale with its fitted Johnson
transformation. The package implements the methodology of Karakaya Demir,
Purutçuoğlu and Bursalı (2026), accepted at ICATEEE 2026; please cite this paper
when you use the package (`citation("DistFamilyFit")`).

## Installation

```r
install.packages("DistFamilyFit")
# or, from a local source archive:
# install.packages("DistFamilyFit_0.1.1.tar.gz", repos = NULL, type = "source")
library(DistFamilyFit)

# Optional, required only for Pearson candidates:
# install.packages("PearsonDS")
```

Johnson, Burr and GLD fitting use base R only. If 'PearsonDS' is not installed,
only the Pearson candidate is reported as `Failed`, with an explanation.

## Input data

Each row is one observation and each selected column is one numeric variable.
For multivariate analysis, the values in a row must belong to the same
observation; do not sort variables independently before a joint analysis.

```csv
sample_id,variable_1,variable_2,variable_3
s001,12.5,4.2,-1.7
s002,18.3,6.8,0.4
s003,9.1,3.5,-2.1
```

The bundled template (`inst/extdata/input_template.csv`) contains 30 artificial
observations in this format.

- Use an 8-bit Unicode Transformation Format (UTF-8) comma-separated values (CSV) or tab-separated values (TSV) file with a unique, nonempty header.
- Every row must have the same number of fields. Quote text fields that contain
  the delimiter. Do not include repeated headers or subtotal rows.
- Numeric cells contain numbers only (`12.5`, `-3`, `0`, `1e-3`). Remove units,
  percentage signs and thousands separators first.
- Specify `sep` and `dec`; they must differ. Defaults are comma and period.
- Identifier, date and category columns may remain in the file; choose the
  analysis columns with `columns`.
- Blank cells and `NA` denote missing values. Missing or infinite analysis
  values raise an error unless `na_action = "omit"` is requested.
- Constant variables, matrix-valued columns and date-time vectors are rejected.
- Derived variables (aggregates, shares, unit conversions) should be created
  before fitting; the fitting functions do not transform data implicitly.

Zeros, negative values and outliers are never removed automatically. Character
numbers in memory are converted only with `convert_numeric = TRUE`. Omission is
complete-case across the selected columns, and the original row numbers of
retained and excluded observations are stored in the audit. The default minimum
sample size is 20 (configurable down to 5); this is a software threshold, not a
guarantee of reliable estimation.

```r
path <- system.file("extdata", "input_template.csv", package = "DistFamilyFit")
d <- read_fit_data(path, columns = c("variable_1", "variable_2"))
# Semicolon-delimited data with decimal commas:
# d <- read_fit_data("data.csv", sep = ";", dec = ",",
#                    columns = c("variable_1", "variable_2"))
```

## Analysis workflow

```r
u <- fit_univariate(prepare_fit_data(d, columns = "variable_1"))  # Johnson
comparison <- fit_univariate(d$data$variable_1, families = "all")
j <- fit_johnson_univariate(d$data$variable_1, types = c("SU", "SB"))
separate <- fit_columns(d, families = c("Johnson", "GLD"))
m <- fit_johnson_multivariate(d)

u$ranking
m$marginal_diagnostics
cdf_fit(u, c(-1, 0, 1))
quantile_fit(u, c(0.1, 0.5, 0.9))
density_fit(u, c(-1, 0, 1))
transform_johnson(u, c(-1, 0, 1))
```

`families = "Burr"` fits Burr Type III and Type XII, which require strictly
positive data; otherwise the candidates are reported as `Failed` and no
observation is dropped. `component = "positive"` fits the distribution of the
positive observations, conditional on X > 0; the share of zeros is not modelled.

Passing a bare numeric vector drops upstream file metadata. Use a one-column
prepared object, `fit_columns()` or the multivariate interface to keep the
original row numbers.

### Large samples and random numbers

`max_fit_n` estimates parameters on a random subsample when the data are larger
than this size; all observations are still used for evaluation and AIC is then
omitted. By default (`seed = NULL`) the subsample is drawn from the current
random number stream, so call `set.seed()` beforehand for reproducibility.
Alternatively, `seed` applies a seed locally and restores the previous random
number state afterwards. With the default `max_fit_n = Inf` no random numbers are
used.

## Public functions

| Function | Purpose | Output |
|---|---|---|
| `read_fit_data()` | Read and validate selected numeric CSV/TSV columns. | Prepared data and audit. |
| `prepare_fit_data()` | Validate an R vector, matrix, data frame or prepared input. | `familyfit_data` object. |
| `fit_univariate()` | Fit and compare selected continuous families. | Ranking, parameters, diagnostics and audit. |
| `fit_columns()` | Fit each selected column separately. | Named list of univariate fits. |
| `fit_johnson_univariate()` | Restrict fitting to selected Johnson types. | Univariate fit. |
| `fit_multivariate()` | Fit Johnson marginals and a normal model on the transformed scale. | Transformed data, covariance, correlation, diagnostics. |
| `fit_johnson_multivariate()` | Johnson-specific multivariate entry point. | Same multivariate class. |
| `cdf_fit()`, `density_fit()`, `quantile_fit()` | Evaluate a candidate in original units. | Probabilities, densities, quantiles. |
| `transform_johnson()` | Apply a fitted Johnson normal-scale transformation. | Normal-scale values. |
| `plot_fit()` | CDF, Q-Q or histogram/density plot. | Plot. |
| `plot_comparison()` | Compare candidate CDFs with the empirical CDF. | Plot. |
| `plot_dependence()` | Transformed-scale correlation or covariance matrix. | Matrix plot. |
| `plot_transformed()` | Pairs plot or Mahalanobis quantile-quantile (Q-Q) plot. | Plot. |
| `print()`, `summary()`, `plot()` | Inspect fitted objects. | Printed output, list or plot. |

## Reading the results

The `ranking` table contains, for every candidate:

- `KS`: the classical Kolmogorov-Smirnov distance between fitted and empirical
  CDFs; candidates are ordered by this value.
- `D_CDF`: the plotting-position distance max |F(x_(i)) - (i - 0.5)/n|.
- `MatchRate`: 100 (1 - `D_CDF`); not an accuracy, probability or p-value.
- `CDF_quantile_RMSE` and `TailError`: probability-scale discrepancies overall
  and in the upper tail.
- `NLL` and `AIC` for likelihood-based fits (Johnson, Burr) only.
- `status` and `note`.

| Status | Meaning |
|---|---|
| OK | Numerical checks passed; this does not by itself establish a good fit. |
| Warning | A descriptive warning, a search-boundary solution or partially failed starts. The candidate may still be selected. |
| Unstable | CDF/quantile consistency or monotonicity failed; excluded from selection. |
| Failed | The candidate could not be fitted; the reason is recorded. |

`best` is the candidate with the smallest `KS` among numerically usable
candidates. All distances are descriptive in-sample measures, not formal
goodness-of-fit tests; no p-value is computed after estimating parameters. The
default `ks_warning = 0.2` only triggers a descriptive note.

## Estimation methods

| Family | Forms | Estimation | Reference |
|---|---|---|---|
| Pearson | Types 0 to VII | Four-moment matching via 'PearsonDS' | Pearson (1895) |
| Johnson | SU, SL, SB | Profiled maximum likelihood, multistart L-BFGS-B | Johnson (1949) |
| Burr | Type III, Type XII | Numerical maximum likelihood (Nelder-Mead) | Burr (1942); Tadikamalla (1980) |
| Generalized lambda | FKML | Quantile matching; CDF by numerical inversion | Ramberg and Schmeiser (1974); Freimer et al. (1988); Chalabi et al. (2012) |

Further background on these systems is given by Johnson, Kotz and Balakrishnan
(1994).

- Johnson searches are bounded on standardized log scales by [-12, 12]; the SU
  location is bounded by the standardized data range extended by 100 spans.
  These are numerical guards. A solution within 1e-4 of a bound is reported as
  `Warning`, its AIC is omitted, and no other distribution is substituted.
  SL has three identifiable parameters.
- Pearson moments use the empirical divisor-n convention.
- The GLD is matched at the 0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95 and
  0.99 quantiles (type 5). Its CDF is obtained by bisection of the quantile
  function to relative tail accuracy.
- Burr calculations are carried out on the log scale for numerical stability.
- Routine round-trip checks cover the 1%-99% quantile range; finite precision
  limits evaluation in the extreme tails.
- Count variables are treated as continuous approximations; no discrete,
  hurdle or zero-inflated model is fitted. Natural bounds such as [0, 1] are not
  imposed on every family automatically.

## Multivariate interpretation

`covariance_Z` uses divisor n - 1; `normal_covariance_Z` uses divisor n plus an
optional explicit `ridge`. Singular or ill-conditioned covariance matrices are
reported, not silently regularised. `criteria_Z` describes only the normal model
for the transformed data, conditional on the fitted marginals; it is not an
original-scale joint AIC/BIC and should not be compared across different
transformations. Mahalanobis plots are descriptive. Marginal normality after
transformation does not imply joint normality, and dependence between repeated
or time-ordered rows is not modelled.

## Visualizations

Fitting functions do not open graphics devices. Plots are drawn explicitly:

```r
plot_fit(u, type = "cdf")
plot_fit(u, type = "qq")
plot_fit(u, type = "density", breaks = 30)
plot_comparison(comparison)
plot_dependence(m, type = "correlation")
plot_transformed(m, type = "mahalanobis")
```

Titles and axis labels can be overridden through named graphics arguments. A
worked example is available with
`vignette("getting-started", package = "DistFamilyFit")`.

## References

- Burr, I. W. (1942). Cumulative frequency functions. *The Annals of
  Mathematical Statistics*, 13(2), 215-232. doi:10.1214/aoms/1177731607
- Chalabi, Y., Scott, D. J. and Wuertz, D. (2012). Flexible distribution
  modeling with the generalized lambda distribution. MPRA Paper No. 43333.
- Freimer, M., Kollia, G., Mudholkar, G. S. and Lin, C. T. (1988). A study of
  the generalized Tukey lambda family. *Communications in Statistics - Theory
  and Methods*, 17(10), 3547-3567. doi:10.1080/03610928808829820
- Johnson, N. L. (1949). Systems of frequency curves generated by methods of
  translation. *Biometrika*, 36(1-2), 149-176. doi:10.1093/biomet/36.1-2.149
- Johnson, N. L., Kotz, S. and Balakrishnan, N. (1994). *Continuous Univariate
  Distributions*, Vol. 1, 2nd ed. Wiley.
- Karakaya Demir, Ş. Ş., Purutçuoğlu, V. and Bursalı, A. (2026). Modeling Mobile Application Usage with Distribution Families. Accepted at the
  3rd International Conference on Advanced Technology in Electronic and
  Electrical Engineering (ICATEEE 2026), Hammamet, Tunisia.
- Pearson, K. (1895). Contributions to the mathematical theory of evolution.
  II. Skew variation in homogeneous material. *Philosophical Transactions of
  the Royal Society of London. A*, 186, 343-414. doi:10.1098/rsta.1895.0010
- Ramberg, J. S. and Schmeiser, B. W. (1974). An approximate method for
  generating asymmetric random variables. *Communications of the ACM*, 17(2),
  78-82. doi:10.1145/360827.360840
- Tadikamalla, P. R. (1980). A look at the Burr and related distributions.
  *International Statistical Review*, 48(3), 337-344. doi:10.2307/1402945

## Detailed terminology

See `help("DistFamilyFit_glossary")` for expanded abbreviations, formulas and interpretation of diagnostic fields. The plotting-position cumulative distribution function distance (`D_CDF`) is distinct from the classical Kolmogorov-Smirnov distance. An explicit subsampling seed restores the previous random number generator state; `seed = NULL` uses and advances the current state.
