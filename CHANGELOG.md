# Changelog

## 1.0.0 (2026-11-25)
- First draft of the DFLES Twin Deck pair: offline Lead Farmer Kit (maize, 5 modules, 6-step flow, PT/EN), back office (indicators, sessions, plots, questions, partners, settings), Supabase schema with RLS, rate limit and sample flags.

## 1.2.0 (2026-11-26)
- Photos & videos tab: field uploads grouped by demo plot, module and step, with signed links (1 h), filters, and Good / Needs help / Hide review.
- Migration 20261126020000_step_media.sql: step_media table + private step-media bucket (anon upload-only, admins view). Tested on Postgres 16 with a storage stub.

## 1.3.0 (2026-11-27)
- New look and layout taken from the house back-office template: sticky header with icon, version tag, Auto/Light/Dark + Warm buttons, View kit and Sign out; underlined tab bar with badges (open questions, new photos); version footer.
- Overview rebuilt in the insight-page format: window picker (7 days to season), six key-metric tiles with change vs the previous period and daily sparklines, highlights (strongest and weakest module, busiest district, questions waiting, photos to review), learning by module, still-to-measure indicators, top lead farmers and villages, pipeline health, CSV export.
- Sign-in screen with provider logos, passkeys, reset password; first owner is now claimed with an explicit button instead of automatically.
- Answers and review notes use an in-page box instead of browser pop-ups; toasts replace alerts.
- Settings: Team card (owner adds people by email as viewer, editor or owner), sign-in methods with passkeys, safety checklist.
- Connection settings moved to config.js; supabase-js loads with an integrity hash.
- Migration 20261127000000_team_by_email.sql: admin_grant(email, role) and admin_team(). Tested on Postgres 16 (supabase/tests/team_test.sql).
