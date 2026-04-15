# MVP_SCOPE_LOCK_V1

## Formål
Stilp v1 er et hurtigt, local-first digitalt skitseværktøj til stilladsopgaver.

Formålet er at erstatte papirskitser med en enkel mobil arbejdsgang til:
- hurtig oprettelse af opgaver
- planvisning af bygningens form
- hurtig facadeoptegning side for side
- mål og visuelle markeringer
- manuel pakkeforberedelse
- PDF- eller billedeksport

Stilp v1 er ikke et komponentsystem, ikke et BOM-system og ikke et teknisk valideringsværktøj.

## Primær bruger
Stilladsmontør eller formand, som før opstart eller pakning hurtigt vil omsætte mål, fotos og mundtlig forklaring til en brugbar skitse.

## Primært brugerflow
1. Opret opgave
2. Vælg opgavetype
3. Skriv noter
4. Tegn bygning oppefra i planvisning, hvis opgaven har flere sider
5. Generér og redigér facader
6. Angiv etager, sektioner og ståhøjde
7. Placér visuelle markører
8. Skriv manuel pakkeliste
9. Eksportér PDF eller billede

## In scope
- local-first lagring
- projektoprettelse
- opgavetype
- noter
- planvisning af bygningens form
- flere sider/facader pr. opgave
- facadegrid
- standardhøjde pr. etage
- standardbredde pr. sektion
- manuel justering af etager og sektioner
- træk-i-linjer for hurtig justering
- ståhøjde på øverste niveau
- automatisk topzone på 1000 mm over øverste ståhøjde som visuel planlægningshjælp
- visuelle markører:
  - konsol
  - skråstiver
  - stigedæk
  - åbning
  - tekstnote
- manuel pakkeliste
- eksport til PDF
- eksport til billede

## Out of scope
- automatisk BOM/stykliste
- automatisk komponentoptælling
- producentkataloger
- BOSTA-logik
- systemprofiler
- prisberegning
- AI-funktioner
- cloud sync
- backend
- auth
- teknisk korrekthedsvalidering
- sikkerheds- eller lovvalidering
- ERP/BIM/CAD integration
- CSV/Excel eksport

## Hårde regler
- Hvis en funktion kræver komponentlogik, BOM-logik eller teknisk validering, er den ude af scope i v1.
- Markører er kun visuelle. De må ikke generere komponenter eller regler.
- Topzonen er kun visuel planlægningshjælp. Den er ikke juridisk eller teknisk godkendelse.
- Planvisning og facadevisning er geometriske værktøjer, ikke stilladsmotor.
- Den manuelle pakkeliste er manuel. Ingen automatisk udledning.

## Acceptkriterier for v1
Stilp v1 er færdig nok, når brugeren kan:
- oprette en opgave på få tryk
- tegne et hus eller en bygning oppefra
- generere en eller flere facader
- redigere etager og sektioner hurtigt
- angive ståhøjde og se topzonen
- placere visuelle markører
- skrive en manuel pakkeliste
- eksportere en klar PDF eller et billede
- gøre det hele hurtigere end på papir

## Definition of failure
v1 fejler, hvis projektet igen glider ind i:
- komponentbiblioteker
- katalogimport
- automatisk materialeberegning
- backend-arkitektur
- skjult regelmotor
- teknisk validering forklædt som UI-hjælp
