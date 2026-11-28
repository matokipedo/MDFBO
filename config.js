// MDF back office - connection settings (same Supabase project as the public Lead Farmer Kit).
// Use the *publishable / anon* key only. NEVER put the service_role / secret key here.
// Access is enforced by Row Level Security: only users in the `admin_roles` table can see or change anything.
window.MDFBO_CONFIG = {
  supabaseUrl: "https://osbwuklsslvuaqhbezzc.supabase.co",
  supabaseKey: "sb_publishable_UHvM6rIuT7ejO0DPNBmM-g_3A34DJdY",
  passkeys: true,                                   // set false to hide passkey buttons
  publicSiteUrl: "https://matokipedo.github.io/MDF/" // the Lead Farmer Kit ("View kit" button)
};
