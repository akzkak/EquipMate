local EM=EquipMate
if EM.locale~="ruRU" then return end
local L=EM.L

L.POPUP_NAME="Введите название комплекта"
L.POPUP_DELETE="Удалить этот комплект?"
L.POPUP_OVERWRITE="Перезаписать «%s»?\nСохранить надетые предметы в выбранные ячейки этого комплекта."
L.POPUP_READ_ERROR="Не удалось прочитать поле названия комплекта."
L.EQUIP="Надеть"; L.SAVE="Сохранить"
L.OVERWRITE="Перезаписать"; L.ALL_SLOTS="Все ячейки"; L.NO_SLOTS="Ни одной"
L.SLOT_INCLUDED_FMT="Включено в %s"; L.SLOT_IGNORED_FMT="Не включено в %s"
L.SLOT_INCLUDED_HELP="Нажмите, чтобы не изменять эту ячейку."
L.SLOT_IGNORED_HELP="Нажмите, чтобы сохранить надетый предмет в этом комплекте."
L.SLOT_EMPTY_HELP="Этот комплект оставляет эту ячейку пустой."
L.EMPTY="Пусто"; L.ITEM_FMT="Предмет %s"
L.CONTEXT_PRESET_FMT="Автоматически: %s"
L.OFF="Отключено"; L.RENAME="Переименовать"; L.DUPLICATE="Дублировать"
L.KEYBINDING_FMT="Клавиша: %s"; L.NONE="Нет"; L.DELETE="Удалить"
L.NO_BINDING="Нет быстрой клавиши"; L.BINDING_FMT="Комплект %d"
L.TOOLTIP_KEYBINDING_FMT="Клавиша: %s"
L.SELECTED_FMT="[Выбрано] %s"; L.BINDING_CHAT_FMT="быстрая клавиша %s для %s"
L.CLEARED="снята"; L.RULE_TITLE="Автоматически"; L.RULE_OFF="Отключено"
L.RULE_CATEGORY_GENERAL="Общие"; L.RULE_CATEGORY_TARGETS="Цели"
L.RULE_CATEGORY_PLACES="Места"; L.RULE_CATEGORY_FORMS="Формы"
L.RULE_CATEGORY_ASPECTS="Аспекты"
L.PRESET_HELP_FMT="Автоматически надевает этот комплект при обнаружении: %s."
L.PRESET_OFF_HELP="Отключает автоматическое надевание этого комплекта."
L.ENHANCED_APIS_MISSING="Расширенный API клиента (ClassicAPI, nampower или SuperWoW) не обнаружен; используется совместимость с Vanilla."
L.SELECT_FIRST="Сначала выберите комплект."
L.MATCHED_FMT="Экипировано ячеек: %d из %d"; L.MISSING="Отсутствует:"
L.AUTOMATIC_FMT="Автоматически: %s"
L.CUSTOM_RULES_FMT="Пользовательских автоматических правил: %d"
L.BINDING_OUTFIT_FMT="Переключить комплект EquipMate %d"
L.CREATURE_TYPES={Beast="Животное",Undead="Нежить",Demon="Демон",Critter="Существо"}
L.ZONE_NAMES={
  City={"Стальгорн","Дарнас","Штормград","Оргриммар","Громовой Утес","Подгород"},
  AV={"Альтеракская долина"},AB={"Низина Арати"},WSG={"Ущелье Песни Войны"},
  Battleground={"Blood Ring","Sunnyglade Valley"},
  ArgentDawn={"Западные Чумные земли","Восточные Чумные земли","Стратхольм","Некроситет","Наксрамас"}
}

L.PRESET_LABELS={Boss="Босс",Lvl63="Уровень 63+",Trash="Обычные противники",
BeastTrash="Звери",UndeadTrash="Нежить",DemonTrash="Демоны",Critter="Зверёк",
Riding="Верхом",Dining="Еда и питьё",Battleground="Поле боя",City="Город",
ArgentDawn="Серебряный Рассвет",AV="Альтеракская долина",AB="Низина Арати",
WSG="Ущелье Песни Войны",Instance="Подземелье",Battle="Боевая стойка",
Defensive="Оборонительная стойка",Berserker="Стойка берсерка",Bear="Облик медведя",
Cat="Облик кошки",Aquatic="Водный облик",Travel="Походный облик",
Moonkin="Облик лунного совуха",Shadowform="Облик Тьмы",Stealth="Незаметность",
GhostWolf="Призрачный волк",Monkey="Дух обезьяны",Hawk="Дух ястреба",
Cheetah="Дух гепарда",Pack="Дух стаи",Beast="Дух зверя",
Wild="Дух дикой природы",Evocate="Прилив сил"}

L.SLOT_LABELS={HeadSlot="Голова",NeckSlot="Шея",ShoulderSlot="Плечи",ShirtSlot="Рубашка",
ChestSlot="Грудь",WaistSlot="Пояс",LegsSlot="Ноги",FeetSlot="Ступни",
WristSlot="Запястья",HandsSlot="Кисти рук",Finger0Slot="Кольцо 1",
Finger1Slot="Кольцо 2",Trinket0Slot="Аксессуар 1",Trinket1Slot="Аксессуар 2",
BackSlot="Спина",MainHandSlot="Правая рука",SecondaryHandSlot="Левая рука",
RangedSlot="Дальний бой / Реликвия",TabardSlot="Гербовая накидка",AmmoSlot="Боеприпасы"}

EM.ApplyLocalization()
