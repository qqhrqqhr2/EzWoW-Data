# EzWoW - Data

**English** · [한국어](#한국어)

Shared game data for the EzWoW addons on WoW Forever, kept in one place so every EzWoW addon shows the same, up-to-date information.

## What it holds
- **Items**: item info, where items drop (with drop chances) and who sells them.
- **Dungeons**: dungeons, bosses, kill order and WoW Forever boss drops.
- **Rare monsters**.
- **Recipes**: profession recipes, reagents and where to learn them.
- **Quests**: quest levels, quest givers and turn-ins, objective spots and quest item drops.
- **Spots**: where NPCs, objects and vendors stand, including NPCs new in WoW Forever.
- **Names** for each client language. Only your client's language is loaded.

## How it works
- It is not used on its own. EzWoW addons such as Map Finder, Tooltip, Best Gear Finder, Profession Recipes, Dungeon Route Guide and Quest read their data from it.
- It is optional. The EzWoW addons keep working without it and fall back to their own data.
- Data is loaded only when an addon needs it, so memory use stays low.

---

## 한국어

와우 포에버용 EzWoW 애드온들이 함께 쓰는 게임 자료입니다. 한 곳에 모아 두어 모든 EzWoW 애드온이 같은 최신 정보를 보여 줍니다.

## 담고 있는 자료
- **아이템**: 아이템 정보, 드롭처(드롭 확률), 판매처
- **던전**: 던전·보스 목록, 처치 순서, 와우 포에버 보스 드롭
- **레어 몬스터**
- **제조법**: 전문 기술 제조법, 재료, 배우는 곳
- **퀘스트**: 퀘스트 레벨, 주는·받는 NPC, 목표 위치, 퀘스트 아이템 드롭
- **위치**: NPC·물체·상인 위치(와우 포에버 신규 NPC 포함)
- **이름**: 언어별 이름. 내 클라이언트 언어만 읽습니다.

## 동작 방식
- 혼자서는 쓰이지 않습니다. 지도 검색(Map Finder), 툴팁(Tooltip), 장비 찾기(Best Gear Finder), 전문 기술 제조법(Profession Recipes), 던전 길잡이(Dungeon Route Guide), 퀘스트(Quest) 같은 EzWoW 애드온이 이 자료를 읽어 씁니다.
- 선택 사항입니다. 없어도 EzWoW 애드온은 자기 자료로 그대로 동작합니다.
- 애드온이 필요할 때만 자료를 읽어서 메모리를 적게 씁니다.

---

**Support:** If you find this addon useful, you can support its development. [Buy Me a Coffee ☕](https://buymeacoffee.com/qqhrqqhr2)

**후원:** 애드온이 도움이 되셨다면 개발 후원으로 응원해 주세요. [Buy Me a Coffee ☕](https://buymeacoffee.com/qqhrqqhr2)

---

**Data credits:** Monster, object and vendor spots and item drop data come from **Classic-DB** of the CMaNGOS project ([cmangos/classic-db](https://github.com/cmangos/classic-db), GNU GPL v3). Its license ships with the addon (`LICENSE-DATA.md`).

**데이터 출처:** 몬스터·물체·상인 위치와 아이템 드롭 자료는 CMaNGOS 프로젝트의 **Classic-DB**([cmangos/classic-db](https://github.com/cmangos/classic-db), GNU GPL v3)에서 가져왔습니다. 라이선스 파일(`LICENSE-DATA.md`)을 애드온에 함께 넣었습니다.
