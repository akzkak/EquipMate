local EM=EquipMate
if EM.locale~="koKR" then return end
local L=EM.L

L.POPUP_NAME="장비 세트 이름을 입력하세요"
L.POPUP_DELETE="이 장비 세트를 삭제하시겠습니까?"
L.POPUP_OVERWRITE="\"%s\" 덮어쓰기?\n현재 착용 중인 아이템을 이 장비 세트에서 선택된 칸에 저장합니다."
L.POPUP_READ_ERROR="장비 세트 이름 입력란을 읽을 수 없습니다."
L.EQUIP="착용"; L.SAVE="저장"
L.OVERWRITE="덮어쓰기"; L.ALL_SLOTS="모든 칸"; L.NO_SLOTS="모두 해제"
L.SLOT_INCLUDED_FMT="%s에 포함됨"; L.SLOT_IGNORED_FMT="%s에 포함되지 않음"
L.SLOT_INCLUDED_HELP="이 칸을 변경하지 않으려면 클릭하세요."
L.SLOT_IGNORED_HELP="현재 착용한 아이템을 이 장비 세트에 저장하려면 클릭하세요."
L.SLOT_EMPTY_HELP="이 장비 세트는 이 칸을 비워 둡니다."
L.EMPTY="비움"; L.ITEM_FMT="아이템 %s"
L.CONTEXT_PRESET_FMT="자동: %s"; L.OFF="끄기"; L.RENAME="이름 변경"
L.DUPLICATE="복제"; L.KEYBINDING_FMT="단축키: %s"; L.NONE="없음"
L.DELETE="삭제"
L.NO_BINDING="빠른 단축키 없음"; L.BINDING_FMT="장비 세트 단축키 %d"
L.TOOLTIP_KEYBINDING_FMT="단축키: %s"
L.SELECTED_FMT="[선택됨] %s"; L.BINDING_CHAT_FMT="빠른 단축키 %s: %s"
L.CLEARED="해제"; L.RULE_TITLE="자동"
L.RULE_OFF="끄기"; L.SELECT_FIRST="먼저 장비 세트를 선택하세요."
L.RULE_CATEGORY_GENERAL="일반"; L.RULE_CATEGORY_TARGETS="대상"
L.RULE_CATEGORY_PLACES="장소"; L.RULE_CATEGORY_FORMS="변신/태세"
L.RULE_CATEGORY_ASPECTS="상"
L.PRESET_HELP_FMT="%s 상태가 감지되면 이 장비 세트를 자동으로 착용합니다."
L.PRESET_OFF_HELP="이 장비 세트의 자동 착용을 끕니다."
L.ENHANCED_APIS_MISSING="향상된 클라이언트 API(ClassicAPI, nampower 또는 SuperWoW)가 감지되지 않아 기본 Vanilla 호환 모드를 사용합니다."
L.MATCHED_FMT="%d / %d 장비 칸 착용"
L.MISSING="누락:"
L.AUTOMATIC_FMT="자동: %s"; L.CUSTOM_RULES_FMT="사용자 자동 규칙: %d"
L.BINDING_OUTFIT_FMT="EquipMate 장비 세트 %d 전환"
L.CREATURE_TYPES={Beast="야수",Undead="언데드",Demon="악마",Critter="동물"}
L.ZONE_NAMES={
  City={"아이언포지","다르나서스","스톰윈드","오그리마","썬더 블러프","언더시티"},
  AV={"알터랙 계곡"},AB={"아라시 분지"},WSG={"전쟁노래 협곡"},
  Battleground={"Blood Ring","Sunnyglade Valley"},
  ArgentDawn={"서부 역병지대","동부 역병지대","스트라솔름","스칼로맨스","낙스라마스"}
}
L.PRESET_LABELS={Boss="우두머리",Lvl63="63레벨 이상",Trash="일반 몬스터",BeastTrash="야수 일반 몬스터",
UndeadTrash="언데드 일반 몬스터",DemonTrash="악마 일반 몬스터",Critter="동물",Riding="탈것",
Dining="음식",Battleground="전장",City="도시",ArgentDawn="은빛 여명회",AV="알터랙 계곡",
AB="아라시 분지",WSG="전쟁노래 협곡",Instance="인스턴스",Battle="전투 태세",
Defensive="방어 태세",Berserker="광폭 태세",Bear="곰 변신",Cat="표범 변신",
Aquatic="바다표범 변신",Travel="치타 변신",Moonkin="달빛야수 변신",Shadowform="어둠의 형상",
Stealth="은신",GhostWolf="늑대 정령",Monkey="원숭이의 상",Hawk="매의 상",
Cheetah="치타의 상",Pack="치타 무리의 상",Beast="야수의 상",Wild="야생의 상",Evocate="환기"}
L.SLOT_LABELS={HeadSlot="머리",NeckSlot="목",ShoulderSlot="어깨",ShirtSlot="속옷",
ChestSlot="가슴",WaistSlot="허리",LegsSlot="다리",FeetSlot="발",WristSlot="손목",
HandsSlot="손",Finger0Slot="반지 1",Finger1Slot="반지 2",Trinket0Slot="장신구 1",
Trinket1Slot="장신구 2",BackSlot="등",MainHandSlot="주장비",SecondaryHandSlot="보조장비",
RangedSlot="원거리 / 성물",TabardSlot="휘장",AmmoSlot="탄약"}
EM.ApplyLocalization()
