local EM=EquipMate
if EM.locale~="deDE" then return end
local L=EM.L

L.POPUP_NAME="Namen für das Outfit eingeben"
L.POPUP_DELETE="Dieses Outfit löschen?"
L.POPUP_OVERWRITE="\"%s\" überschreiben?\nDie aktuell angelegten Gegenstände werden in den ausgewählten Plätzen dieses Outfits gespeichert."
L.POPUP_READ_ERROR="Das Feld für den Outfitnamen konnte nicht gelesen werden."
L.EQUIP="Anlegen"; L.SAVE="Speichern"
L.OVERWRITE="Überschreiben"; L.ALL_SLOTS="Alle Plätze"; L.NO_SLOTS="Keine Plätze"
L.SLOT_INCLUDED_FMT="In %s enthalten"; L.SLOT_IGNORED_FMT="Nicht in %s enthalten"
L.SLOT_INCLUDED_HELP="Klicken, um diesen Platz unverändert zu lassen."
L.SLOT_IGNORED_HELP="Klicken, um den aktuell angelegten Gegenstand in diesem Outfit zu speichern."
L.SLOT_EMPTY_HELP="Dieses Outfit lässt diesen Platz leer."
L.EMPTY="Leer"; L.ITEM_FMT="Gegenstand %s"
L.CONTEXT_PRESET_FMT="Automatisch: %s"
L.OFF="Aus"; L.RENAME="Umbenennen"; L.DUPLICATE="Duplizieren"
L.KEYBINDING_FMT="Tastenbelegung: %s"; L.NONE="Keine"
L.DELETE="Löschen"
L.NO_BINDING="Keine Schnellbelegung"; L.BINDING_FMT="Outfitbelegung %d"
L.TOOLTIP_KEYBINDING_FMT="Tastenbelegung: %s"
L.SELECTED_FMT="[Ausgewählt] %s"; L.BINDING_CHAT_FMT="Schnellbelegung %s für %s"
L.CLEARED="gelöscht"; L.RULE_TITLE="Automatisch"
L.RULE_OFF="Aus"
L.RULE_CATEGORY_GENERAL="Allgemein"; L.RULE_CATEGORY_TARGETS="Ziele"
L.RULE_CATEGORY_PLACES="Orte"; L.RULE_CATEGORY_FORMS="Formen"
L.RULE_CATEGORY_ASPECTS="Aspekte"
L.PRESET_HELP_FMT="Legt dieses Outfit automatisch an, wenn %s erkannt wird."
L.PRESET_OFF_HELP="Deaktiviert das automatische Anlegen dieses Outfits."
L.ENHANCED_APIS_MISSING="Keine erweiterte Client-API erkannt (ClassicAPI, nampower oder SuperWoW); die Vanilla-Kompatibilität wird verwendet."
L.SELECT_FIRST="Zuerst ein Outfit auswählen."
L.MATCHED_FMT="%d von %d Plätzen angelegt"; L.MISSING="Fehlend:"
L.AUTOMATIC_FMT="Automatisch: %s"
L.CUSTOM_RULES_FMT="Eigene automatische Regeln: %d"
L.BINDING_OUTFIT_FMT="EquipMate-Outfit %d umschalten"
L.CREATURE_TYPES={Beast="Wildtier",Undead="Untoter",Demon="Dämon",Critter="Kleintier"}
L.ZONE_NAMES={
  City={"Ironforge","Eisenschmiede","Darnassus","Stormwind","Sturmwind","Orgrimmar","Thunder Bluff","Undercity"},
  AV={"Alteractal"},AB={"Arathibecken"},WSG={"Warsongschlucht"},
  Battleground={"Blood Ring","Sunnyglade Valley"},
  ArgentDawn={"Westliche Pestländer","Östliche Pestländer","Stratholme","Scholomance","Naxxramas"}
}
L.PRESET_LABELS={Boss="Boss",Lvl63="Stufe 63+",Trash="Trash",BeastTrash="Wildtier-Trash",
UndeadTrash="Untoten-Trash",DemonTrash="Dämonen-Trash",Critter="Kleintier",Riding="Reiten",
Dining="Essen",Battleground="Schlachtfeld",City="Stadt",ArgentDawn="Argentumdämmerung",
AV="Alteractal",AB="Arathibecken",WSG="Kriegshymnenschlucht",Instance="Instanz",
Battle="Kampfhaltung",Defensive="Verteidigungshaltung",Berserker="Berserkerhaltung",
Bear="Bärengestalt",Cat="Katzengestalt",Aquatic="Wassergestalt",Travel="Reisegestalt",
Moonkin="Mondkingestalt",Shadowform="Schattengestalt",Stealth="Verstohlenheit",
GhostWolf="Geisterwolf",Monkey="Aspekt des Affen",Hawk="Aspekt des Falken",
Cheetah="Aspekt des Geparden",Pack="Aspekt des Rudels",Beast="Aspekt des Wildtiers",
Wild="Aspekt der Wildnis",Evocate="Hervorrufung"}
L.SLOT_LABELS={HeadSlot="Kopf",NeckSlot="Hals",ShoulderSlot="Schultern",ShirtSlot="Hemd",
ChestSlot="Brust",WaistSlot="Taille",LegsSlot="Beine",FeetSlot="Füße",WristSlot="Handgelenke",
HandsSlot="Hände",Finger0Slot="Ring 1",Finger1Slot="Ring 2",Trinket0Slot="Schmuck 1",
Trinket1Slot="Schmuck 2",BackSlot="Rücken",MainHandSlot="Waffenhand",
SecondaryHandSlot="Schildhand",RangedSlot="Distanz / Relikt",TabardSlot="Wappenrock",AmmoSlot="Munition"}
EM.ApplyLocalization()
