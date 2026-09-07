local EM=EquipMate
if EM.locale~="frFR" then return end
local L=EM.L

L.POPUP_NAME="Saisissez le nom de la tenue"
L.POPUP_DELETE="Supprimer cette tenue ?"
L.POPUP_OVERWRITE="Écraser « %s » ?\nEnregistrer les objets actuellement équipés dans les emplacements sélectionnés de cette tenue."
L.POPUP_READ_ERROR="Impossible de lire le champ du nom de la tenue."
L.EQUIP="Équiper"; L.SAVE="Enregistrer"
L.OVERWRITE="Écraser"; L.ALL_SLOTS="Tous les emplacements"; L.NO_SLOTS="Aucun emplacement"
L.SLOT_INCLUDED_FMT="Inclus dans %s"; L.SLOT_IGNORED_FMT="Non inclus dans %s"
L.SLOT_INCLUDED_HELP="Cliquez pour ne pas modifier cet emplacement."
L.SLOT_IGNORED_HELP="Cliquez pour enregistrer l’objet actuellement équipé dans cette tenue."
L.SLOT_EMPTY_HELP="Cette tenue laisse cet emplacement vide."
L.EMPTY="Vide"; L.ITEM_FMT="Objet %s"
L.CONTEXT_PRESET_FMT="Automatique : %s"; L.OFF="Désactivé"
L.RENAME="Renommer"; L.DUPLICATE="Dupliquer"; L.KEYBINDING_FMT="Raccourci : %s"
L.NONE="Aucun"
L.DELETE="Supprimer"; L.NO_BINDING="Aucun raccourci rapide"; L.BINDING_FMT="Raccourci de tenue %d"
L.TOOLTIP_KEYBINDING_FMT="Raccourci : %s"
L.SELECTED_FMT="[Sélectionné] %s"; L.BINDING_CHAT_FMT="raccourci rapide %s pour %s"
L.CLEARED="effacé"; L.RULE_TITLE="Automatique"
L.RULE_OFF="Désactivé"
L.RULE_CATEGORY_GENERAL="Général"; L.RULE_CATEGORY_TARGETS="Cibles"
L.RULE_CATEGORY_PLACES="Lieux"; L.RULE_CATEGORY_FORMS="Formes"
L.RULE_CATEGORY_ASPECTS="Aspects"
L.PRESET_HELP_FMT="Équipe automatiquement cette tenue lorsque %s est détecté."
L.PRESET_OFF_HELP="Désactive l’équipement automatique de cette tenue."
L.ENHANCED_APIS_MISSING="Aucune API client améliorée détectée (ClassicAPI, nampower ou SuperWoW) ; utilisation de la compatibilité Vanilla."
L.SELECT_FIRST="Sélectionnez d’abord une tenue."
L.MATCHED_FMT="%d emplacement(s) sur %d équipé(s)"; L.MISSING="Manquant :"
L.AUTOMATIC_FMT="Automatique : %s"
L.CUSTOM_RULES_FMT="Règles automatiques personnalisées : %d"
L.BINDING_OUTFIT_FMT="Basculer la tenue EquipMate %d"
L.CREATURE_TYPES={Beast="Bête",Undead="Mort-vivant",Demon="Démon",Critter="Bestiole"}
L.ZONE_NAMES={
  City={"Ironforge","Darnassus","Cité de Stormwind","Stormwind","Orgrimmar","Thunder Bluff","Undercity"},
  AV={"Vallée d’Alterac","Vallée d'Alterac"},AB={"Bassin d’Arathi","Bassin d'Arathi"},
  WSG={"Goulet des Chanteguerres","Goulet des Warsong"},
  Battleground={"Blood Ring","Sunnyglade Valley"},
  ArgentDawn={"Maleterres de l’ouest","Maleterres de l'ouest","Maleterres de l'ouest (Western Plaguelands)",
    "Maleterres de l’est","Maleterres de l'est","Maleterres de l'est (Eastern Plaguelands)",
    "Stratholme","Scholomance","Naxxramas"}
}
L.PRESET_LABELS={Boss="Boss",Lvl63="Niveau 63+",Trash="Ennemis ordinaires",
BeastTrash="Bêtes ordinaires",UndeadTrash="Morts-vivants ordinaires",DemonTrash="Démons ordinaires",
Critter="Bestiole",Riding="Monture",Dining="Repas",Battleground="Champ de bataille",City="Ville",
ArgentDawn="Aube d’argent",AV="Vallée d’Alterac",AB="Bassin d’Arathi",WSG="Goulet des Chanteguerres",
Instance="Instance",Battle="Posture de combat",Defensive="Posture défensive",
Berserker="Posture berserker",Bear="Forme d’ours",Cat="Forme de félin",Aquatic="Forme aquatique",
Travel="Forme de voyage",Moonkin="Forme de sélénien",Shadowform="Forme d’Ombre",
Stealth="Camouflage",GhostWolf="Loup fantôme",Monkey="Aspect du singe",Hawk="Aspect du faucon",
Cheetah="Aspect du guépard",Pack="Aspect de la meute",Beast="Aspect de la bête",
Wild="Aspect de la nature",Evocate="Évocation"}
L.SLOT_LABELS={HeadSlot="Tête",NeckSlot="Cou",ShoulderSlot="Épaules",ShirtSlot="Chemise",
ChestSlot="Torse",WaistSlot="Taille",LegsSlot="Jambes",FeetSlot="Pieds",WristSlot="Poignets",
HandsSlot="Mains",Finger0Slot="Anneau 1",Finger1Slot="Anneau 2",Trinket0Slot="Bijou 1",
Trinket1Slot="Bijou 2",BackSlot="Dos",MainHandSlot="Main droite",SecondaryHandSlot="Main gauche",
RangedSlot="Distance / Relique",TabardSlot="Tabard",AmmoSlot="Munitions"}
EM.ApplyLocalization()
