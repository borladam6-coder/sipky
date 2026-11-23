# Šipky – počítadlo

Počítadlo skóre pro šipky (X01, Cricket, Count Up), profily, týmy, statistiky a zadávání hlasem.
Statická PWA + jedna Netlify funkce (`netlify/functions/prepis.mjs`) pro přepis hlasu.

## Hlas (přepis přes Whisper na Groq)
Na Netlify nastav proměnnou prostředí `GROQ_API_KEY` (Site configuration → Environment variables).
Bez klíče aplikace použije rozpoznávání řeči v prohlížeči nebo diktování klávesnicí.
