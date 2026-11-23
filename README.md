# Šipky – počítadlo

Počítadlo skóre pro šipky (X01, Cricket, Count Up): profily, týmy, statistiky, zadávání čísly nebo ťukáním do terče.
Statická PWA na Netlify. Volitelně sdílená **kancelář** přes Supabase: víc telefonů zapisuje do jedné hry a všichni vidí stav živě.

## Sdílená kancelář – jednorázové založení (asi 10 minut)

1. **Účet a projekt.** Na [supabase.com](https://supabase.com) se přihlas (např. přes GitHub) a dej *New project*:
   název `sipky`, region **Central EU (Frankfurt)**, tarif **Free**. Heslo k databázi si ulož, aplikace ho nepotřebuje.
2. **Tabulky.** V projektu otevři *SQL Editor → New query*, vlož celý obsah souboru
   [`supabase/schema.sql`](supabase/schema.sql) a klikni *Run*. Má skončit hláškou *Success*.
   Skript jde bezpečně spustit i znovu.
3. **Přihlašování bez účtu.** *Authentication → Sign In / Providers →* zapni **Allow anonymous sign-ins** a ulož.
   Telefony se pak přihlásí samy na pozadí, nikdo nic nevyplňuje.
4. **Adresa a klíč.** V *Project Settings → Data API* zkopíruj **Project URL** (`https://….supabase.co`)
   a v *Project Settings → API Keys* **Publishable key** (`sb_publishable_…`).
   Publishable key je veřejný z principu (data chrání pravidla v databázi). **Secret key nikam nedávej.**
5. **Kancelář založíš jen ty** v *SQL Editoru*: `insert into public.offices(code) values ('TVUJKOD');`
   (8–12 velkých písmen/číslic). Z aplikace kancelář založit nejde, takže si nikdo cizí ve tvé databázi nic nezaloží.
6. **Telefony.** V aplikaci *Hráči → Připojit kancelář* → kód → **Připojit**. Po připojení aplikace nabídne nahrání hráčů a zápasů z telefonu
   (hráči se stejným jménem se spojí).

Až budou adresa a klíč doplněné přímo v `index.html` (`CLOUD_URL`, `CLOUD_KEY`), stačí na telefonech zadat jen kód.

### Jak to funguje
- Každá šipka je řádek v tabulce `throws` s pořadovým číslem. Stav hry se na každém telefonu přepočítá ze šipek,
  takže všichni vidí totéž. Změny chodí živě (Supabase Realtime), jinak se stav obnovuje každých 5 s.
- Když dva telefony zapíšou stejnou šipku, uloží se první a druhý se zeptá: *zapsat jako další*, nebo *zahodit*.
- Bez internetu se hody ukládají do fronty v telefonu a po připojení se odešlou za hody z ostatních telefonů.
- *Zpět* funguje z kteréhokoli telefonu; šipka se nesmaže, jen označí jako vrácená.
- Automat v GitHub Actions (`.github/workflows/supabase-keepalive.yml`) každé 3 dny zapíše do tabulky `heartbeat`,
  aby bezplatný projekt neusnul. Kdyby přesto hrozilo uspání, Supabase předem pošle e-mail.

## Hlas (přepis přes Whisper na Groq)
Na Netlify nastav proměnnou prostředí `GROQ_API_KEY` (Site configuration → Environment variables).
Bez klíče aplikace použije rozpoznávání řeči v prohlížeči nebo diktování klávesnicí.
