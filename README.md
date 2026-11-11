# EzWoW - Data (`EzWoW-Data`)

## CurseForge

- **Project ID / 프로젝트 ID:** `1797865`

**[English](#english) · [한국어](#한국어)**

WoW Forever (`Interface: 16001`)

---

## English

### Overview

Shared game data for the EzWoW addons. The data lives in one place so every EzWoW addon shows the same, up-to-date information. It does nothing on its own; EzWoW addons read from it. It is optional: EzWoW addons keep working without it.

### What is in the package

One download installs several folders. Only `EzWoW-Data` loads at login; the others load when an addon asks for them.

| Folder | Contents |
|---|---|
| `EzWoW-Data` | access functions, instance tables (always loaded) |
| `EzWoW-Data-Items` | item info, item sources with drop chances, vendors, quest rewards, tokens, mounts, pets, toys |
| `EzWoW-Data-Dungeons` | dungeons, bosses (kill order), boss NPC IDs, boss loot, dungeon quests |
| `EzWoW-Data-Rares` | rare monsters and where they appear |
| `EzWoW-Data-Recipes` | recipes, reagents, skill levels, where to learn them, crafted items |
| `EzWoW-Data-Quests` | quest levels, requirements, objectives, givers and turn-ins, objective spots, quest item drops, rewards |
| `EzWoW-Data-Spawns` | NPC, object, item and quest spots (including NPCs new in WoW Forever) |
| `EzWoW-Data-Names-<language>` | names of items, NPCs, objects, quests and spells for koKR, enUS, deDE, frFR, esES, ruRU, zhCN, zhTW. Only your client's language is loaded. |

### Installation

1. Put all `EzWoW-Data*` folders into `Interface/AddOns/`.
2. Keep them enabled in the **AddOns** list.

### For addon authors

Add `## OptionalDeps: EzWoW-Data` to your `.toc` and use the global `EzWoW_Data`:

```lua
local Data = EzWoW_Data
if Data then
    Data.Load("Items", function(name, ok)
        if ok then print(Data.GetItemSources(6948)) end
    end)
end
```

- `Load(module [, callback])`: loads `"Items"`, `"Dungeons"`, `"Rares"`, `"Recipes"`, `"Quests"`, `"Spawns"`, `"Names"` (client language) or `"Names-<locale>"`. It never loads during combat; the load runs after combat and then calls the callback.
- Getters load their module on first use (out of combat) and return `nil` while it is not available: `GetItemSources`, `ParseItemSources`, `GetGearDrops`, `GetItemInfo`, `GetSpawns`, `GetSpawnIDs`, `GetNpcInfo`, `GetName`, `GetKoreanFromEnglish`, `GetRecipe`, `GetProfession`, `GetCraftedBy`, `GetDungeons`, `GetDungeon`, `GetDungeonByInstance`, `GetRare`, `GetQuest`, `GetQuestLevels`, `GetQuestRewards`, `GetQuestGiver`, `GetQuestTurnIn`, `GetInstance`, `GetInstanceMapName`, plus `Get(module, table, key)` and `GetTable(module, table)`.
- `formatVersion` changes when a table shape changes. Each module also has its own version (`GetModuleVersion`).
- The table shapes are described at the top of each data file.

---

## 한국어

### 개요

EzWoW 애드온들이 함께 쓰는 게임 자료입니다. 한 곳에 모아 두어 모든 EzWoW 애드온이 같은 최신 정보를 보여 줍니다. 혼자서는 아무 일도 하지 않고, EzWoW 애드온이 이 자료를 읽어 씁니다. 선택 사항이라 없어도 EzWoW 애드온은 그대로 동작합니다.

### 들어 있는 폴더

한 번 받으면 여러 폴더가 함께 설치됩니다. 접속할 때는 `EzWoW-Data`만 읽고, 나머지는 애드온이 필요할 때 읽습니다.

| 폴더 | 내용 |
|---|---|
| `EzWoW-Data` | 자료를 꺼내는 함수, 인스턴스 표(항상 읽음) |
| `EzWoW-Data-Items` | 아이템 정보, 드롭처(드롭 확률), 판매처, 퀘스트 보상, 토큰, 탈것, 애완동물, 장난감 |
| `EzWoW-Data-Dungeons` | 던전, 보스(처치 순서), 보스 NPC 번호, 보스 전리품, 던전 퀘스트 |
| `EzWoW-Data-Rares` | 희귀 몬스터와 나오는 곳 |
| `EzWoW-Data-Recipes` | 제조법, 재료, 숙련도, 배우는 곳, 만든 아이템 |
| `EzWoW-Data-Quests` | 퀘스트 레벨, 조건, 목표, 주는·받는 곳, 목표 위치, 퀘스트 아이템 드롭, 보상 |
| `EzWoW-Data-Spawns` | NPC·물체·아이템·퀘스트 위치(와우 포에버 신규 NPC 포함) |
| `EzWoW-Data-Names-<언어>` | 아이템·NPC·물체·퀘스트·주문 이름(koKR, enUS, deDE, frFR, esES, ruRU, zhCN, zhTW). 내 클라이언트 언어만 읽습니다. |

### 설치

1. `EzWoW-Data`로 시작하는 폴더를 모두 `Interface/AddOns/`에 넣습니다.
2. **애드온** 목록에서 켜 둡니다.

### 애드온 제작자용

`.toc`에 `## OptionalDeps: EzWoW-Data`를 넣고 전역 `EzWoW_Data`를 씁니다. 함수 목록은 위 English 부분과 같습니다.

- `Load(모듈 [, 콜백])`: 전투 중에는 읽지 않고, 전투가 끝난 뒤 읽은 다음 콜백을 부릅니다.
- 조회 함수는 처음 쓸 때 모듈을 읽고(전투 밖에서), 아직 없으면 `nil`을 돌려줍니다.
- 표 모양이 바뀌면 `formatVersion`이 올라갑니다. 표 모양은 각 자료 파일 맨 위에 적혀 있습니다.

---

**Data credits:** Monster, object and vendor spots and item drop data come from **Classic-DB** of the CMaNGOS project ([cmangos/classic-db](https://github.com/cmangos/classic-db), GNU GPL v3). Its license ships with the addon (`LICENSE-DATA.md`, `LICENSE-DATA-NOTICE.md`).

**데이터 출처:** 몬스터·물체·상인 위치와 아이템 드롭 자료는 CMaNGOS 프로젝트의 **Classic-DB**([cmangos/classic-db](https://github.com/cmangos/classic-db), GNU GPL v3)에서 가져왔습니다. 라이선스 파일(`LICENSE-DATA.md`, `LICENSE-DATA-NOTICE.md`)을 애드온에 함께 넣었습니다.

**License:** GPL-3.0 (`LICENSE`).
