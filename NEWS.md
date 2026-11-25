# DistFamilyFit 0.1.1

* Base this resubmission on the submitted DistFamilyFit 0.1.0 source.
* Expand abbreviations and add a detailed installed glossary.
* Restore graphical parameters in examples, the vignette and demo, including errors.
* Remove the vignette output-width option override and rebuild installed documentation.
* Rename local cumulative probability vectors from F to cdf_values.
* Adopt the requested MIT License and update author affiliations and contact details.
* Preserve the submitted estimation, subsampling, output fields, references and funding acknowledgment.

# DistFamilyFit 0.1.0

* Initial CRAN submission.
* Implements the methodology of Karakaya Demir, Purutçuoğlu and Bursalı
  (2026), accepted at ICATEEE 2026; see `citation("DistFamilyFit")`.

## Features

* `fit_univariate()` fits and ranks the Johnson (SU, SL, SB), Pearson,
  Burr (Type III, Type XII) and FKML generalized lambda families. The Johnson
  family is the default; `families = "all"` fits every family.
* Estimation follows the structure of each family: profiled maximum likelihood
  for Johnson, numerical maximum likelihood for Burr, four-moment matching for
  Pearson (through the suggested package 'PearsonDS') and quantile matching for
  the generalized lambda distribution.
* Candidates are compared with the classical Kolmogorov-Smirnov distance and the
  plotting-position distance `D_CDF`; both are descriptive, in-sample measures.
* `fit_multivariate()` and `fit_johnson_multivariate()` map each variable to a
  common normal scale through its fitted Johnson transformation and summarise
  dependence by the transformed-scale mean, covariance and correlation.
* `read_fit_data()` and `prepare_fit_data()` validate numeric input and record
  the original row numbers of every retained and excluded observation.
* `cdf_fit()`, `density_fit()`, `quantile_fit()` and `transform_johnson()`
  evaluate fitted candidates in the original data units.
* `plot_fit()`, `plot_comparison()`, `plot_dependence()` and
  `plot_transformed()` draw diagnostic plots; fitting functions never draw.
* Optional estimation subsampling (`max_fit_n`) uses the current random number
  stream by default; a `seed` can be supplied for a reproducible subsample.
