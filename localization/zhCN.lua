local EM=EquipMate
if EM.locale~="zhCN" then return end
local L=EM.L

L.POPUP_NAME="输入套装名称"; L.POPUP_DELETE="删除这套装备？"
L.POPUP_OVERWRITE="覆盖“%s”？\n将当前装备的物品保存到该套装选中的栏位。"
L.POPUP_READ_ERROR="无法读取套装名称输入框。"; L.EQUIP="装备"; L.SAVE="保存"
L.OVERWRITE="覆盖"; L.ALL_SLOTS="所有栏位"; L.NO_SLOTS="全部取消"
L.SLOT_INCLUDED_FMT="已包含在%s中"; L.SLOT_IGNORED_FMT="未包含在%s中"
L.SLOT_INCLUDED_HELP="点击以保持此栏位不变。"
L.SLOT_IGNORED_HELP="点击以将当前装备的物品保存到此套装。"
L.SLOT_EMPTY_HELP="此套装会将此栏位保持为空。"
L.EMPTY="空置"; L.ITEM_FMT="物品 %s"
L.CONTEXT_PRESET_FMT="自动：%s"; L.OFF="关闭"; L.RENAME="重命名"
L.DUPLICATE="复制"; L.KEYBINDING_FMT="按键：%s"; L.NONE="无"
L.DELETE="删除"
L.NO_BINDING="无快速按键"; L.BINDING_FMT="套装按键 %d"; L.SELECTED_FMT="[已选择] %s"
L.TOOLTIP_KEYBINDING_FMT="按键：%s"
L.BINDING_CHAT_FMT="快速按键 %s：%s"; L.CLEARED="已清除"
L.RULE_TITLE="自动"; L.RULE_OFF="关闭"
L.RULE_CATEGORY_GENERAL="常规"; L.RULE_CATEGORY_TARGETS="目标"
L.RULE_CATEGORY_PLACES="地点"; L.RULE_CATEGORY_FORMS="形态/姿态"
L.RULE_CATEGORY_ASPECTS="守护"
L.PRESET_HELP_FMT="检测到%s时自动装备此套装。"
L.PRESET_OFF_HELP="关闭此套装的自动装备。"
L.ENHANCED_APIS_MISSING="未检测到增强客户端 API（ClassicAPI、nampower 或 SuperWoW）；将使用原版兼容模式。"
L.SELECT_FIRST="请先选择一套装备。"
L.MATCHED_FMT="已装备 %d / %d 个栏位"; L.MISSING="缺失："
L.AUTOMATIC_FMT="自动：%s"
L.CUSTOM_RULES_FMT="自定义自动规则：%d"
L.BINDING_OUTFIT_FMT="切换 EquipMate 套装 %d"
L.CREATURE_TYPES={Beast="野兽",Undead="亡灵",Demon="恶魔",Critter="小动物"}
L.ZONE_NAMES={
  City={"铁炉堡","达纳苏斯","暴风城","奥格瑞玛","雷霆崖","幽暗城"},
  AV={"奥特兰克山谷"},AB={"阿拉希盆地"},WSG={"战歌峡谷"},
  Battleground={"Blood Ring","Sunnyglade Valley"},
  ArgentDawn={"西瘟疫之地","东瘟疫之地","斯坦索姆","通灵学院","纳克萨玛斯"}
}
L.PRESET_LABELS={Boss="首领",Lvl63="63级以上",Trash="普通怪物",BeastTrash="野兽普通怪",
UndeadTrash="亡灵普通怪",DemonTrash="恶魔普通怪",Critter="小动物",Riding="骑乘",Dining="进食",
Battleground="战场",City="城市",ArgentDawn="银色黎明",AV="奥特兰克山谷",AB="阿拉希盆地",
WSG="战歌峡谷",Instance="副本",Battle="战斗姿态",Defensive="防御姿态",Berserker="狂暴姿态",
Bear="熊形态",Cat="猎豹形态",Aquatic="水栖形态",Travel="旅行形态",Moonkin="枭兽形态",
Shadowform="暗影形态",Stealth="潜行",GhostWolf="幽魂之狼",Monkey="灵猴守护",
Hawk="雄鹰守护",Cheetah="猎豹守护",Pack="豹群守护",Beast="野兽守护",
Wild="野性守护",Evocate="唤醒"}
L.SLOT_LABELS={HeadSlot="头部",NeckSlot="颈部",ShoulderSlot="肩部",ShirtSlot="衬衣",
ChestSlot="胸部",WaistSlot="腰部",LegsSlot="腿部",FeetSlot="脚",WristSlot="手腕",
HandsSlot="手",Finger0Slot="戒指 1",Finger1Slot="戒指 2",Trinket0Slot="饰品 1",
Trinket1Slot="饰品 2",BackSlot="背部",MainHandSlot="主手",SecondaryHandSlot="副手",
RangedSlot="远程 / 圣物",TabardSlot="战袍",AmmoSlot="弹药"}
EM.ApplyLocalization()
