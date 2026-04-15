# 02_PLAN_VIEW_FLOW_V1

## Formål
Planvisningen bruges til at tegne bygningens form oppefra, så brugeren hurtigt kan oprette flere facader ud fra samme bygning.

Planvisningen er geometrisk. Den må ikke indeholde komponentlogik eller BOM-logik.

---

## Hvad brugeren gør

```txt
1. Vælg planvisning
2. Tegn bygningens omrids som polygon
3. Ret længden på hver side
4. Angiv side-type:
   - langside
   - gavl
   - anden
5. Angiv højde til tagfod
6. Angiv kiphøjde hvis relevant
7. Gem planen
8. Opret facader fra siderne
```

---

## Input
### Obligatorisk
- sidepunkter / vægge
- sidelængder

### Valgfrit
- tagfodshøjde
- kiphøjde
- sidebetegnelse
- notemarkører

---

## UI-regler
- Brugeren skal kunne tegne formen groft først
- Brugeren skal derefter kunne trykke på hver side og rette målet direkte
- Side-type skal være et hurtigt valg, ikke en lang formular
- Polygonen skal kunne lukkes og genåbnes for redigering
- Hjørner skal kunne trækkes direkte

---

## Fra plan til facade
Når planen er gemt, skal appen kunne oprette én facade pr. side.

Hver facade arver:
- navn eller indeks
- sidelængde
- side-type
- tagfodshøjde
- kiphøjde hvis relevant

Appen må ikke gætte stilladstype eller komponenter ud fra planen.

---

## No-go
Planvisningen må ikke:
- beregne komponenter
- foreslå systemdele
- validere stilladsløsning
- tælle sektioner automatisk uden brugerens valg
- lave skjult BOM-forberedelse

---

## Definition of done
Planvisningen er god nok når brugeren kan:
- tegne en bygning oppefra hurtigt
- rette hver side uden bøvl
- oprette facader ud fra planen
- forstå sammenhængen mellem plan og facader med det samme
