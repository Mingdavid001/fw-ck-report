#' Write a one-page HTML stub from example or user CSV path
#' @param csv_path path to CSV
#' @param out_html output HTML path
render_fw_report <- function(csv_path, out_html = "fw-ck-report.html") {
  message("MVP stub: load CSV, compute CK mean inhibition table, run dunnett_fw, knit HTML.")
  message("Wire rmarkdown template in v0.0.2. Input: ", csv_path, " -> ", out_html)
  invisible(NULL)
}
