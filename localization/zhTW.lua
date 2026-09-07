local EM=EquipMate
if EM.locale~="zhTW" then return end
local L=EM.L

L.POPUP_NAME="輸入套裝名稱"; L.POPUP_DELETE="刪除這套裝備？"
L.POPUP_OVERWRITE="覆寫「%s」？\n將目前裝備的物品儲存到此套裝選取的欄位。"
L.POPUP_READ_ERROR="無法讀取套裝名稱輸入框。"; L.EQUIP="裝備"; L.SAVE="儲存"
L.OVERWRITE="覆寫"; L.ALL_SLOTS="所有欄位"; L.NO_SLOTS="全部取消"
L.SLOT_INCLUDED_FMT="已包含在%s中"; L.SLOT_IGNORED_FMT="未包含在%s中"
L.SLOT_INCLUDED_HELP="點擊以保持此欄位不變。"
L.SLOT_IGNORED_HELP="點擊以將目前裝備的物品儲存到此套裝。"
L.SLOT_EMPTY_HELP="此套裝會將此欄位保持為空。"
L.EMPTY="空置"; L.ITEM_FMT="物品 %s"
L.CONTEXT_PRESET_FMT="自動：%s"; L.OFF="關閉"; L.RENAME="重新命名"
L.DUPLICATE="複製"; L.KEYBINDING_FMT="按鍵：%s"; L.NONE="無"
L.DELETE="刪除"
L.NO_BINDING="無快速按鍵"; L.BINDING_FMT="套裝按鍵 %d"; L.SELECTED_FMT="[已選擇] %s"
L.TOOLTIP_KEYBINDING_FMT="按鍵：%s"
L.BINDING_CHAT_FMT="快速按鍵 %s：%s"; L.CLEARED="已清除"
L.RULE_TITLE="自動"; L.RULE_OFF="關閉"
L.RULE_CATEGORY_GENERAL="一般"; L.RULE_CATEGORY_TARGETS="目標"
L.RULE_CATEGORY_PLACES="地點"; L.RULE_CATEGORY_FORMS="形態/姿態"
L.RULE_CATEGORY_ASPECTS="守護"
L.PRESET_HELP_FMT="偵測到%s時自動裝備此套裝。"
L.PRESET_OFF_HELP="關閉此套裝的自動裝備。"
L.ENHANCED_APIS_MISSING="未偵測到增強客戶端 API（ClassicAPI、nampower 或 SuperWoW）；將使用原版相容模式。"
L.SELECT_FIRST="請先選擇一套裝備。"
L.MATCHED_FMT="已裝備 %d / %d 個欄位"; L.MISSING="缺少："
L.AUTOMATIC_FMT="自動：%s"
L.CUSTOM_RULES_FMT="自訂自動規則：%d"
L.BINDING_OUTFIT_FMT="切換 EquipMate 套裝 %d"
L.CREATURE_TYPES={Beast="野獸",Undead="不死族",Demon="惡魔",Critter="小動物"}
L.ZONE_NAMES={
  City={"鐵爐堡","達納蘇斯","暴風城","奧格瑪","雷霆崖","幽暗城"},
  AV={"奧特蘭克山谷"},AB={"阿拉希盆地"},WSG={"戰歌峽谷"},
  Battleground={"Blood Ring","Sunnyglade Valley"},
  ArgentDawn={"西瘟疫之地","東瘟疫之地","斯坦索姆","通靈學院","納克薩瑪斯"}
}
L.PRESET_LABELS={Boss="首領",Lvl63="63級以上",Trash="普通怪物",BeastTrash="野獸普通怪",
UndeadTrash="不死族普通怪",DemonTrash="惡魔普通怪",Critter="小動物",Riding="騎乘",Dining="進食",
Battleground="戰場",City="城市",ArgentDawn="銀色黎明",AV="奧特蘭克山谷",AB="阿拉希盆地",
WSG="戰歌峽谷",Instance="副本",Battle="戰鬥姿態",Defensive="防禦姿態",Berserker="狂暴姿態",
Bear="熊形態",Cat="獵豹形態",Aquatic="水棲形態",Travel="旅行形態",Moonkin="梟獸形態",
Shadowform="暗影形態",Stealth="潛行",GhostWolf="幽魂之狼",Monkey="靈猴守護",
Hawk="雄鷹守護",Cheetah="獵豹守護",Pack="豹群守護",Beast="野獸守護",
Wild="野性守護",Evocate="喚醒"}
L.SLOT_LABELS={HeadSlot="頭部",NeckSlot="頸部",ShoulderSlot="肩部",ShirtSlot="襯衣",
ChestSlot="胸部",WaistSlot="腰部",LegsSlot="腿部",FeetSlot="腳",WristSlot="手腕",
HandsSlot="手",Finger0Slot="戒指 1",Finger1Slot="戒指 2",Trinket0Slot="飾品 1",
Trinket1Slot="飾品 2",BackSlot="背部",MainHandSlot="主手",SecondaryHandSlot="副手",
RangedSlot="遠程 / 聖物",TabardSlot="外袍",AmmoSlot="彈藥"}
EM.ApplyLocalization()
