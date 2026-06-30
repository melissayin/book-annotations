# Marginalia — starter prototype

A single static page (`index.html`) plus a database schema (`schema.sql`). No build step,
no server to run yourself — Supabase is your backend, GitHub Pages hosts the page.

Why this combo: GitHub Pages only serves static files, it can't store data or know who's
signed in. Supabase fills that gap — free hosted Postgres database, login, and
permissions — without you having to run your own server.

## 1. Create the backend (10 min)

1. Go to supabase.com, sign up, and create a new project (pick any name/region, free tier
   is plenty to start).
2. In the project dashboard, open **SQL Editor → New query**, paste in the contents of
   `schema.sql`, and run it. This creates the tables and the permission rules that decide
   who can see which comments.
3. Open **Authentication → Providers** and make sure **Email** is enabled (it is by
   default). This gives you magic-link sign-in with no password to manage.
4. Open **Settings → API**. Copy the **Project URL** and the **anon public** key.

## 2. Wire up the frontend

Open `index.html` and replace these two lines near the top of the `<script>` block:

```js
const SUPABASE_URL = 'https://YOUR-PROJECT-REF.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR-ANON-PUBLIC-KEY';
```

with the values you copied. That's the only edit required to get it running locally —
just open `index.html` in a browser.

## 3. Deploy to GitHub Pages

1. Create a new GitHub repo and push `index.html` to it (you don't need `schema.sql` or
   this README in the deployed site, but it's fine to leave them in the repo).
2. In the repo, go to **Settings → Pages**, set **Source** to your main branch, root
   folder, and save.
3. GitHub gives you a URL like `https://yourname.github.io/yourrepo/` — that's your live
   app. Anyone with the link can sign in and start commenting.

## How it works right now

- A reader signs in with email (magic link, no password).
- They type the title of the book they're reading. If someone else already created that
  book, they land on the same comment thread; otherwise a new one is created.
- To comment, they paste the line or two they're reacting to, estimate how far into the
  book they are as a percent, and write their thought. There's a checkbox for "end of
  chapter" thoughts so those can be styled and found separately.
- Comments are sorted by position percent, so scrolling the feed roughly mirrors
  scrolling through the book.
- Visibility (everyone vs. one book club) is enforced by the database itself (the row
  level security policies in `schema.sql`), not by the frontend — so there's no way for
  the page's JavaScript to accidentally leak a group's comments to someone outside it.

## What's deliberately not built yet

- **Calibration by page count / percent, and assisted pacing** — right now the reader
  just types a percent by hand. The page-count math (`current page ÷ total pages`) is a
  small bit of arithmetic to add to the position field once this works end to end.
- **Photo-snap calibration** — saved for later, as discussed.
- **Split-screen polish** — this works fine today as a second window or a second app in
  split view on a tablet; no special code is needed for that, it's just how the browser
  window behaves.
- **Duplicate book matching** — right now two slightly different title spellings create
  two separate books. Fine for testing with a small group; worth a real search/matching
  step before opening this up more widely.

## Suggested next step

Get 3-5 people reading the same book to actually use this for a week. The two things to
watch: whether the percent-position estimate feels close enough that comments show up
near "where they are," and whether typing the excerpt by hand is too much friction. Both
are cheap to learn from a real test and expensive to guess about.
