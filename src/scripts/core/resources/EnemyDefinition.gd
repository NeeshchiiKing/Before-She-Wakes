class_name EnemyDefinition extends Resource
# Provides the packed scene resource, Preview texture and span config for enemies

@export var scene           : PackedScene #Scene containing enemy
@export var preview_texture : Texture2D #imgae displayed represents enemy

@export_category("Spawn_Behavior")
# Defines how the spawner determines when this enemuy should respawn
# Note: These values are used by spawner unless override_enemy_default is enabled on spawner
@export var respawn_mode : Spawner.RespawnType

# Base cooldown applied when using ON_TIMER respawn mode
# This value is used after the enemy is removed from the scene
@export_range(0.0, 60.0, 0.1) var cooldown_time : float = 0.0

# Adds a random value between 0.0 and this amount to the cooldown_time
@export_range(0.0, 60.0, 0.1) var randomize_cooldown_time : float = 0.0
