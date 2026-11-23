# Šablona motivu terče

Motiv je krátký text ve formátu **JSON**: jen barvy a pár voleb.
Vytvoříš ho sám, nebo ho necháš vymyslet jinou AI (ChatGPT, Gemini, Claude…).
V aplikaci ho pak vložíš přes **+ VLASTNÍ** → vložit → **Použít motiv**.

Do motivu nejde dát obrázek ani kód, jen barvy. Když bude nějaká barva špatně, aplikace ji nahradí výchozí a řekne ti kterou.

## Prompt pro jinou AI (zkopíruj celý)

```
Navrhni barevný motiv terče na šipky pro mobilní aplikaci. Téma: <SEM NAPIŠ TÉMA, např. „Halloween“, „Sparta Praha“, „vesmír“, „retro 80. léta“>.

Terč má od středu: střed BULL (dvě barvy: vnější kruh 25 a vnitřní 50), široký kruh SINGLE, užší kruh TRIPLE, vnější kruh DOUBLE.
Každý kruh má 20 výsečí, které se střídají dvěma barvami (sudé/liché výseče). Na každé výseči je číslo (např. „20“, „T20“, „D20“), takže písmo musí být dobře čitelné proti barvě výseče.

Odpověz POUZE jedním blokem JSON přesně v tomto formátu, bez komentářů:

{
  "name": "Název motivu (max 24 znaků)",
  "single": ["#barva sudých výsečí", "#barva lichých výsečí"],
  "double": ["#barva", "#barva"],
  "triple": ["#barva", "#barva"],
  "labels": { "singleDark": "#písmo na sudých single", "singleLight": "#písmo na lichých single", "double": "#písmo na double", "triple": "#písmo na triple" },
  "wire": { "color": "#barva drátků", "width": 1.2, "metal": "silver | gold | none" },
  "rim": "#barva okraje terče",
  "bull": { "outer": "#barva 25", "inner": "#barva 50", "label": "#písmo BULL" },
  "glow": null,
  "texture": "none | sisal | carbon | brushed",
  "shade": true,
  "edge": null,
  "highlight": "#barva zvýraznění při ťuknutí",
  "dots": { "on": "#tečka šipky, která se ještě hází", "off": "#tečka hozené šipky" }
}

Pravidla:
- Barvy jen jako #RRGGBB nebo rgba(r,g,b,a).
- „glow“ je buď null, nebo { "double": "#barva", "triple": "#barva" } pro svítící (neonové) obrysy.
- „edge“ je buď null, nebo barva tenkého lemu kolem terče.
- „width“ drátků 0–4 (0 = bez drátků).
- Kontrast písma proti výseči aspoň 4,5 : 1, aplikace má tmavé pozadí.
```

## Popis polí

| Pole | Co dělá |
| --- | --- |
| `name` | název motivu v aplikaci |
| `single`, `double`, `triple` | dvojice barev, výseče se střídají (výseč 20 nahoře používá první barvu) |
| `labels` | barvy čísel na výsečích |
| `wire` | drátky mezi poli: barva, tloušťka, kovový lesk `silver` / `gold`, nebo `none` |
| `rim` | černý (nebo jiný) okraj kolem terče |
| `bull` | střed: vnější kruh (25), vnitřní (50), barva nápisu |
| `glow` | neonové svítící obrysy double a triple, nebo `null` |
| `texture` | `sisal` (vlákna jako skutečný terč), `carbon`, `brushed` (broušený kov), `none` |
| `shade` | jemné stínování do hloubky (`true` / `false`) |
| `edge` | lem kolem terče, nebo `null` |
| `highlight` | barva zvýraznění pole a štítku při ťuknutí |
| `dots` | barvy teček šipek v kole |

## Příklad (motiv Turnaj)

```json
{
  "name": "Turnaj",
  "single": ["#141414", "#EADFC4"],
  "double": ["#C62A35", "#16824A"],
  "triple": ["#C62A35", "#16824A"],
  "labels": { "singleDark": "#EADFC4", "singleLight": "#141414", "double": "#FFFFFF", "triple": "#FFFFFF" },
  "wire": { "color": "#C0C6CE", "width": 1.1, "metal": "silver" },
  "rim": "#0D0E11",
  "bull": { "outer": "#16824A", "inner": "#C62A35", "label": "#FFFFFF" },
  "glow": null,
  "texture": "sisal",
  "shade": true,
  "edge": null,
  "highlight": "#FFD400",
  "dots": { "on": "#FFD400", "off": "#3A3D46" }
}
```
