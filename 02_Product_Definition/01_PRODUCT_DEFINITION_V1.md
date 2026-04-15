# Stilp Product Definition v1

## Dom
Stilp v1 er et hurtigt, local-first skitseværktøj til stilladsopgaver.

Det er **ikke** et komponentsystem, et BOM-system eller et valideringssystem.

## Formål
Gøre det hurtigt at gå fra mål, fotos og korte forklaringer fra pladsen til:
- en brugbar plantegning af bygningens form
- en hurtig skitse af relevante facader/sider
- visuelle markeringer på facaderne
- en manuel pakkeliste
- en PDF- eller billedeksport

## Primær bruger
Stilladsmontør eller planlægger, som:
- står med mål, fotos og en kort forklaring
- vil erstatte papirskitse med hurtig digital skitse
- vil forberede pakning uden automatisk komponentberegning

## Kerneprincipper
1. Hurtigere end papir
2. Få trin og få tryk
3. Mobil-first
4. Local-first
5. Visuel planlægning før alt andet
6. Manuel pakkeliste, ikke auto-BOM

## Produktets kerne
Stilp v1 består af to sammenhængende visninger:

### 1. Planvisning
Brugeren kan tegne bygningens form oppefra.
Brugeren kan:
- oprette flere sider/vægge
- indtaste længder på sider
- markere om en side er langside eller gavl
- angive højde til tagfod og eventuelt kip

### 2. Facadevisning
For hver relevant side kan brugeren hurtigt opbygge et facadegrid.
Brugeren kan:
- angive antal sektioner/fag
- angive standard bredde pr. sektion
- angive antal etager
- angive standard højde pr. etage
- redigere enkelte sektioner og etager bagefter
- angive ståhøjde på øverste niveau
- få en automatisk topzone på 1000 mm over øverste ståhøjde

## Visuelle markører
Markører er tilladte i v1, men kun som visuelle planlægningsobjekter.

Tilladte markørtyper:
- konsol
- skråstiver
- stigedæk
- åbning
- tekstnote

Markører må ikke:
- generere komponenter
- generere BOM-linjer
- validere teknisk korrekthed
- skjule producentlogik

## Manuel pakkeliste
Stilp v1 må indeholde en manuel pakkeliste.
Det betyder:
- brugeren skriver selv linjer
- brugeren angiver selv antal
- appen beregner ikke automatisk komponenter

## Eksport
V1 skal kunne eksportere:
- PDF
- billede

Eksporten skal indeholde:
- opgavetype
- noter
- plantegning hvis relevant
- facadevisninger
- mål
- markører
- manuel pakkeliste

## Ude af scope
Følgende er ude af scope i v1:
- producentkataloger
- BOSTA-logik
- automatisk BOM/stykliste
- automatisk optælling
- prisberegning
- teknisk korrekthedsvalidering
- backend
- cloud sync
- AI
- ERP/BIM/CAD-integration

## Definition of success
Brugeren skal kunne:
1. oprette en opgave på sekunder
2. skitsere et hus eller en facade hurtigt
3. justere etager og sektioner direkte
4. sætte visuelle markører
5. skrive en manuel pakkeliste
6. eksportere en klar PDF eller et billede

Hvis det kræver komponentkatalog, backend eller BOM-logik, er det ikke v1.
