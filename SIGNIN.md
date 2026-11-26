# Back-office sign-in (standard screen)

0. Supabase → Authentication → URL Configuration: Site URL + Redirect URLs = the deployed back office address. Sign In / Providers → turn on "Allow manual linking".
- Callback URL for every provider: `https://<project-ref>.supabase.co/auth/v1/callback`

| Provider | Cost | Where |
|---|---|---|
| Email + password | free | on by default |
| Google | free | Google Cloud console → OAuth client (Web) |
| Microsoft | free | Azure portal → App registrations (provider `azure`) |
| Yahoo | free | Custom OIDC provider, issuer `https://api.login.yahoo.com` (free plan: 3 custom providers) |
| Apple | US$99/yr | Apple Developer; the secret must be renewed at least every 6 months |
| Passkeys | free (beta) | Authentication → Passkeys. RP ID = bare deployed domain (e.g. `mdfbo.pages.dev`). Set once: changing it breaks every passkey |

Buttons for providers that aren't switched on explain themselves instead of breaking. After the first admin exists, turn public sign-ups OFF so a stray OAuth/passkey sign-in can't create accounts. New staff: create their user in Supabase → Authentication, then the owner gives them a role (`select set_admin_role('<uuid>','editor');` in SQL, run as the owner).

Quick check: Google button with Google off → plain note; Forgot password with no email → asks for it; recovery link → "Choose a new password".
