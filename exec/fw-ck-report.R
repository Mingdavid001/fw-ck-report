#!/usr/bin/env Rscript
# Minimal CLI for fw-ck-report
# Example (asymmetric):
#   Rscript exec/fw-ck-report.R --design=asymmetric --control=CK \
#     --input=inst/extdata/example_fw_asymmetric.csv --out=fw-ck-report.html
# Example (ARRIVE-lite / Methods footnote):
#   Rscript exec/fw-ck-report.R --methods-footnote \
#     --input=inst/extdata/example_fw.csv --out=fw-ck-report.html

args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  out <- list(
    design = "long",
    control = "CK",
    input = NULL,
    out = "fw-ck-report.html",
    methods_footnote = FALSE,
    help = FALSE
  )
  for (a in args) {
    if (a %in% c("-h", "--help")) {
      out$help <- TRUE
    } else if (startsWith(a, "--design=")) {
      out$design <- sub("^--design=", "", a)
    } else if (startsWith(a, "--control=")) {
      out$control <- sub("^--control=", "", a)
    } else if (startsWith(a, "--input=")) {
      out$input <- sub("^--input=", "", a)
    } else if (startsWith(a, "--out=")) {
      out$out <- sub("^--out=", "", a)
    } else if (a %in% c("--methods-footnote", "--arrive-lite")) {
      out$methods_footnote <- TRUE
    } else {
      stop("Unknown argument: ", a, call. = FALSE)
    }
  }
  out
}

usage <- function() {
  cat(
    "fw-ck-report — fresh weight vs CK + Dunnett\n",
    "\n",
    "Usage:\n",
    "  Rscript exec/fw-ck-report.R --design=asymmetric --control=CK \\\n",
    "    --input=inst/extdata/example_fw_asymmetric.csv --out=fw-ck-report.html\n",
    "  Rscript exec/fw-ck-report.R --methods-footnote \\\n",
    "    --input=inst/extdata/example_fw.csv --out=fw-ck-report.html\n",
    "\n",
    "Flags:\n",
    "  --design=long|asymmetric   long = rep,treatment,fw; asymmetric = wide dilution cols + control\n",
    "  --control=NAME             no-dose control column (wide) or level (long); default CK\n",
    "  --input=PATH               CSV path (required)\n",
    "  --out=PATH                 HTML output; default fw-ck-report.html\n",
    "  --methods-footnote         ARRIVE-lite Methods sentence + judgment checklist in HTML footer\n",
    "  --arrive-lite              alias of --methods-footnote\n",
    sep = ""
  )
}

opt <- parse_args(args)
if (isTRUE(opt$help)) {
  usage()
  quit(status = 0)
}
if (is.null(opt$input)) {
  usage()
  quit(status = 1)
}

ca <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", grep("^--file=", ca, value = TRUE))
if (!length(file_arg)) {
  stop("Could not resolve script path; run via: Rscript exec/fw-ck-report.R ...", call. = FALSE)
}
script_path <- normalizePath(file_arg[[1]], winslash = "/")
root <- dirname(dirname(script_path))

source(file.path(root, "R", "inhibition.R"))
source(file.path(root, "R", "dunnett_fw.R"))
source(file.path(root, "R", "asymmetric.R"))
source(file.path(root, "R", "arrive_lite.R"))
source(file.path(root, "R", "report.R"))

design <- opt$design
if (!design %in% c("long", "asymmetric")) {
  stop("--design must be 'long' or 'asymmetric'", call. = FALSE)
}

input <- opt$input
if (!file.exists(input)) {
  alt <- file.path(root, input)
  if (file.exists(alt)) input <- alt
}
if (!file.exists(input)) {
  stop("Input CSV not found: ", opt$input, call. = FALSE)
}

out_html <- opt$out
render_fw_report(
  csv_path = input,
  out_html = out_html,
  design = design,
  control = opt$control,
  methods_footnote = opt$methods_footnote
)

raw <- readr::read_csv(input, show_col_types = FALSE)
if (design == "asymmetric") {
  res <- run_asymmetric(raw, control = opt$control)
} else {
  ck_mean <- mean(raw$fresh_weight_g[raw$treatment == opt$control], na.rm = TRUE)
  raw$inhibition_pct <- inhibition_pct(raw$fresh_weight_g, ck_mean)
  res <- list(
    long = as.data.frame(raw),
    ck_mean = ck_mean,
    control = opt$control,
    dunnett = dunnett_fw(as.data.frame(raw), ck_level = opt$control)
  )
}
cat("CK mean fresh weight:", signif(res$ck_mean, 4), "\n")
print(res$dunnett)
