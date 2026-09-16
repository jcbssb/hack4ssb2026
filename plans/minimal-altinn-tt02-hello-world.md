# Plan: Minimal "Hello World" Skjema på Altinn TT02

**Formål**: Opprette og deploye et minimalt Altinn 3-skjema i testmiljøet (TT02) som kun ber om ett felt: **Hackday Team Name** (`teamName`).  
**Miljø**: Altinn TT02 (`tt02.altinn.no` / `ssb.apps.tt02.altinn.no`)  
**Målgruppe**: Team Foran Skjema (SSB Hackday 2026)

---

## 1. Tokenanalyse & Forutsetninger (Rolle- og Kapasitetssjekk)

Før man oppretter eller interagerer med en app på TT02, må man verifisere hva det tilgjengelige `ALTINN_TOKEN` gir tilgang til.

### 1.1 Dekode og inspisere JWT
Et Altinn-token er en standard JWT (JSON Web Token). Kjør en lokal inspeksjon (uten å sende tokenet til eksterne tjenester):
```bash
# Dekode JWT payload lokalt via python
python3 -c "
import sys, json, base64
token = sys.argv[1].strip()
payload = token.split('.')[1]
# Fix padding
payload += '=' * (-len(payload) % 4)
print(json.dumps(json.loads(base64.urlsafe_b64decode(payload)), indent=2))
" "$ALTINN_TOKEN"
```

### 1.2 Nøkkelfelter og hva de betyr
- `iss` (Issuer): Bør være `https://platform.tt02.altinn.no/authentication/api/v1/openid/` eller Maskinporten TT02.
- `scope`:
  - `altinn:serviceowner` (kreves for eierskap/deploys/spesielle APIer som SSB org).
  - `altinn:instances.read`, `altinn:instances.write` (for instansiering og skjemautfylling).
- `consumer` / `urn:altinn:org`: Organisasjonsnummer for aktøren som eier tokenet (f.eks. SSB).
- `urn:altinn:partyid` / `urn:altinn:userid`: PartyID eller Bruker-ID tokenet agerer på vegne av.

### 1.3 Verifisere mot Altinn TT02 API
Test tokenet direkte mot profil/party-endepunktet i TT02:
```bash
curl -s -H "Authorization: Bearer $ALTINN_TOKEN" \
  "https://platform.tt02.altinn.no/authorization/api/v1/parties/current" | jq .
```
- **Svar 200 OK**: Viser hvilket `partyId`, `orgNumber` eller brukernavn du er logget inn som.
- **Svar 401**: Ugyldig eller utløpt token.
- **Svar 403**: Manglende rettigheter / feil miljø.

---

## 2. Minimalt App-oppsett ("Hello World")

Et Altinn 3 skjema krever minimalt fire kjerneelementer:
1. `applicationmetadata.json` (definerer app-id, tittel og datamodell/layout-kobling)
2. Datamodell (`schema.json` eller XSD)
3. UI Layout (`App/ui/layouts/Form.json` og `layout-settings.json`)
4. Tekstressurser (`App/config/texts/resource.nb.json`)

### 2.1 Datamodell (`App/models/team-model.schema.json`)
Definerer det enkle datagrunnlaget med kun ett felt:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "HackdayTeamModel",
  "type": "object",
  "properties": {
    "teamName": {
      "type": "string",
      "title": "Hackday Team Name"
    }
  },
  "required": ["teamName"]
}
```

### 2.2 UI Layout (`App/ui/layouts/Form.json`)
Definerer skjermbildet med ett `Header` og ett `Input`-felt:
```json
{
  "$schema": "https://altinncdn.no/schemas/json/layout/layout.schema.v1.json",
  "data": {
    "layout": [
      {
        "id": "header-1",
        "type": "Header",
        "size": "L",
        "textResourceBindings": {
          "title": "appName"
        }
      },
      {
        "id": "team-name-input",
        "type": "Input",
        "textResourceBindings": {
          "title": "teamNameLabel"
        },
        "dataModelBindings": {
          "simpleBinding": "teamName"
        },
        "required": true
      }
    ]
  }
}
```

### 2.3 Tekstressurser (`App/config/texts/resource.nb.json`)
```json
{
  "language": "nb",
  "resources": [
    {
      "id": "appName",
      "value": "SSB Hackday 2026 - Registrering"
    },
    {
      "id": "teamNameLabel",
      "value": "Hva er navnet på ditt Hackday Team?"
    }
  ]
}
```

### 2.4 App metadata (`App/config/applicationmetadata.json`)
Knytter sammen org, app-navn og datatyper:
```json
{
  "id": "ssb/hack4ssb-hello",
  "org": "ssb",
  "title": { "nb": "Hackday Team Registrering" },
  "dataTypes": [
    {
      "id": "ref-data-as-provided",
      "allowedContentTypes": ["application/json"],
      "appLogic": {
        "classRef": "Altinn.App.Models.HackdayTeamModel"
      },
      "maxCount": 1,
      "minCount": 1
    }
  ]
}
```

---

## 3. Deployment & Kjøring på TT02

Det finnes to måter å deploye et minimalt Altinn 3 skjema til TT02:

### Alternativ A: Via Altinn Studio (Raskest & Anbefalt for Hackday)
1. Logg inn på [Altinn Studio TT02](https://altinn.studio).
2. Opprett ny app under organisasjon `ssb` (f.eks. `hack4ssb-hello`).
3. Lim inn layout/datamodell eller bruk visuell designer.
4. Klikk **Publiser / Deploy** til testmiljø (`TT02`).
5. Appen blir tilgjengelig på: `https://ssb.apps.tt02.altinn.no/ssb/hack4ssb-hello/`

### Alternativ B: Git Repository & GitHub Actions / Altinn CLI
1. Klon app-repoet fra Altinn Studio Gitea / GitHub.
2. Push koden med filene spesifisert i seksjon 2.
3. Utløs deploy-pipeline til TT02 (krever deploy-rettigheter for org i Altinn Studio).

---

## 4. Teste Instansiering og Innsending (Verifikasjon)

Når appen er deployet på `ssb.apps.tt02.altinn.no/ssb/hack4ssb-hello`:

1. **Åpne i nettleser**:
   - Gå til `https://ssb.apps.tt02.altinn.no/ssb/hack4ssb-hello/`
   - Logg inn med en syntetisk testbruker i TT02 (Tenor-testbruker).
   - Skriv inn teamnavn (f.eks. "Foran Skjema") og send inn.

2. **Eller instansiere programmatisk via API**:
   ```bash
   curl -X POST "https://ssb.apps.tt02.altinn.no/ssb/hack4ssb-hello/instances" \
     -H "Authorization: Bearer $ALTINN_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "instanceOwner": {
         "organisationNumber": "991825827"
       }
     }'
   ```
3. **Bekrefte dataelement**:
   - Verifiser at instansen ble opprettet og at data-elementet inneholder:
     `{"teamName": "Foran Skjema"}`.
