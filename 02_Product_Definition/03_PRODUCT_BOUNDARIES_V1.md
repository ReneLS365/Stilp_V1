# Stilp Product Boundaries v1

## Hovedregel
Stilp v1 er et visuelt planlægningsværktøj.
Det er ikke en teknisk autoritet.

## Tilladt
- geometri
- mål
- planvisning
- facadegrid
- visuelle markører
- manuel pakkeliste
- lokal lagring
- PDF/billede

## Ikke tilladt
- producentafhængig logik
- automatisk komponentberegning
- automatisk stykliste
- teknisk godkendelse
- sikkerhedsgodkendelse
- backend-authoritative regler
- cloud-synkronisering
- prislogik
- AI-assistenter

## Grænse for topzone
Topzonen på 1000 mm over øverste ståhøjde er en visuel planlægningsregel i appen.
Den må ikke formuleres som juridisk, normativ eller ingeniørmæssig validering.

## Grænse for markører
Konsoller, skråstivere, stigedæk, åbninger og noter er kun visuelle markører.
De må ikke udløse skjult beregning.

## Grænse for planvisning
Planvisningen må bruges til:
- optegning af husets form
- opdeling i sider
- klassificering af sider som gavl/langside
- mål til tagfod/kip

Planvisningen må ikke bruges til:
- automatisk generering af stilladskomponenter
- teknisk layout-validering
- beregning af materialeforbrug

## Grænse for pakkeliste
Pakkelisten i v1 er manuel.
Den må gerne være struktureret.
Den må ikke være automatisk genereret ud fra skitsen.

## Grænse for data
V1-data må kun omfatte:
- opgave
- noter
- opgavetype
- planvisning
- facader
- etager
- sektioner
- markører
- manuel pakkeliste
- eksportmetadata

V1-data må ikke omfatte:
- komponentmastere
- producenttabeller
- kompatibilitetsmatricer
- BOM-linjer
- priser
- lagerstatus

## Konfliktregel
Hvis en idé ligger på grænsen, så vælges den simpleste løsning der kun understøtter visuel planlægning.
Hvis den kræver komponentviden eller backend, er den ude.
