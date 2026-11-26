# MDFBO: MDF back office (private)

For agrodealer technicians and the PROMAS team: indicators, training sessions, demo plots, questions, partners.
Public kit: `matokipedo/MDF`. Supabase project: `osbwuklsslvuaqhbezzc` (linked to this repo).

- Database: `supabase/migrations/20261126000000_mdf_init.sql` (same as `supabase/schema.sql`, which you can paste into the SQL editor instead). Idempotent.
- Setup: `SETUP.md`. Sign-in providers: `SIGNIN.md`. Plot photos: `kobo/`.
- Hosting: Cloudflare Pages (free GitHub can't serve a private repo on Pages) → `mdfbo.pages.dev`.
