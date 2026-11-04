#' Flatten an asymmetric pot-trial table (dilution columns + no-dose control)
#'
#' Wide schema: one `rep` column, one control column (default `CK`), and one
#' or more treatment / dilution columns with fresh weights. Long schema is
#' already `rep,treatment,fresh_weight_g` and is returned unchanged.
#'
#' @param data data.frame
#' @param control name of the no-dose control column / level (default "CK")
#' @param rep_col replicate id column (default "rep")
#' @param value_name output fresh-weight column name
#' @return long data.frame with columns rep, treatment, fresh_weight_g
flatten_asymmetric <- function(data,
                               control = "CK",
                               rep_col = "rep",
                               value_name = "fresh_weight_g") {
  stopifnot(is.data.frame(data))
  nms <- names(data)

  # Already long?
  if (all(c(rep_col, "treatment", value_name) %in% nms)) {
    out <- data[, c(rep_col, "treatment", value_name), drop = FALSE]
    names(out) <- c("rep", "treatment", "fresh_weight_g")
    return(out)
  }

  if (!rep_col %in% nms) {
    stop("Asymmetric wide data needs a '", rep_col, "' column.", call. = FALSE)
  }
  if (!control %in% nms) {
    stop(
      "Control column '", control,
      "' not found. Pass --control=<col> matching the no-dose column.",
      call. = FALSE
    )
  }

  treat_cols <- setdiff(nms, rep_col)
  if (length(treat_cols) < 2L || !control %in% treat_cols) {
    stop("Need control + at least one dilution/treatment column.", call. = FALSE)
  }

  long <- stats::reshape(
    as.data.frame(data),
    varying = treat_cols,
    v.names = value_name,
    timevar = "treatment",
    times = treat_cols,
    idvar = rep_col,
    direction = "long"
  )
  rownames(long) <- NULL
  long <- long[, c(rep_col, "treatment", value_name), drop = FALSE]
  names(long) <- c("rep", "treatment", "fresh_weight_g")
  long$treatment <- as.character(long$treatment)
  long
}

#' Run asymmetric design: flatten -> inhibition vs CK -> Dunnett vs control
#'
#' @param data wide or long data.frame
#' @param control no-dose control column/level
#' @return list with long, ck_mean, table (with inhibition_pct), dunnett
run_asymmetric <- function(data, control = "CK") {
  long <- flatten_asymmetric(data, control = control)
  if (!control %in% long$treatment) {
    stop("After flatten, control level '", control, "' is missing.", call. = FALSE)
  }
  ck_mean <- mean(long$fresh_weight_g[long$treatment == control], na.rm = TRUE)
  long$inhibition_pct <- inhibition_pct(long$fresh_weight_g, ck_mean)
  dun <- dunnett_fw(long, ck_level = control)
  list(long = long, ck_mean = ck_mean, control = control, dunnett = dun)
}
