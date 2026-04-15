# 03_FACADE_EDITOR_FLOW_V1

## Formål
Facadeeditoren er den primære arbejdsskærm i Stilp v1.

Den skal gøre det hurtigt at generere og redigere en facade som grid med etager og sektioner.

---

## Grundflow

```txt
1. Åbn facade
2. Angiv antal sektioner
3. Angiv standardbredde pr. sektion
4. Angiv antal etager
5. Angiv standardhøjde pr. etage
6. Generér grid
7. Ret enkelte sektioner og etager
8. Angiv ståhøjde på øverste niveau
9. Appen viser topzone automatisk
10. Placér markører
11. Gem facade
```

---

## Regler for grid
- Sektioner er lodrette opdelinger i bredden
- Etager er vandrette opdelinger i højden
- Brugeren må kunne generere et stort grid hurtigt med standardmål
- Brugeren må kunne overstyre mål pr. sektion og pr. etage bagefter

Eksempel:
```txt
10 sektioner × 3000 mm
4 etager × 2000 mm
```

---

## Ståhøjde og topzone
- Brugeren vælger ståhøjde på øverste arbejdsniveau
- Appen tilføjer automatisk en visuel topzone på 1000 mm over dette niveau
- Topzonen er en planlægningshjælp og ikke teknisk godkendelse

---

## Markører
Tilladte v1-markører:
- konsol
- skråstiver
- stigedæk
- åbning
- tekstnote

Markører placeres på sektion, etage eller position.

Markører er kun visuelle.

---

## Hurtig redigering
Brugeren skal kunne:
- trække i lodrette linjer for at ændre sektionsbredde
- trække i vandrette linjer for at ændre etagehøjde
- trykke på en celle eller sektion for at placere markør
- kopiere gentagne markører hurtigt hvis relevant

---

## No-go
Facadeeditoren må ikke:
- generere BOM
- vælge komponenter
- validere korrekthed
- kende producentkataloger
- bruge skjult systemlogik

---

## Definition of done
Facadeeditoren er god nok når brugeren kan:
- generere et brugbart grid på få sekunder
- justere det uden menurod
- placere visuelle markører hurtigt
- få en tydelig og læsbar facade ud til eksport
