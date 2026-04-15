# EDITOR_RULES_V1

## Formål
Facadeeditoren er hjertet i Stilp v1.

Den skal være hurtigere end papir og må kun være et geometrisk og visuelt planlægningsværktøj.

Den må ikke fungere som en skjult stilladsmotor.

## Regel 1 — Grid er geometrisk
Gridet repræsenterer:
- sektioner
- etager
- mål

Gridet repræsenterer ikke:
- komponenter
- rammer
- dæk
- diagonaler som systemdele
- BOM-linjer
- teknisk validering

## Regel 2 — Generering af grid
Brugeren angiver:
- antal sektioner
- standardbredde pr. sektion
- antal etager
- standardhøjde pr. etage
- ståhøjde for øverste niveau

Editoren genererer derefter:
- et facadegrid
- en visuel topzone på 1000 mm over topStandingHeightMm

## Regel 3 — Træk-i-linjer
Brugeren må kunne:
- trække lodrette gridlinjer for at ændre sektionsbredde
- trække vandrette gridlinjer for at ændre etagehøjde

Når en linje trækkes:
- kun tilstødende sektion eller etage ændres
- eksisterende markører bliver på deres celleindeks
- editoren må ikke forsøge at korrigere efter skjulte regler

## Regel 4 — Tilføj/fjern sektioner og etager
Brugeren må kunne:
- tilføje sektion før eller efter valgt sektion
- fjerne valgt sektion
- tilføje etage over eller under valgt etage
- fjerne valgt etage

Editoren må ikke:
- foreslå stilladskomponenter
- kontrollere om ændringen er teknisk korrekt

## Regel 5 — Ståhøjde og topzone
Brugeren angiver ståhøjden for øverste arbejdsniveau.

Editoren skal altid:
- beregne topZoneHeightMm = topStandingHeightMm + 1000
- vise topzonen tydeligt som ekstra visuel zone over øverste ståhøjde

Topzonen er:
- en visuel planlægningshjælp
- ikke en juridisk eller teknisk godkendelse

## Regel 6 — Markører
Tilladte markørtyper i v1:
- console
- diagonal
- ladder_deck
- opening
- text_note

Markører må:
- placeres på en specifik celle eller kant
- flyttes
- slettes
- have enkel tekst eller metadata

Markører må ikke:
- generere komponenter
- generere BOM-linjer
- udløse skjulte regler
- validere noget
- ændre andre data automatisk

## Regel 7 — Plan til facade
Hvis en facade kommer fra planvisning:
- facadebredde skal følge side-længden i planvisningen
- facade-navn må kobles til side-id
- sidetype må vises som metadata

Editoren må ikke:
- tolke planvisningen som systemstilladslogik
- gætte komponenttyper ud fra sidetype

## Regel 8 — Hurtighed
Editoren skal optimeres til få handlinger:
- generér grid hurtigt
- redigér direkte på lærredet
- undgå dybe menuer
- undgå tunge formularer

Hvis en funktion kræver mere end kort, direkte interaktion, er den sandsynligvis forkert til v1.

## Regel 9 — No-go i editoren
Følgende er forbudt i v1-editoren:
- komponentvælger
- producentdata
- BOM-preview
- sikkerhedsvalidering
- regelmotor
- lastklasse-logik
- rør/koblingslogik
- automatisk materialeliste

## Regel 10 — Eksportkontrakt
Facadeeditoren skal kun eksportere:
- geometri
- mål
- ståhøjde
- topzone
- markører
- noter

Ikke:
- komponenter
- styklister
- beregnede materialer
