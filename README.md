# fw-ck-report

Open-source helper for **pot-trial fresh weight → inhibition vs CK + Dunnett**, with an optional one-page HTML report.

Free core. Paid seats buy a **written judgment receipt** (is this CK table report-ready?)—not hours of analysis ops.

## Quick start (MVP stub)

```r
# install.packages(c("rstatix", "dplyr", "readr"))
source("R/inhibition.R"); source("R/dunnett_fw.R")
d <- readr::read_csv("inst/extdata/example_fw.csv", show_col_types = FALSE)
ck_mean <- mean(d$fresh_weight_g[d$treatment == "CK"])
d$inhibition_pct <- inhibition_pct(d$fresh_weight_g, ck_mean)
dunnett_fw(d)
```

Inference prefers **fresh weight + Dunnett vs CK** (not a pile of uncorrected t-tests on % inhibition).

## Example

A pot trial came in with fresh-weight vs CK but no Dunnett plan. `fw-ck-report` turned the CSV into an inhibition table + one-page HTML; the paid seat was a written call on whether the design was report-ready—not running the analysis for them.

## Support this project

`fw-ck-report` is free and open source. If it saves you time turning pot fresh-weight into inhibition vs CK with Dunnett, consider supporting continued maintenance.

- **Sponsors** — fund core upkeep and issue triage
- **Priority seats** — paid support for labs who need setup judgment and a written receipt within an agreed window
- **Not included** — custom pipelines, private forks, or “run the analysis for me”

Cite the repo; file reproducible issues when you can.

### Sponsors tiers (draft)

| Tier | Intent |
|------|--------|
| Supporter | Buy the maintainer a coffee. Keeps `fw-ck-report` maintained. |
| Lab | Priority triage for one lab. Reproducible pot-trial reports get first response. |
| Team | Named contact window + monthly office hour. Judgment on Dunnett setup/config—not unpaid consulting. |

### Pricing (draft)

You pay for a written call on whether this CK table is report-ready—not for hours of analysis.

- **Lab seat:** ~€490 / seat / year (anchor: [Datanovia Teams](https://www.datanovia.com/pricing))
- **Institutional:** see [COMMERCIAL.md](COMMERCIAL.md)

## License

MIT — see [LICENSE](LICENSE). Institutional commercial use: [COMMERCIAL.md](COMMERCIAL.md).

## Status

Scaffold / MVP stub (2026-11-03). HTML report wiring and GitHub Sponsors links land next.
