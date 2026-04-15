# 01_USER_FLOW_V1

## Formål
Dette dokument låser det samlede brugerflow i Stilp v1.

Stilp v1 er et hurtigt, local-first skitseværktøj til stilladsplanlægning og manuel pakkeforberedelse.

Det er ikke et BOM-system, ikke et komponentkatalog og ikke et teknisk valideringsværktøj.

---

## Primært brugerflow

```txt
1. Åbn app
2. Opret ny opgave
3. Vælg opgavetype
4. Skriv noter
5. Vælg arbejdsform:
   - Enkel side
   - Flersidet bygning
6. Lav planvisning hvis opgaven har flere sider
7. Generér én eller flere facader
8. Justér etager, sektioner og mål
9. Angiv ståhøjde på øverste niveau
10. Få automatisk topzone over øverste niveau
11. Placér visuelle markører
12. Skriv manuel pakkeliste
13. Eksportér PDF eller billede
```

---

## Variant A: Enkel side
Bruges når brugeren kun skal skitsere én facade eller én gavl.

```txt
Ny opgave
→ opgavetype
→ noter
→ facadeeditor
→ grid
→ justering
→ markører
→ manuel pakkeliste
→ eksport
```

---

## Variant B: Flersidet bygning
Bruges når der skal bygges rundt om et helt hus eller flere bygningssider.

```txt
Ny opgave
→ opgavetype
→ noter
→ planvisning
→ tegn bygningsform oppefra
→ angiv sidelængder og side-type
→ opret facader fra planen
→ redigér hver facade
→ manuel pakkeliste
→ eksport
```

---

## Beslutningsregel
Hvis brugeren kan løse opgaven hurtigere uden planvisning, skal appen ikke tvinge planvisning ind.

Planvisning er kun nødvendig ved flersidede eller komplekse bygninger.

---

## Krav til flow
- Maksimalt få trin fra ny opgave til første brugbare skitse
- Ingen tvungen dataindtastning ud over opgavetype og noter
- Ingen tvungen komponentvalg
- Ingen teknisk validering i flowet
- Ingen skjulte auto-beregninger

---

## Definition of done for flow
Flowet er korrekt når en bruger kan:
- oprette en opgave på få sekunder
- skitsere en enkelt side hurtigt
- skitsere flere sider via planvisning
- justere mål uden menurod
- markere særlige forhold visuelt
- eksportere et brugbart resultat
