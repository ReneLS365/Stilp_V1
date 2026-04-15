# 04_MANUAL_PACKINGLIST_AND_EXPORT_V1

## Formål
Stilp v1 skal kunne samle en manuel pakkeliste og eksportere et brugbart dokument.

Pakkelisten er manuel. Eksporten er den endelige ground truth i v1.

---

## Manuel pakkeliste
Brugeren skal kunne tilføje linjer som:
- tekst
- antal
- enhed

Eksempel:
```txt
Rammer - 20 stk
Dæk - 40 stk
Stiger - 2 stk
```

---

## Regler for pakkeliste
- Intet auto-udfyld fra markører
- Intet komponentkatalog
- Intet producentfilter
- Ingen automatisk optælling
- Ingen prisfelter

---

## Eksportindhold
PDF eller billede skal kunne indeholde:
- opgavetype
- noter
- planvisning hvis den findes
- en eller flere facader
- mål på facader
- ståhøjde og topzone visuelt
- visuelle markører
- manuel pakkeliste

---

## Eksportlayout
Prioritet i eksport:
1. Læsbar skitse
2. Tydelige mål
3. Tydelige markører
4. Brugbare noter
5. Manuel pakkeliste

Eksport skal være praktisk, ikke pæn for præsentationens skyld.

---

## No-go
Eksporten må ikke:
- påstå teknisk korrekthed
- vise skjulte BOM-data
- generere CSV/Excel i v1
- indeholde producentafhængig komponentlogik

---

## Definition of done
Eksporten er god nok når en bruger kan:
- sende eller vise PDF/billede som arbejdsgrundlag
- bruge eksporten som visuel reference ved pakning
- læse pakkelisten uden at åbne appen igen
