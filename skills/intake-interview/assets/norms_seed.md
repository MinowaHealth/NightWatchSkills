# Health Monitoring Norms

**Version:** {{DATE}} · created at intake
**Supersedes:** — (first version)

Standing instructions for reading this person's data. Read this before interpreting anything or
writing any narrative.

This document is stored as a dated version. Each correction produces a new dated document; earlier
versions remain retrievable. Each rule carries the date it entered the document, so its age is visible
without diffing back through versions.

## Data-source quirks

*(These apply to everyone and ship with the product — they are not personal to this user.)*

- Garmin sleep **scoring lags the upload**, sometimes by hours, and short episodes often lack
  enough data to be scored at all. Unscored stretches are NOT "no sleep" — infer rest from the
  heart-rate decline and the observation log, and note that re-analysis later may fill it in. *(seeded)*
- **Respiratory rate depends on the device model — confirm before reading anything into it.** Several
  wearables have no respiration sensor at all, and on those the field is permanently null: that is a
  hardware fact, not a gap, and chasing it wastes a session. Establish at intake whether this person's
  device has the sensor, and record the answer here. *(seeded)*
- Stress is not scored while the wearer is moving, and does not resume the instant movement stops. A
  blank stress stretch that lines up with a non-zero step bucket is that — not missing data, and not
  something a re-sync will recover. *(seeded)*
- Heart rate and stress sample on **offset clocks** — their timestamps do not align. Treat them as
  two separate sparse series, never as paired points. *(seeded)*

## Vocabulary

*(none recorded yet)*

## Sequences and causation

*(none recorded yet)*

## Symptoms and remedies

*(none recorded yet)*

## Instruments

*(none recorded yet)*

## Baselines

*(none recorded yet)*

## Beliefs under test

*(none recorded yet)*

## Retired

*Rules that no longer apply, kept with the reason. Retired rules are not applied — they are here so
the reasoning survives in the current document rather than only in an old version.*

*(none yet)*
