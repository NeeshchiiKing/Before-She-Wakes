class_name PerkDefinition extends Resource
## One perk. Found as a perk orb (Blueprint, Tome, Teacher or Deed) and installed in a perk socket on the Orb Grid.
## Gameplay checks it by id, e.g. player.orb_grid.has_perk(&"battering_ram")

enum Tier { INNER, OUTER, CAPSTONE }
enum Source { BLUEPRINT, TOME, TEACHER, DEED }

@export var id : StringName = &"" ## Code checks this, so keep it lowercase_with_underscores
@export var display_name : String = "New Perk"
## Grid branch: mig Might, sur Survival, arc Arcana, tri Trickery, con Conditioning
@export_enum("mig", "sur", "arc", "tri", "con") var branch : String = "mig"
## Inner fits any socket in its branch, Outer needs a socket past the seal, Capstone needs the capstone socket
@export var tier : Tier = Tier.INNER
@export_multiline var description : String = ""
@export var source : Source = Source.BLUEPRINT
@export var source_detail : String = "" ## e.g. "Kira at the Inn" or "Win 50 fights unarmed"
@export var icon : Texture2D ## Drawn inside its socket on the grid
