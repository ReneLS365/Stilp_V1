# Stilp v1 masterplan og task tracker

## Formål
Dette dokument er den samlede mållinje for Stilp v1.

Det bruges til:
- at se hele forløbet samlet
- at se hvor langt projektet er
- at styre Codex-opgaver i korrekt rækkefølge
- at undgå scope drift tilbage til BOM, kataloger, backend og anden gammel støj

## V1 slutmål
Stilp v1 er færdig når brugeren kan:

- oprette en opgave
- vælge opgavetype
- skrive noter
- tegne en bygning oppefra i planvisning
- oprette og redigere facader side for side
- generere facadegrid
- justere etager og sektioner
- sætte ståhøjde og få automatisk topzone
- placere visuelle markører
- skrive manuel pakkeliste
- eksportere PDF eller billede

## Uden for scope
Disse ting må ikke snige sig ind i v1:
- automatisk BOM
- producentkataloger
- BOSTA-logik
- automatisk optælling
- backend
- cloud sync
- pris
- AI
- teknisk korrekthedsvalidering

## Statusmodel
Brug kun disse statustyper:
- planned
- active
- blocked
- review
- merged
- done

## Fremdrift
- Total tasks: 21
- Fase 0 setup: done
- Done: 17
- Active: 1
- Planned: 3
- Aktuel fase: Fase 6
- Aktuel fokus: T18

## Aktuel repo-status
Repoet indeholder allerede:
- Flutter app shell
- base navigation
- 6 låste hovedskærme som placeholders
- `AppFlow` app shell state
- `LocalProjectStore` interface
- filbaseret `LocalProjectStore` i app documents directory
- basal app-shell test

Det betyder:
- T01 er reelt done
- T02 er reelt done
- T03 er reelt done
- T04 er implementeret med lokal oprettelse og åbning af projekt
- T05 er implementeret i kode med fuld projektmodel
- T06 er implementeret med lokal fil-persistence
- T07 er implementeret med plan-canvas, node-drag og lokal persistence
- T08 er implementeret med side-metadataredigering og persisted måldata
- T09 er implementeret med plan-til-facade mapping, labels og persistens
- T10 er implementeret med facadegrid-generering, visning og persistens
- T11 er implementeret med direkte line-drag og persistens
- T12 er merged via PR #13
- T13 er merged via PR #15
- T14 er merged via PR #17
- T15 er merged via PR #19 med visuel markørplacering og lokal persistens
- T16 er merged via PR #21 med marker editing, move, edit og delete
- T17 er merged via PR #23 med manuel pakkeliste uden BOM
- T18 er næste aktive task

---

# Låste beslutninger før næste fase

## 1. Navigation model
Fra og med T04 er den ønskede model:
- `ProjectsList -> ProjectWorkspace`
- `ProjectWorkspace` ejer projektkontekst
- planvisning, facadeeditor, manuel pakkeliste og eksport hører under et aktivt projekt

Den nuværende globale bundnavigation er accepteret som skeleton i T01/T02, men er ikke den endelige struktur for projektflowet.

## 2. State management
State management låses til:
- `Riverpod`

Begrundelse:
- passer til feature-first Flutter-struktur
- gør projektkontekst og lokal dataflow lettere at holde ren
- er mere robust end fortsat shell-`setState` når T04-T06 bygges

## 3. Persistence strategi i v1
Persistence i v1 låses til:
- lokale JSON-filer i app documents directory

Det betyder:
- ingen backend
- ingen cloud
- ingen Hive/Isar i første omgang
- ingen unødig databaskompleksitet før det er nødvendigt

T06 er implementeret som lokal filbaseret persistence for det fulde projektdokument.

---

# Faseoversigt

## Fase 1 — App-skelet
Mål: app-shell, navigation og tomme hovedskærme.

- T01 Initial app shell
- T02 Locked screens and navigation
- T03 Local-first app structure

## Fase 2 — Projekt og datamodel
Mål: projekter kan oprettes, gemmes og åbnes lokalt.

- T04 New project flow
- T05 Project model v1 in code
- T06 Local persistence wired

## Fase 3 — Planvisning
Mål: bygning kan tegnes oppefra og omsættes til facader.

- T07 Plan view canvas
- T08 Side measurement and side type
- T09 Plan-to-facade mapping

## Fase 4 — Facadeeditor
Mål: hurtig og brugbar facadeskitsering.

- T10 Facade grid generation
- T11 Direct line adjustment
- T12 Standing height and top zone
- T13 Facade side switching
- T14 Facade state persistence

## Fase 5 — Markører og manuel pakkeliste
Mål: praktisk planlægning og pakkeforberedelse.

- T15 Visual markers
- T16 Marker editing
- T17 Manual packing list

## Fase 6 — Eksport og finish
Mål: brugbart output og basal robusthed.

- T18 Export preview
- T19 PDF export
- T20 Image export
- T21 Polish and baseline tests

---

# Samlet taskliste

## T01 — Initial app shell
- Fase: 1
- Status: done
- Mål: oprette Flutter app skeleton med tydelig mappe- og filstruktur
- Indhold:
  - app entry
  - base theme
  - app shell
  - routing skeleton
- Afhænger af: ingen
- Done når:
  - appen kan starte
  - hovedstruktur findes
  - ingen backendspor er introduceret

## T02 — Locked screens and navigation
- Fase: 1
- Status: done
- Mål: oprette låste hovedskærme og navigation
- Indhold:
  - Project list
  - New project
  - Plan view
  - Facade editor
  - Manual packing list
  - Export preview
- Afhænger af: T01
- Done når:
  - alle hovedskærme findes
  - navigation virker mellem dem
  - skærmnavne matcher scope-filerne

## T03 — Local-first app structure
- Fase: 1
- Status: done
- Mål: lægge lokal struktur for data og app state
- Indhold:
  - local-first foldering
  - Riverpod app state skeleton
  - persistence interfaces
  - klar overgang væk fra global shell-navigation som endelig projektmodel
- Implementeret i repo:
  - local-first foldering
  - `LocalProjectStore`
  - `InMemoryProjectStore`
  - Riverpod app shell + project session state
- Afhænger af: T01
- Done når:
  - lokal struktur findes
  - state management er låst og indført
  - persistence interface er klar til T04-T06
  - ingen cloud eller backend er introduceret

## T04 — New project flow
- Fase: 2
- Status: done
- Mål: oprette ny opgave med opgavetype og noter
- Indhold:
  - create project
  - task type
  - notes
  - åbning af projekt i `ProjectWorkspace`
- Afhænger af: T02, T03
- Done når:
  - bruger kan oprette projekt
  - projekt kan åbnes i næste flow

## T05 — Project model v1 in code
- Fase: 2
- Status: done
- Mål: implementere den låste projektmodel i kode
- Indhold:
  - full project model
  - planView
  - facades
  - storeys
  - sections
  - markers
  - manualPackingList
  - createdAt
  - updatedAt
- Afhænger af: T03
- Done når:
  - modellen matcher lock-filerne
  - summary-modeller og fuld model er tydeligt adskilt
  - ingen komponentmodeller er tilføjet

## T06 — Local persistence wired
- Fase: 2
- Status: done
- Mål: gemme, åbne og opdatere projekt lokalt
- Indhold:
  - save
  - load
  - update
  - JSON file persistence in app documents directory
- Afhænger af: T04, T05
- Done når:
  - projektdata overlever app-genstart
  - lokal persistence virker uden backend og uden cloud

## T07 — Plan view canvas
- Fase: 3
- Status: done
- Mål: tegne bygning oppefra
- Indhold:
  - sides
  - corners
  - simple shape editing
- Afhænger af: T04, T05, T06
- Done når:
  - brugeren kan oprette en planform visuelt

## T08 — Side measurement and side type
- Fase: 3
- Status: done
- Mål: tilføje længde og type pr. side
- Indhold:
  - side length
  - gavl/langside
  - tagfod
  - kip
- Afhænger af: T07
- Done når:
  - hver side kan målsættes og klassificeres

## T09 — Plan-to-facade mapping
- Fase: 3
- Status: done
- Mål: omsætte planvisning til facadeobjekter
- Indhold:
  - create facades from plan
  - side order
  - side labels
- Afhænger af: T07, T08
- Done når:
  - facader oprettes side for side

## T10 — Facade grid generation
- Fase: 4
- Status: done
- Mål: generere facadegrid hurtigt
- Indhold:
  - number of sections
  - default section width
  - number of storeys
  - default storey height
- Afhænger af: T09
- Done når:
  - brugeren kan generere et grid fra basisinput

## T11 — Direct line adjustment
- Fase: 4
- Status: done
- Mål: justere grid direkte med fingeren
- Indhold:
  - drag vertical lines
  - drag horizontal lines
  - edit single section
  - edit single storey
- Afhænger af: T10
- Done når:
  - grid kan justeres hurtigt uden tung formularlogik

## T12 — Standing height and top zone
- Fase: 4
- Status: done
- Mål: vise ståhøjde og automatisk topzone
- Indhold:
  - top standing height input
  - 1000 mm top zone
  - visual rendering
- Afhænger af: T10
- Done når:
  - topzone genereres og gemmes korrekt
- Repo-note:
  - merged via PR #13

## T13 — Facade side switching
- Fase: 4
- Status: done
- Repo-note: merged via PR #15
- Mål: skifte hurtigt mellem facader
- Indhold:
  - next/previous side
  - side selector
- Afhænger af: T09, T10
- Done når:
  - brugeren kan skifte side uden at miste overblik

## T14 — Facade state persistence
- Fase: 4
- Status: done
- Repo-note: merged via PR #17
- Mål: bevare facadeændringer pr. side
- Indhold:
  - persist facade state
  - restore state
- Afhænger af: T11, T12, T13
- Done når:
  - intet tabes ved sideskift eller genåbning

## T15 — Visual markers
- Fase: 5
- Status: done
- Repo-note: merged via PR #19
- Mål: placere visuelle markører i facaden
- Indhold:
  - console
  - diagonal
  - ladder deck
  - opening
  - text note
- Afhænger af: T11, T14
- Done når:
  - markører kan oprettes visuelt
  - ingen skjult logik findes

## T16 — Marker editing
- Fase: 5
- Status: done
- Repo-note: merged via PR #21
- Mål: redigere markører
- Indhold:
  - move
  - edit
  - delete
- Afhænger af: T15
- Done når:
  - markører kan ændres uden fejl

## T17 — Manual packing list
- Fase: 5
- Status: done
- Repo-note: merged via PR #23
- Mål: manuel pakkeliste uden BOM
- Indhold:
  - line items
  - quantity
  - unit
  - free text
- Afhænger af: T04, T14
- Done når:
  - bruger kan lave og gemme manuel pakkeliste

## T18 — Export preview
- Fase: 6
- Status: active
- Mål: samlet preview før eksport
- Indhold:
  - project
  - plan
  - facades
  - notes
  - packing list
- Afhænger af: T17
- Done når:
  - samlet preview kan vises stabilt

## T19 — PDF export
- Fase: 6
- Status: planned
- Mål: eksportere PDF
- Indhold:
  - PDF layout
  - readable pages
- Afhænger af: T18
- Done når:
  - PDF kan eksporteres og åbnes

## T20 — Image export
- Fase: 6
- Status: planned
- Mål: eksportere billede
- Indhold:
  - image output
  - facade or full project
- Afhænger af: T18
- Done når:
  - billede kan eksporteres og deles

## T21 — Polish and baseline tests
- Fase: 6
- Status: planned
- Mål: rydde de sidste fejl og sikre basisrobusthed
- Indhold:
  - grid logic tests
  - persistence tests
  - top zone tests
  - marker model tests
  - export payload checks
- Afhænger af: T19, T20
- Done når:
  - de vigtigste flows virker stabilt
  - ingen scope-drift er indført

---

# Milepæle

## Milepæl A
Efter T03
- app shell findes
- navigation kan bygges ovenpå
- lokal struktur er låst
- state management og persistence-retning er låst

## Milepæl B
Efter T06
- projekter kan oprettes og gemmes
- grundmodellen er levende

## Milepæl C
Efter T09
- bygning kan tegnes oppefra
- facader kan oprettes fra planen

## Milepæl D
Efter T14
- kerne-skitseflowet virker

## Milepæl E
Efter T17
- praktisk planlægning og manuel pakkeforberedelse virker

## Milepæl F
Efter T21
- Stilp v1 er klar til reel intern brug og feltprøve

---

# Opdateringsregel
Når en Codex-opgave er merged:
1. opdatér task-status i dette dokument
2. skriv PR-nummer under den konkrete task hvis relevant
3. flyt næste task til status `active`
4. opdatér fremdriftstal øverst

# Aktuel anbefalet startordre
1. T03 Local-first app structure
2. T04 New project flow
3. T05 Project model v1 in code
4. T06 Local persistence wired
5. T07 Plan view canvas
6. T08 Side measurement and side type
