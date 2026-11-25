#' Prepare a rectangular numeric dataset
#' @param data Numeric vector, matrix, data.frame or prepared object.
#' @param columns Explicit names or indices of analysis columns.
#' @param na_action Fail or omit rows with nonfinite analysis values.
#' @param convert_numeric Explicitly convert character numeric columns.
#' @param min_n Minimum retained observations, at least five.
#' @return A familyfit_data object containing numeric data and an audit.
#' @export
prepare_fit_data <- function(data, columns = NULL, na_action = c('fail', 'omit'),
                             convert_numeric = FALSE, min_n = 20L) {
  na_action <- match.arg(na_action)
  if (length(min_n) != 1L || !is.numeric(min_n) || !is.finite(min_n) || min_n < 5 || min_n != floor(min_n)) stop('min_n must be an integer >= 5.')
  if (!is.logical(convert_numeric) || length(convert_numeric) != 1L || is.na(convert_numeric)) stop('convert_numeric must be TRUE or FALSE.')
  upstream <- NULL
  if (inherits(data, 'familyfit_data')) { .ff_validate_prepared(data); upstream <- data$audit; data <- data$data }
  if (.ff_numeric_vector(data)) data <- data.frame(value = data)
  if (!is.data.frame(data) && !is.matrix(data)) stop('Use a numeric vector, matrix or data.frame.')
  if (is.matrix(data)) {
    if (is.null(colnames(data))) colnames(data) <- paste0('V', seq_len(ncol(data)))
    data <- as.data.frame(data, stringsAsFactors = FALSE, optional = TRUE)
  }
  if (!ncol(data) || anyNA(names(data)) || any(!nzchar(trimws(names(data)))) || anyDuplicated(names(data))) stop('Column names must be nonempty and unique.')
  all_names <- names(data)
  if (!is.null(columns)) {
    valid <- if (is.character(columns)) !anyNA(columns) && all(columns %in% all_names) else
      is.numeric(columns) && !anyNA(columns) && all(is.finite(columns)) && all(columns == floor(columns)) && all(columns >= 1 & columns <= ncol(data))
    if (!length(columns) || !valid || anyDuplicated(columns)) stop('columns must contain distinct existing names or positive indices.')
    data <- data[, columns, drop = FALSE]
  }
  converted <- character()
  for (nm in names(data)) {
    x <- data[[nm]]
    if (.ff_numeric_vector(x)) next
    if (!is.null(dim(x))) stop(paste('Each data.frame column must be one vector, not a matrix/array:', nm))
    if (!convert_numeric || !is.character(x)) stop(paste('Non-numeric analysis column:', nm, '- select numeric columns or explicitly convert character numbers.'))
    y <- suppressWarnings(as.numeric(trimws(x)))
    if (any(!is.na(x) & !is.finite(y))) stop(paste('Cannot safely convert column:', nm))
    data[[nm]] <- y; converted <- c(converted, nm)
  }
  X <- as.matrix(data)
  keep <- rowSums(!is.finite(X)) == 0L
  if (any(!keep) && na_action == 'fail') stop('Missing/non-finite analysis values: choose na_action = "omit" explicitly.')
  if (sum(keep) < min_n) stop('Too few retained observations.')
  data <- data[keep, , drop = FALSE]
  variation <- vapply(data, function(x) is.finite(stats::sd(x)) && stats::sd(x) > 0, logical(1))
  if (any(!variation)) stop(paste('Constant or numerically unscalable columns:', paste(names(data)[!variation], collapse = ', ')))
  rows <- if (is.null(upstream)) seq_len(nrow(X)) else upstream$retained_rows
  retained <- rows[keep]
  original_n <- if (is.null(upstream)) nrow(X) else upstream$n_input
  structure(list(data = data, audit = utils::modifyList(if (is.null(upstream)) list() else upstream, list(n_input = original_n, n_retained = nrow(data),
    retained_rows = retained, excluded_rows = setdiff(seq_len(original_n), retained),
    columns = names(data), ignored_columns = unique(c(upstream$ignored_columns, setdiff(all_names, names(data)))),
    converted_columns = unique(c(upstream$converted_columns, converted)), na_action = na_action))), class = 'familyfit_data')
}
#' Read a delimited data file with an explicit schema
#' @param file Path to a UTF-8 text CSV or TSV file with a header row.
#' @param sep Field separator, e.g. comma, semicolon or tab.
#' @param dec Decimal mark, dot or comma.
#' @param columns Names or indices of numeric analysis columns.
#' @param na_strings Text values representing missing observations.
#' @param na_action Fail or omit nonfinite analysis rows.
#' @param min_n Minimum retained sample size.
#' @return A familyfit_data object suitable for fitting functions.
#' @export
read_fit_data <- function(file, sep = ',', dec = '.', columns = NULL,
                          na_strings = c('', 'NA'), na_action = c('fail', 'omit'), min_n = 20L) {
  if (!is.character(file) || length(file) != 1L || is.na(file) || !file.exists(file)) stop('file must be an existing local text file.')
  if (!is.character(sep) || length(sep) != 1L || is.na(sep) || nchar(sep) != 1L || !is.character(dec) || length(dec) != 1L || is.na(dec) || !dec %in% c('.', ',') || sep == dec) stop('Specify distinct field separator and decimal mark.')
  if (!is.character(na_strings) || anyNA(na_strings)) stop('na_strings must be a character vector without missing entries.')
  header <- utils::read.table(file, header = FALSE, sep = sep, nrows = 1L,
    quote = '"', comment.char = '', na.strings = NULL, stringsAsFactors = FALSE, colClasses = 'character', fileEncoding = 'UTF-8-BOM')
  names_raw <- unlist(header, use.names = FALSE)
  if (anyNA(names_raw) || any(!nzchar(trimws(names_raw))) || anyDuplicated(names_raw)) stop('File header must contain nonempty unique column names.')
  d <- utils::read.table(file, header = TRUE, sep = sep, dec = dec, na.strings = na_strings,
    quote = '"', comment.char = '', check.names = FALSE, stringsAsFactors = FALSE,
    fileEncoding = 'UTF-8-BOM', fill = FALSE, row.names = NULL)
  if (ncol(d) != length(names_raw) || !identical(names(d), names_raw)) stop('File must be rectangular and match its header.')
  out <- prepare_fit_data(d, columns = columns, na_action = match.arg(na_action), min_n = min_n)
  out$audit$file <- basename(file); out$audit$sep <- sep; out$audit$dec <- dec
  out
}
