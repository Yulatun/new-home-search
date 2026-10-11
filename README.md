# Apartment Shortlist (website version)

A static page (`index.html` + `config.js`) hosted on Vercel, with data and sign-in from Supabase.
Only the two emails you put in the database can open it. Ratings stay hidden from each other
until both of you have rated, and the database itself enforces that.

## 1. Supabase (database and sign-in) — about 10 minutes

1. Create a free account at supabase.com and a **New project** (region: Frankfurt or Stockholm is closest to Vilnius). Save the database password somewhere; you won't need it for this app.
2. Open **SQL Editor** → **New query**. Paste all of `supabase/schema.sql`.
   At the bottom, replace the two example emails and names with yours and your husband's (lowercase emails). Press **Run**.
3. New query again: paste `supabase/seed.sql` and press **Run**. This copies your 6 apartments from the Claude version (ratings start empty).
4. **Project Settings → API**: copy the **Project URL** and the **anon public** key into `config.js`.

## 2. Vercel (hosting)

Either:

- **Drag and drop:** in Vercel, **Add New → Project**, choose to deploy without Git if offered, and upload this folder. Framework preset: **Other**, no build command, output directory: the folder root.
- **Command line:** in this folder run `npx vercel` and then `npx vercel --prod`.
- **GitHub:** push this folder to a repository and import it in Vercel (preset **Other**).

Note the address Vercel gives you, for example `https://apartment-shortlist.vercel.app`.

## 3. Connect the two

In Supabase, **Authentication → URL Configuration**:

- **Site URL:** your Vercel address.
- **Redirect URLs:** add the same address.

Without this, the sign-in links in the emails point to the wrong place.

## 4. Use it

Open the Vercel address, enter your email, and open the link Supabase sends you on the same device.
Send your husband the address; he signs in the same way with his email.

## Good to know

- **Free-tier limits:** Supabase pauses a free project after about a week with no visits. Opening the dashboard and pressing **Restore** brings it back with the data intact. The built-in email sender only allows a few sign-in emails per hour, which is plenty for two people.
- **Adding someone later:** add a row to the `members` table (Table Editor). Remove a row to take access away.
- **Changing the page:** edit `index.html` and deploy again. The data lives in Supabase, so redeploying never touches it.
- **Running `schema.sql` twice:** it is mostly safe to re-run, but the `alter publication` line will complain that the tables are already added. You can ignore that error.
