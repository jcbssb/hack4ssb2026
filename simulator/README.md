# Simulator (Foreldet / Deprecated)

Denne mappen inneholder tidlige statiske HTML/JS-prototyper fra hackathon-fasen (`simulator/index.html` og visualiseringer).

## Offisiell og aktiv simulator

Den aktive og fullverdige simulatoren for Dialogue Schema DSL er nå plassert i søsken-repositoriet:

👉 **[skjemantikk-simulator](../../skjemantikk-simulator/)** (`http://localhost:5173/`)

### Egenskaper i `skjemantikk-simulator`:
- Bygget med **React**, **Vite** og **DigDir Designsystemet** (`@digdir/designsystemet-react`).
- Full støtte for alle versjoner av Byggesak (Trial 1–9), Kostra 51 og syntetiske testskjemaer.
- Interaktive matrisetabeller (`MatrixTable`), dynamisk beregningsevaluering i sanntid og valideringsregler.
- Tett integrert med **Skjemakart** (`tools/skjemakart/`), inkludert dyp-lenking til bolker og spesifikke felter med fokus og puls-animasjon.
