# SCREEN_FLOW_V1

## Regel
Stilp v1 må kun have de skærme, der direkte støtter hurtig skitse, lokal lagring, manuel pakkeliste og eksport.

Ingen skjulte flows til komponenter, BOM, backend eller kataloger.

## Skærm 1 — Projektliste
Formål:
- vise lokale projekter
- oprette ny opgave
- åbne eksisterende opgave
- slette eller duplikere opgave

Handlinger:
- Ny opgave
- Åbn opgave
- Slet opgave

## Skærm 2 — Ny opgave
Formål:
- oprette en ny opgave med minimal friktion

Felter:
- Opgavetype
- Noter

Handlinger:
- Start uden planvisning
- Start med planvisning

## Skærm 3 — Planvisning
Formål:
- tegne bygningens form oppefra
- registrere flere sider på en enkel måde

Handlinger:
- opret hjørner
- træk hjørner
- indtast længde pr. side
- vælg sidetype: langside, gavl, andet
- indtast tagfodshøjde pr. side
- indtast kiphøjde pr. side
- generér facader fra plan

Bemærkning:
Planvisning er geometrisk. Ingen komponent- eller BOM-logik.

## Skærm 4 — Facadeeditor
Formål:
- generere og redigere én facade ad gangen

Handlinger:
- vælg facade
- angiv antal sektioner
- angiv standardbredde
- angiv antal etager
- angiv standardhøjde
- angiv ståhøjde på øverste niveau
- generér grid
- træk i linjer for justering
- tilføj/fjern sektioner
- tilføj/fjern etager
- placér markører
- skriv facade-noter

Visuelle lag:
- grid
- topzone
- markører
- mållinjer

## Skærm 5 — Manuel pakkeliste
Formål:
- samle enkel manuel pakkeforberedelse

Handlinger:
- tilføj linje
- redigér linje
- slet linje
- evt. antal og enhed

Bemærkning:
Ingen automatisk udledning fra grid eller markører.

## Skærm 6 — Eksport-preview
Formål:
- kontrollere hvad der skal eksporteres

Indhold:
- opgavetype
- noter
- planvisning
- facadevisninger
- mål
- markører
- manuel pakkeliste

Handlinger:
- eksportér som PDF
- eksportér som billede

## Navigation
Tilladt hovednavigation:
1. Projektliste
2. Ny opgave
3. Planvisning
4. Facadeeditor
5. Manuel pakkeliste
6. Eksport-preview

Ikke tilladt i v1:
- katalogskærme
- komponentvælger
- BOM-preview
- backend-status
- brugerlogin
- cloud-dialoger
