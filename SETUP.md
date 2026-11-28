# MDF setup (free tools only)

Think of it as setting up a sound system for a new venue: plug in the mixer (Supabase), run cables to both decks (keys), put the decks on stage (hosting), then sound-check.

1. **Supabase project (the mixer).** supabase.com → New project "MDF" (free plan: max 2 active projects per org). SQL Editor → open `supabase/schema.sql`, copy its *contents*, paste, Run. Running it twice is safe.
2. **Keys (the cables).** Project Settings → API: copy the Project URL and the anon/publishable key into the kit's `index.html` and into `config.js` here (already filled in for project osbwuklsslvuaqhbezzc). The anon key is public by design. Never paste the service-role key.
3. **Repos.** Create `MDF` (public, Pages on, branch `main`, root) and `MDFBO` (private) under the agreed GitHub owner.
4. **Host the back office.** Free GitHub can't serve a private repo on Pages, so use Cloudflare Pages: Workers & Pages → Create → Pages → Import Git repo (only `MDFBO`) → branch `main`, no build command, output `/`. You get `mdfbo.pages.dev`.
5. **Auth URLs.** Supabase → Authentication → URL Configuration: Site URL = `https://mdfbo.pages.dev`, Redirect URLs = the same with `/**`. Watch for stray characters. Sign in once with email + password, open *First-time setup* and press **Claim owner** (works once). Then switch public sign-ups OFF.
6. **Plot photos (KoboToolbox, free for NGOs).** kf.kobotoolbox.org → New → Upload XLSForm → `kobo/dfles_plot_observation.xlsx` → Deploy. Technicians use the KoboCollect Android app offline. Export CSV and import into `plot_observations` (Table editor → Import) each fortnight.
7. **WhatsApp.** One WhatsApp Business number per technician (free app). Lead farmers put that number under "Eu / Me" in the kit; the kit's Help and Photo buttons open the chat directly.
8. **Lead farmer phones.** Open the public URL in Chrome → menu → *Add to Home screen*. Open each lesson once with signal so its media is cached; after that it works offline.
9. **Sound-check.** Finish one lesson on a phone, see it under Sessions and Pipeline health, then delete it.

10. **Team (1.3.0).** Paste `supabase/migrations/20261127000000_team_by_email.sql` into the SQL editor and Run. Then Settings → Team lets the owner add technicians by email.
