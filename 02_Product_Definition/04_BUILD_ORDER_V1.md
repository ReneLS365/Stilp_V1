# Stilp Build Order v1

## Formål
Byg Stilp i en rækkefølge der aktivt forhindrer scope creep.

## Fase 0 - styring låses
Før kode:
1. MVP scope lock
2. produktdefinition
3. screen flow
4. editor-regler
5. datamodel

Ingen implementering før disse er låst.

## Fase 1 - app-skelet
Byg:
- app shell
- lokal projektmodel
- projektliste
- opret opgave
- noter
- opgavetype

Mål:
Brugeren kan oprette og gemme en tom opgave lokalt.

## Fase 2 - planvisning
Byg:
- plan canvas
- opret sider/vægge
- indtast længder
- markér gavl/langside
- tagfod/kip-felter

Mål:
Brugeren kan tegne huset oppefra og gemme planen.

## Fase 3 - facadegenerering
Byg:
- opret facade pr. side
- facadegrid
- standard sektionbredde
- standard etagehøjde
- generér grid

Mål:
Brugeren kan gå fra plan til facade.

## Fase 4 - direkte redigering
Byg:
- træk i lodrette linjer for sektionsbredde
- træk i vandrette linjer for etagehøjde
- tilføj/fjern sektioner
- tilføj/fjern etager

Mål:
Gridet føles hurtigere end papir.

## Fase 5 - ståhøjde og topzone
Byg:
- input for ståhøjde på øverste niveau
- automatisk topzone 1000 mm over dette niveau

Mål:
Brugeren får en tydelig, visuel topafslutning.

## Fase 6 - markører
Byg:
- konsolmarkør
- skråstivermarkør
- stigedæksmarkør
- åbningsmarkør
- tekstnote

Mål:
Brugeren kan gøre skitsen praktisk brugbar.

## Fase 7 - manuel pakkeliste
Byg:
- simple linjer
- antal
- tekst
- evt. enhed

Mål:
Brugeren kan skrive hvad der skal pakkes uden auto-BOM.

## Fase 8 - eksport
Byg:
- PDF eksport
- billedeksport
- layout med plan, facader, noter og pakkeliste

Mål:
Brugeren kan dele eller printe resultatet.

## Hård rækkefølge
Følgende må ikke bygges før alle ovenstående faser er færdige:
- komponentlogik
- producentdata
- backend
- cloud
- autooptælling
- BOM

## Stopregel
Hvis en implementeringsidé kræver:
- komponentkatalog
- backend
- valideringsregler
- automatisk materialelogik

så stoppes arbejdet og idéen flyttes til arkiv eller senere fase.
