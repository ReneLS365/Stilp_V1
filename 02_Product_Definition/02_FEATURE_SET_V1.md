# Stilp Feature Set v1

## In scope

### Opgave
- opret opgave
- vælg opgavetype
- skriv noter

### Planvisning
- tegn bygningens form oppefra
- opret flere sider/vægge
- indtast sidelængder
- markér side som gavl eller langside
- angiv tagfodshøjde
- angiv kiphøjde når relevant

### Facadevisning
- generér facadegrid
- antal sektioner/fag
- standard bredde pr. sektion
- antal etager
- standard højde pr. etage
- redigér enkelte sektioner
- redigér enkelte etager
- træk i linjer for hurtig justering
- ståhøjde på øverste niveau
- automatisk topzone på 1000 mm over øverste ståhøjde

### Visuelle markører
- konsoller
- skråstivere
- stigedæk
- åbninger
- tekstnoter

### Pakkeliste
- manuel pakkeliste
- frie tekstlinjer
- antal pr. linje
- evt. enhed pr. linje

### Lagring og eksport
- lokal gem
- lokal åbning
- lokal redigering
- PDF eksport
- billedeksport

## Out of scope
- automatisk komponentvalg
- automatisk BOM
- producentkataloger
- BOSTA-runtime-logik
- pris og akkord
- backend og API
- cloud sync
- brugerlogin
- teknisk validering
- sikkerhedsvalidering
- CSV/Excel-eksport
- AI-funktioner

## Open later, not now
- genbrug af skabeloner
- flere eksportlayouts
- deling af projekter
- simpel versionshistorik
- projektarkiv på tværs af enheder

## Hård regel
Enhver ny feature skal bestå denne test:

"Gør den skitsen hurtigere og mere brugbar uden at indføre komponentlogik, backend eller BOM?"

Hvis nej, så skal den ikke med i v1.
