#' Inhibition rate vs CK mean
#' @param fw numeric fresh weights
#' @param ck_mean mean fresh weight of CK
#' @return percent inhibition
inhibition_pct <- function(fw, ck_mean) {
  if (is.na(ck_mean) || ck_mean == 0) return(NA_real_)
  (ck_mean - fw) / ck_mean * 100
}
