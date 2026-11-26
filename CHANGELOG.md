# Changelog

## 1.0.0 (2026-11-25)
- First draft of the DFLES Twin Deck pair: offline Lead Farmer Kit (maize, 5 modules, 6-step flow, PT/EN), back office (indicators, sessions, plots, questions, partners, settings), Supabase schema with RLS, rate limit and sample flags.

## 1.2.0 (2026-11-26)
- Photos & videos tab: field uploads grouped by demo plot, module and step, with signed links (1 h), filters, and Good / Needs help / Hide review.
- Migration 20261126020000_step_media.sql: step_media table + private step-media bucket (anon upload-only, admins view). Tested on Postgres 16 with a storage stub.
