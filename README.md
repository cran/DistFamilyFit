# DistFamilyFit

Fitting and comparing flexible continuous distribution families in R.

DistFamilyFit fits the Johnson unbounded (SU), lognormal (SL) and bounded (SB) forms, Pearson, Burr (Type III, Type XII)
and Freimer-Kollia-Mudholkar-Lin (FKML) generalized lambda families to a numeric variable, ranks the candidates
by descriptive cumulative distribution function (CDF) distances and provides separate diagnostic plots.
Johnson marginal transformations map several variables to a common normal
scale, on which dependence is summarised by covariance and correlation matrices.

| Family | Estimation |
|---|---|
| Johnson (default) | Profiled maximum likelihood |
| Pearson | Four-moment matching (suggested package 'PearsonDS') |
| Burr III / XII | Numerical maximum likelihood |
| Generalized lambda (FKML) | Quantile matching |

## Installation

```r
install.packages("DistFamilyFit")
```

## Example

```r
library(DistFamilyFit)
path <- system.file("extdata", "input_template.csv", package = "DistFamilyFit")
d <- read_fit_data(path, columns = c("variable_1", "variable_2"))

u <- fit_univariate(prepare_fit_data(d, columns = "variable_1"))  # Johnson
comparison <- fit_univariate(d$data$variable_1, families = "all")
comparison$ranking

m <- fit_johnson_multivariate(d)
m$correlation_Z

plot_comparison(comparison)
plot_dependence(m)
```

Distances such as `KS` and `D_CDF` are descriptive in-sample measures, not
formal goodness-of-fit tests. Count data are treated as continuous
approximations, and positive-part fits (`component = "positive"`) are
conditional on X > 0.

See `vignette("getting-started", package = "DistFamilyFit")` and
`inst/USER_GUIDE.md` for the input format, methods and interpretation.

## Citation

The package implements the methodology of:

Karakaya Demir, Ş. Ş., Purutçuoğlu, V. and Bursalı, A. (2026). Modeling Mobile
Application Usage with Distribution Families. Accepted at the 3rd
International Conference on Advanced Technology in Electronic and Electrical
Engineering (ICATEEE 2026), Hammamet, Tunisia.

See `citation("DistFamilyFit")` for BibTeX entries.

## Authors

Şule Şevval Karakaya Demir (maintainer), Vilda Purutçuoğlu and Ahmet Bursalı.
Supported by the Scientific and Technological Research Council of Türkiye (TÜBİTAK) 1505 research project no. 5240032.

## License

MIT + file LICENSE

## Author details

The author roles are author (aut) and maintainer (cre). ORCID stands for Open Researcher and Contributor ID.

| Author | Affiliation | Email | ORCID |
|---|---|---|---|
| Şule Şevval Karakaya Demir | Department of Biomedical Engineering, Middle East Technical University, Ankara, Türkiye | sule.karakaya@metu.edu.tr | 0000-0003-1851-4109 |
| Vilda Purutçuoğlu | Department of Biomedical Engineering and Department of Statistics, Middle East Technical University, Ankara, Türkiye | vpurutucu@metu.edu.tr | 0000-0002-0757-0837 |
| Ahmet Bursalı | Intelligent Application DC Department, Huawei Turkey Research and Development Center, İstanbul, Türkiye | ahmet.bursali@huawei.com | 0000-0001-7050-769X |

DC is retained as supplied in the department name; no expansion was provided.

## Terminology

See `help("DistFamilyFit_glossary")` or `GLOSSARY.md` in the installed package for expanded abbreviations and output definitions.
