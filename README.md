# fw-ck-report

Open-source helper for **pot-trial fresh weight 鈫?inhibition vs CK + Dunnett**, with an optional one-page HTML report.

Free core. Paid seats buy a **written judgment receipt** (is this CK table report-ready?)鈥攏ot hours of analysis ops.

## Quick start (long / symmetric)

```r
# install.packages(c("multcomp", "dplyr", "readr"))
source("R/inhibition.R"); source("R/dunnett_fw.R")
d <- readr::read_csv("inst/extdata/example_fw.csv", show_col_types = FALSE)
ck_mean <- mean(d$fresh_weight_g[d$treatment == "CK"])
d$inhibition_pct <- inhibition_pct(d$fresh_weight_g, ck_mean)
dunnett_fw(d)
```

Inference prefers **fresh weight + Dunnett vs CK** (not a pile of uncorrected t-tests on % inhibition).

## Asymmetric design (`--design=asymmetric`)

Use when the sheet is **wide**: one no-dose control column plus several dilution / treatment columns (unequal to a single paired T1/T2 block).

**Wide schema**

| rep | CK | dose_1x | dose_0.5x | dose_0.25x |
|-----|----|---------|-----------|------------|
| 1   | 鈥? | 鈥?      | 鈥?        | 鈥?         |

- `--control=CK` names the no-dose column (also the Dunnett reference level after flatten).
- Pipeline: **flatten 鈫?inhibition % vs CK mean 鈫?Dunnett on fresh weight vs control 鈫?HTML**.

**One command**

```bash
Rscript exec/fw-ck-report.R --design=asymmetric --control=CK \
  --input=inst/extdata/example_fw_asymmetric.csv --out=fw-ck-report.html
```

**In R**

```r
source("R/inhibition.R"); source("R/dunnett_fw.R")
source("R/asymmetric.R"); source("R/report.R")
raw <- readr::read_csv("inst/extdata/example_fw_asymmetric.csv", show_col_types = FALSE)
res <- run_asymmetric(raw, control = "CK")
res$dunnett
render_fw_report(
  "inst/extdata/example_fw_asymmetric.csv",
  out_html = "fw-ck-report.html",
  design = "asymmetric",
  control = "CK"
)
```

Long CSV (`rep,treatment,fresh_weight_g`) still works with `--design=long` (default).

## Example

A pot trial came in with fresh-weight vs CK but no Dunnett plan. `fw-ck-report` turned the CSV into an inhibition table + one-page HTML; the paid seat was a written call on whether the design was report-ready鈥攏ot running the analysis for them.

## Support this project

`fw-ck-report` is free and open source. If it saves you time turning pot fresh-weight into inhibition vs CK with Dunnett, consider supporting continued maintenance.

- **Lab / Team seats** 鈥?paid setup judgment and a written receipt within an agreed window (**inquire via [GitHub Issues](https://github.com/Mingdavid001/fw-ck-report/issues)**; label the issue `seat-inquiry`)
- **Sponsors** 鈥?planned once payout region or a fiscal host is available; tiers below are the intended ladder
- **Not included** 鈥?custom pipelines, private forks, or "run the analysis for me"

Cite the repo; file reproducible issues when you can.

### Intended Sponsors tiers

| Tier | Intent |
|------|--------|
| Supporter | Buy the maintainer a coffee. Keeps `fw-ck-report` maintained. |
| Lab | Priority triage for one lab. Reproducible pot-trial reports get first response. |
| Team | Named contact window + monthly office hour. Judgment on Dunnett setup/config鈥攏ot unpaid consulting. |

### Pricing

You pay for a written call on whether this CK table is report-ready鈥攏ot for hours of analysis.

- **Lab seat:** ~鈧?90 / seat / year (anchor: [Datanovia Teams](https://www.datanovia.com/pricing)) 鈥?inquire via Issues (`seat-inquiry`)
- **Institutional:** see [COMMERCIAL.md](COMMERCIAL.md)

## License

MIT 鈥?see [LICENSE](LICENSE). Institutional commercial use: [COMMERCIAL.md](COMMERCIAL.md).

## Status

MVP: long + asymmetric (`--design=asymmetric`) flatten 鈫?inhibition 鈫?Dunnett 鈫?HTML (v0.0.2). Pricing wall live (inquiry path). GitHub Sponsors enrollment when payout is available.

