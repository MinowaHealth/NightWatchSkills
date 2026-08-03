# Health Monitoring Norms

Accumulated inference corrections for the health episode reports. Read this **before** writing any
narrative. These are inferences that have had to be corrected repeatedly — state them plainly rather
than re-deriving them each time. This file only grows; append new corrections as they are made.

> This is the committed **template**. Copy to `HealthMonitoringNorms.md` (gitignored in a public repo)
> and let it accumulate your own corrections. The headings below show the intended shape; the bullets
> are illustrative placeholders — replace with your own.

## Sequences and causation
- <A logged input> has an onset lag; read <input → physiological change → outcome> as one linked
  chain, not separate observations. Demonstrate the lag from the data, not from assumption.
- <Some supplement>: report only as a plain logged fact (taken at time X). Draw NO causal linkage to
  what follows.
- Actual sleep is evident from the heart-rate trace, not self-report. Don't hedge if the HR shows it.

## Symptoms and remedies
- <Symptom> is a symptom, not a neutral state. Its remedy is <step 1>, then <step 2> only if step 1
  fails — so "skipped step 2" means step 1 sufficed and must not be framed as therapeutic.

## Blood pressure
- If there are multiple physical meters, treat them as **separate datasets — never merge**. Note which
  meter reads high and under what posture. Discard a reading only when it is BOTH anomalously high
  within its own meter's set AND symptom-inconsistent; judge within-meter, never across meters.

## Data-source quirks (not inferences — avoid mis-reading them as findings)
- Garmin sleep scoring lags the upload; a window analyzed soon after a morning sync may be unscored.
  Infer rest from the HR decline and note that scoring may fill in on re-run.
- Respiratory-rate samples are frequently absent from daytime windows; note the gap, don't read
  meaning into it.

## Reporting stance
- Keep the narrative small. Don't speculate beyond what these norms and the data support.
- Write in the user's voice. Clinical precision, no hedging.
