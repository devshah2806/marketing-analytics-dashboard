# marketing-analytics-dashboard
Cross-channel paid media dashboard unifying Facebook, Google, and TikTok advertising data — January 2024

# Cross-Channel Marketing Analytics Dashboard

A unified paid media performance report for January 2024, integrating advertising data across Facebook, Google Ads, and TikTok into a single analytical view.

**Live Dashboard:** https://devshah2806.github.io/marketing-analytics-dashboard

---

## What's in this repo

| File | Description |
|------|-------------|
| `index.html` | Self-contained interactive dashboard |
| `unified_data_model.sql` | PostgreSQL schema — source tables, unified table, analytical views |

---

## Data Model

Three platform-specific source tables are normalized into a single `unified_ads` table with derived efficiency metrics (CPA, CTR, CPC, CPM) computed as generated columns.

**Platforms:** Facebook Ads · Google Ads · TikTok Ads  
**Period:** January 1–30, 2024  
**Total records:** 330 rows across 12 campaigns

---

## Key Findings

- Google Search Generic Terms consumed 12% of total budget at a $24.80 CPA — nearly 5× worse than Brand Terms ($5.10). Reallocating that spend would yield an estimated +2,422 conversions at no additional cost.
- Facebook is the most capital-efficient platform (CPA $7.64) despite receiving only 14% of budget.
- TikTok's Influencer Collab campaign holds viewers 37% longer than Awareness_GenZ, with the best full-completion rate (30.4%) in the account.
- Recommended channel strategy: TikTok for awareness → Facebook for retargeting → Google Search to close intent.
