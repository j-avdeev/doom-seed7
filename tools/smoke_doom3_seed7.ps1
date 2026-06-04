param(
  [string]$Seed7Js = "seed7/bin/s7.js",
  [string]$Seed7Lib = "seed7/lib",
  [string]$PortEntry = "doom3_seed7.s7",
  [string]$RuntimeEntry = "doom3_seed7_runtime.s7",
  [string]$InventoryEntry = "doom3_seed7_inventory.s7",
  [string]$CombatEntry = "doom3_seed7_combat.s7",
  [string]$AiEntry = "doom3_seed7_ai.s7",
  [string]$ObjectiveEntry = "doom3_seed7_objective.s7",
  [string]$LevelEntry = "doom3_seed7_level.s7",
  [string]$ModelEntry = "doom3_seed7_model.s7",
  [string]$WeaponEntry = "doom3_seed7_weapon.s7",
  [string]$ProjectileEntry = "doom3_seed7_projectile.s7",
  [string]$FxEntry = "doom3_seed7_fx.s7",
  [string]$CinematicEntry = "doom3_seed7_cinematic.s7",
  [string]$GuiEntry = "doom3_seed7_gui.s7",
  [string]$SoundEntry = "doom3_seed7_sound.s7",
  [string]$AudioEntry = "doom3_seed7_audio.s7",
  [string]$AasEntry = "doom3_seed7_aas.s7",
  [string]$ScriptEntry = "doom3_seed7_script.s7",
  [string]$SchedulerEntry = "doom3_seed7_scheduler.s7",
  [string]$TraceEntry = "doom3_seed7_trace.s7",
  [string]$VfsEntry = "doom3_seed7_vfs.s7",
  [string]$PlatformEntry = "doom3_seed7_platform.s7",
  [string]$ConsoleEntry = "doom3_seed7_console.s7",
  [string]$LangEntry = "doom3_seed7_lang.s7",
  [string]$PdaEntry = "doom3_seed7_pda.s7",
  [string]$AccessEntry = "doom3_seed7_access.s7",
  [string]$ArmorEntry = "doom3_seed7_armor.s7",
  [string]$SurvivalEntry = "doom3_seed7_survival.s7",
  [string]$CampaignEntry = "doom3_seed7_campaign.s7",
  [string]$PlayloopEntry = "doom3_seed7_playloop.s7",
  [string]$MathEntry = "doom3_seed7_math.s7",
  [string]$ParserEntry = "doom3_seed7_parser.s7",
  [string]$DeclEntry = "doom3_seed7_decl.s7",
  [string]$ResourceEntry = "doom3_seed7_resource.s7",
  [string]$TextureEntry = "doom3_seed7_texture.s7",
  [string]$MaterialEntry = "doom3_seed7_material.s7",
  [string]$LightingEntry = "doom3_seed7_lighting.s7",
  [string]$PoseEntry = "doom3_seed7_pose.s7",
  [string]$SubmitEntry = "doom3_seed7_submit.s7",
  [string]$SessionEntry = "doom3_seed7_session.s7",
  [string]$SaveEntry = "doom3_seed7_save.s7",
  [string]$PhysicsEntry = "doom3_seed7_physics.s7",
  [string]$InteractionEntry = "doom3_seed7_interaction.s7",
  [string]$SpawnEntry = "doom3_seed7_spawn.s7",
  [string]$MoverEntry = "doom3_seed7_mover.s7",
  [string]$RenderEntry = "doom3_seed7_render.s7",
  [string]$ViewEntry = "doom3_seed7_view.s7",
  [string]$CompiledMapEntry = "doom3_seed7_compiledmap.s7",
  [string]$FrameEntry = "doom3_seed7_frame.s7",
  [string]$LauncherProbeNeedle = "doom3_seed7_runtime.s7",
  [string]$FixturePath = $env:DOOM3_SEED7_FIXTURE,
  [string]$RealDoom3Path = $env:DOOM3_DATA_PATH,
  [switch]$GenerateFixtureOnly,
  [string]$GeneratedFixtureOut = "fixtures/base"
)

$ErrorActionPreference = "Stop"

function Assert-FileContains {
  param(
    [string]$Path,
    [string]$Needle,
    [string]$Label
  )

  $text = Get-Content -LiteralPath $Path -Raw
  if (-not $text.Contains($Needle)) {
    throw "$Label did not contain expected marker: $Needle"
  }
}

function Invoke-Doom3Seed7 {
  param(
    [string[]]$ArgsToPass,
    [string]$Label,
    [string[]]$MustContain = @(),
    [string]$Entry = $PortEntry
  )

  Write-Host "== $Label =="
  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = & node $Seed7Js -l $Seed7Lib $Entry @ArgsToPass 2>&1
  $ErrorActionPreference = $previousErrorAction
  $lines = foreach ($item in $output) {
    if ($item -is [System.Management.Automation.ErrorRecord]) {
      $item.Exception.Message
    } else {
      [string]$item
    }
  }
  $lines | ForEach-Object { Write-Host $_ }
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE"
  }
  $text = $lines -join "`n"
  foreach ($needle in $MustContain) {
    if (-not $text.Contains($needle)) {
      throw "$Label did not contain expected output: $needle"
    }
  }
}

function New-TgaBytes {
  param(
    [int]$Width,
    [int]$Height,
    [int]$BitsPerPixel = 32
  )

  $bytes = New-Object byte[] 18
  $bytes[2] = 2
  $bytes[12] = [byte]($Width -band 0xff)
  $bytes[13] = [byte](($Width -shr 8) -band 0xff)
  $bytes[14] = [byte]($Height -band 0xff)
  $bytes[15] = [byte](($Height -shr 8) -band 0xff)
  $bytes[16] = [byte]$BitsPerPixel
  $bytes[17] = 8
  return $bytes
}

function New-DdsDxt1Bytes {
  param(
    [int]$Width,
    [int]$Height,
    [int]$MipLevels = 4
  )

  $bytes = New-Object byte[] 128
  $bytes[0] = [byte][char]'D'
  $bytes[1] = [byte][char]'D'
  $bytes[2] = [byte][char]'S'
  $bytes[3] = [byte][char]' '
  [BitConverter]::GetBytes([uint32]124).CopyTo($bytes, 4)
  [BitConverter]::GetBytes([uint32]0x0002100F).CopyTo($bytes, 8)
  [BitConverter]::GetBytes([uint32]$Height).CopyTo($bytes, 12)
  [BitConverter]::GetBytes([uint32]$Width).CopyTo($bytes, 16)
  [BitConverter]::GetBytes([uint32]$MipLevels).CopyTo($bytes, 28)
  [BitConverter]::GetBytes([uint32]32).CopyTo($bytes, 76)
  [BitConverter]::GetBytes([uint32]0x00000004).CopyTo($bytes, 80)
  $bytes[84] = [byte][char]'D'
  $bytes[85] = [byte][char]'X'
  $bytes[86] = [byte][char]'T'
  $bytes[87] = [byte][char]'1'
  [BitConverter]::GetBytes([uint32]0x00001000).CopyTo($bytes, 108)
  return $bytes
}

function New-WavBytes {
  param(
    [int]$SampleRate = 22050,
    [int]$Channels = 1,
    [int]$BitsPerSample = 16,
    [int]$DurationMs = 100
  )

  $blockAlign = [int](($Channels * $BitsPerSample) / 8)
  $byteRate = [int]($SampleRate * $blockAlign)
  $dataSize = [int](($byteRate * $DurationMs) / 1000)
  $bytes = New-Object byte[] (44 + $dataSize)
  $bytes[0] = [byte][char]'R'
  $bytes[1] = [byte][char]'I'
  $bytes[2] = [byte][char]'F'
  $bytes[3] = [byte][char]'F'
  [BitConverter]::GetBytes([uint32](36 + $dataSize)).CopyTo($bytes, 4)
  $bytes[8] = [byte][char]'W'
  $bytes[9] = [byte][char]'A'
  $bytes[10] = [byte][char]'V'
  $bytes[11] = [byte][char]'E'
  $bytes[12] = [byte][char]'f'
  $bytes[13] = [byte][char]'m'
  $bytes[14] = [byte][char]'t'
  $bytes[15] = [byte][char]' '
  [BitConverter]::GetBytes([uint32]16).CopyTo($bytes, 16)
  [BitConverter]::GetBytes([uint16]1).CopyTo($bytes, 20)
  [BitConverter]::GetBytes([uint16]$Channels).CopyTo($bytes, 22)
  [BitConverter]::GetBytes([uint32]$SampleRate).CopyTo($bytes, 24)
  [BitConverter]::GetBytes([uint32]$byteRate).CopyTo($bytes, 28)
  [BitConverter]::GetBytes([uint16]$blockAlign).CopyTo($bytes, 32)
  [BitConverter]::GetBytes([uint16]$BitsPerSample).CopyTo($bytes, 34)
  $bytes[36] = [byte][char]'d'
  $bytes[37] = [byte][char]'a'
  $bytes[38] = [byte][char]'t'
  $bytes[39] = [byte][char]'a'
  [BitConverter]::GetBytes([uint32]$dataSize).CopyTo($bytes, 40)
  return $bytes
}

function New-Doom3Seed7Fixture {
  param(
    [string]$Name = "doom3-seed7-smoke-fixture"
  )

  $root = Join-Path $env:TEMP $Name
  if (Test-Path -LiteralPath $root) {
    $resolved = (Resolve-Path -LiteralPath $root).Path
    if (-not $resolved.StartsWith($env:TEMP, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to delete outside temp: $resolved"
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }

  $base = Join-Path $root "base"
  New-Item -ItemType Directory -Force -Path (Join-Path $base "maps/game") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "materials") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "def") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "fx") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "particles") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "script") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "config") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "guis") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "strings") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "pda") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "skins") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "textures/smoke") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "video") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "models/monsters/smoke") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "models/pickups/health") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "models/pickups/ammo") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "models/weapons/pistol") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "sound/monsters/smoke") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $base "sound/world") | Out-Null

  @'
textures/smoke/panel
{
 noshadows
 twosided
 translucent
 {
  blend add
  map textures/smoke/panel_d.tga
  scroll 0.25 0.00
  rotate 15
 }
}
textures/smoke/trim
{
 qer_editorimage textures/smoke/trim_editor
 diffusemap textures/smoke/trim_d
 bumpmap textures/smoke/trim_local
 specularmap textures/smoke/trim_s
}
textures/smoke/ghostclip
{
 nonsolid
}
'@ | Set-Content -LiteralPath (Join-Path $base "materials/smoke.mtr") -Encoding ASCII

  @'
entityDef monster_smoke_base
{
 "spawnclass" "idAI"
 "health" "150"
 "model" "models/monsters/smoke/smoke.md5mesh"
 "anim" "models/monsters/smoke/idle.md5anim"
 "skin" "skin_smoke_burned"
 "snd_sight" "sound/monsters/smoke/sight.wav"
 "mins" "-16 -16 0"
 "maxs" "16 16 64"
 "scriptobject" "monster_smoke_base"
 "melee_range" "80"
 "damage_melee" "12"
}
entityDef monster_smoke_child
{
 "inherit" "monster_smoke_base"
}
model model_smoke_imp
{
 mesh models/monsters/smoke/smoke.md5mesh
}
entityDef monster_model_ref
{
 "model" "model_smoke_imp"
}
entityDef item_health
{
 "model" "models/pickups/health/health.md5mesh"
}
entityDef ammo_bullets
{
 "model" "models/pickups/ammo/bullets.md5mesh"
}
entityDef weapon_pistol
{
 "model" "models/weapons/pistol/pickup.md5mesh"
 "model_view" "models/weapons/pistol/pickup.md5mesh"
 "ammoType" "ammo_bullets"
 "ammoRequired" "1"
 "clipSize" "12"
 "num_projectiles" "1"
 "spread" "0"
 "def_projectile" "projectile_smoke_round"
 "snd_fire" "sound/weapons/pistol/fire.wav"
 "gui" "guis/hud.gui"
}
entityDef projectile_smoke_round
{
 "damage" "25"
 "splash_damage" "10"
 "splash_radius" "48"
 "speed" "900"
 "model" "models/weapons/pistol/projectile.md5mesh"
 "fx_impact" "fx/smoke_impact"
}
'@ | Set-Content -LiteralPath (Join-Path $base "def/monsters.def") -Encoding ASCII

  @'
fx/smoke_impact
{
 "particle" "particles/smoke_impact.prt"
 "sound" "sound/weapons/pistol/fire.wav"
 "decal" "textures/smoke/panel"
 "light" "1.0 0.45 0.2"
 "duration" "500"
}
'@ | Set-Content -LiteralPath (Join-Path $base "fx/smoke.fx") -Encoding ASCII

  @'
particle smoke_impact
{
 count 8
 time 0.5
 color 1.0 0.45 0.2 1.0
 size 8
}
'@ | Set-Content -LiteralPath (Join-Path $base "particles/smoke_impact.prt") -Encoding ASCII

  @'
// parser smoke: line comment before script text
object monster_smoke_base {
 void init();
}

/* parser smoke: block comment before executable function */
void smoke_entry() {
 sys.println("smoke entry");
 $door_smoke_1.trigger($player1);
 wait(0.5);
 objective_complete();
}
'@ | Set-Content -LiteralPath (Join-Path $base "script/smoke.script") -Encoding ASCII

  @'
windowDef Desktop
{
 rect 0 0 640 480
 visible 1
 matcolor 0.1 0.8 0.6 1
 background "video/smoke_intro.roq"
 text "#str_00001"
 windowDef Health
 {
  rect 24 420 160 24
  visible 1
  matcolor 0.8 0.1 0.1 1
  onAction { set "cmd" "hud_health"; }
 }
}
'@ | Set-Content -LiteralPath (Join-Path $base "guis/hud.gui") -Encoding ASCII

  @'
windowDef MainMenu
{
 rect 0 0 640 480
 visible 1
 matcolor 0.02 0.02 0.02 1
 text "#str_00002"
 windowDef Start
 {
  rect 220 120 200 36
  visible 1
  matcolor 0.2 0.6 0.8 1
  onAction { set "cmd" "startgame"; }
 }
 windowDef Resume
 {
 rect 220 168 200 36
 visible 1
 matcolor 0.2 0.8 0.4 1
 text "#str_99999"
 onAction { set "cmd" "resume"; }
 }
 windowDef Restart
 {
  rect 220 216 200 36
  visible 1
  matcolor 0.8 0.5 0.2 1
  onAction { set "cmd" "restart"; }
 }
 windowDef Quit
 {
 rect 220 264 200 36
 visible 1
 matcolor 0.8 0.2 0.2 1
 text "#str_00003"
 onAction { set "cmd" "quit"; }
 }
}
'@ | Set-Content -LiteralPath (Join-Path $base "guis/mainmenu.gui") -Encoding ASCII

  @'
VERSION "2"
{
"#str_00001" "Health"
"#str_00002" "Smoke Access"
"#str_00003" "Quit"
"#str_00004" "Security Mail"
"#str_00005" "Audio Log"
}
'@ | Set-Content -LiteralPath (Join-Path $base "strings/english.lang") -Encoding ASCII

  @'
pda smoke_security
{
 "name" "#str_00002"
 "fullName" "Smoke Lab Security"
 "icon" "guis/hud.gui"
 "door" "door_smoke_1"
 "armor" "50"
 "armor_protection" "60"
 email mail_smoke_access
 {
  "subject" "#str_00004"
  "from" "UAC Admin"
  "body" "Door authorization rerouted through the smoke lab."
 }
 audio audio_smoke_log
 {
  "title" "#str_00005"
  "sound" "sound/monsters/smoke/sight.wav"
 }
 video video_smoke_intro
 {
  "title" "Smoke Intro"
  "video" "video/smoke_intro.roq"
 }
}
'@ | Set-Content -LiteralPath (Join-Path $base "pda/smoke_security.pda") -Encoding ASCII

  @'
skin skin_smoke_burned
{
 textures/smoke/panel textures/smoke/panel_burned
}
'@ | Set-Content -LiteralPath (Join-Path $base "skins/smoke.skin") -Encoding ASCII

  @'
{
"classname" "worldspawn"
"name" "world"
"gui" "guis/hud.gui"
"cinematic" "video/smoke_intro.roq"
"objective" "Restore access to the smoke door"
"nextmap" "game/mars_city2"
{
brushDef3
{
( 1 0 0 -64 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/panel 0 0 0
( -1 0 0 0 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/panel 0 0 0
( 0 1 0 -64 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/panel 0 0 0
( 0 -1 0 0 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/panel 0 0 0
( 0 0 1 -80 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/panel 0 0 0
( 0 0 -1 0 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/panel 0 0 0
}
}
{
brushDef3
{
( 1 0 0 -384 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/ghostclip 0 0 0
( -1 0 0 320 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/ghostclip 0 0 0
( 0 1 0 -64 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/ghostclip 0 0 0
( 0 -1 0 0 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/ghostclip 0 0 0
( 0 0 1 -80 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/ghostclip 0 0 0
( 0 0 -1 0 ) ( ( 1 0 0 ) ( 0 1 0 ) ) textures/smoke/ghostclip 0 0 0
}
}
{
patchDef2
{
textures/smoke/panel
( 3 3 0 0 0 )
(
( ( 96 -32 64 0 0 ) ( 96 0 64 0.5 0 ) ( 96 32 64 1 0 ) )
( ( 96 -32 80 0 0.5 ) ( 96 0 80 0.5 0.5 ) ( 96 32 80 1 0.5 ) )
( ( 96 -32 96 0 1 ) ( 96 0 96 0.5 1 ) ( 96 32 96 1 1 ) )
)
}
}
{
patchDef2
{
textures/smoke/trim
( 3 3 0 0 0 )
(
( ( 0 -32 64 0 0 ) ( 0 0 64 0.5 0 ) ( 0 32 64 1 0 ) )
( ( 0 -32 80 0 0.5 ) ( 0 0 80 0.5 0.5 ) ( 0 32 80 1 0.5 ) )
( ( 0 -32 96 0 1 ) ( 0 0 96 0.5 1 ) ( 0 32 96 1 1 ) )
)
}
}
}
{
"classname" "info_player_start"
"name" "player_start_1"
"origin" "128 0 64"
"angle" "180"
}
{
"classname" "light"
"name" "light_smoke_1"
"origin" "32 32 96"
"light_radius" "160 160 160"
"_color" "0.8 0.7 0.5"
}
{
"classname" "monster_smoke_child"
"name" "monster_smoke_1"
"origin" "192 0 64"
"snd_sight" "sound/monsters/smoke/alert.wav"
"call" "smoke_entry"
}
{
"classname" "func_door"
"name" "door_smoke_1"
"origin" "240 0 64"
"snd_open" "sound/world/door_open.wav"
}
{
"classname" "trigger_multiple"
"name" "trigger_open_door"
"origin" "80 0 64"
"target" "door_smoke_1"
}
{
"classname" "item_health"
"name" "health_pickup_1"
"origin" "80 32 64"
}
{
"classname" "ammo_bullets"
"name" "ammo_pickup_1"
"origin" "80 -31 64"
}
{
"classname" "weapon_pistol"
"name" "weapon_pickup_1"
"origin" "112 0 64"
}
'@ | Set-Content -LiteralPath (Join-Path $base "maps/game/mars_city1.map") -Encoding ASCII

  @'
PROC "4"
model {
 "world"
 surface {
  material textures/smoke/panel
  numVerts 3
  numIndexes 3
 }
}
interAreaPortals {
 3 2
 4 0 1 ( 0 0 0 ) ( 0 64 0 ) ( 0 64 80 ) ( 0 0 80 )
 4 1 2 ( 64 0 0 ) ( 64 64 0 ) ( 64 64 80 ) ( 64 0 80 )
}
'@ | Set-Content -LiteralPath (Join-Path $base "maps/game/mars_city1.proc") -Encoding ASCII

  @'
CM "1"
collisionModel "world"
{
 vertices { 4 }
 edges { 4 }
 polygons { 2
  polygon { material textures/smoke/panel contents solid plane 1 0 0 -64 }
  polygon { material textures/smoke/ghostclip contents solid plane 0 1 0 -64 }
 }
 brushes { 1 }
}
'@ | Set-Content -LiteralPath (Join-Path $base "maps/game/mars_city1.cm") -Encoding ASCII

  @'
AASVersion 1
settings monster_smoke_child
area 1 { origin 128 0 64 flags walk }
area 2 { origin 192 0 64 flags walk }
reachability 1 2 cost 64 travel walk
reachability 2 1 cost 64 travel walk
'@ | Set-Content -LiteralPath (Join-Path $base "maps/game/mars_city1.aas") -Encoding ASCII

  @'
{
"classname" "worldspawn"
"name" "world"
"objective" "Arrive at the second smoke room"
}
{
"classname" "info_player_start"
"name" "player_start_2"
"origin" "16 16 64"
"angle" "90"
}
{
"classname" "light"
"name" "light_smoke_2"
"origin" "48 48 96"
"light_radius" "96 96 96"
"_color" "0.4 0.6 0.9"
}
'@ | Set-Content -LiteralPath (Join-Path $base "maps/game/mars_city2.map") -Encoding ASCII

  @'
PROC "4"
model {
 "world"
 surface {
  material textures/smoke/trim
  numVerts 3
  numIndexes 3
 }
}
interAreaPortals {
 1 0
}
'@ | Set-Content -LiteralPath (Join-Path $base "maps/game/mars_city2.proc") -Encoding ASCII

  @'
CM "1"
collisionModel "world"
{
 vertices { 4 }
 edges { 4 }
 polygons { 1
  polygon { material textures/smoke/trim contents solid plane 1 0 0 -32 }
 }
 brushes { 1 }
}
'@ | Set-Content -LiteralPath (Join-Path $base "maps/game/mars_city2.cm") -Encoding ASCII

  [System.IO.File]::WriteAllBytes((Join-Path $base "textures/smoke/panel_d.tga"), (New-TgaBytes -Width 64 -Height 64 -BitsPerPixel 32))
  [System.IO.File]::WriteAllBytes((Join-Path $base "textures/smoke/trim_d.tga"), (New-TgaBytes -Width 128 -Height 64 -BitsPerPixel 24))
  [System.IO.File]::WriteAllBytes((Join-Path $base "textures/smoke/trim_local.tga"), (New-TgaBytes -Width 128 -Height 64 -BitsPerPixel 24))
  [System.IO.File]::WriteAllBytes((Join-Path $base "textures/smoke/trim_s.dds"), (New-DdsDxt1Bytes -Width 128 -Height 64 -MipLevels 4))
  [System.IO.File]::WriteAllBytes((Join-Path $base "textures/smoke/trim_editor.tga"), (New-TgaBytes -Width 32 -Height 32 -BitsPerPixel 24))
  @'
MD5Version 10
commandline "generated smoke fixture"
numJoints 1
numMeshes 1
joints {
 "origin" -1 ( 0 0 0 ) ( 0 0 0 )
}
mesh {
 shader "textures/smoke/panel"
 numverts 3
 vert 0 ( 0 0 ) 0 1
 vert 1 ( 1 0 ) 1 1
 vert 2 ( 0 1 ) 2 1
 numtris 1
 tri 0 0 1 2
 numweights 3
 weight 0 0 1.0 ( 0 0 0 )
 weight 1 0 1.0 ( 16 0 0 )
 weight 2 0 1.0 ( 0 16 0 )
}
'@ | Set-Content -LiteralPath (Join-Path $base "models/monsters/smoke/smoke.md5mesh") -Encoding ASCII
  Set-Content -LiteralPath (Join-Path $base "models/pickups/health/health.md5mesh") -Value "placeholder" -Encoding ASCII
  Set-Content -LiteralPath (Join-Path $base "models/pickups/ammo/bullets.md5mesh") -Value "placeholder" -Encoding ASCII
  Set-Content -LiteralPath (Join-Path $base "models/weapons/pistol/pickup.md5mesh") -Value "placeholder" -Encoding ASCII
  Set-Content -LiteralPath (Join-Path $base "models/weapons/pistol/projectile.md5mesh") -Value "placeholder" -Encoding ASCII
  @'
MD5Version 10
commandline "generated smoke anim"
numFrames 2
numJoints 1
frameRate 24
numAnimatedComponents 6
hierarchy {
 "origin" -1 63 0
}
bounds {
 ( -16 -16 0 ) ( 16 16 64 )
 ( -16 -16 0 ) ( 16 16 64 )
}
baseframe {
 ( 0 0 0 ) ( 0 0 0 )
}
frame 0 {
 0 0 0 0 0 0
}
frame 1 {
 2 0 0 0 0 0
}
'@ | Set-Content -LiteralPath (Join-Path $base "models/monsters/smoke/idle.md5anim") -Encoding ASCII
  @'
sound/monsters/smoke/sight
{
 sound/monsters/smoke/sight.wav
}
sound/world/door_open
{
 sound/world/door_open.wav
}
'@ | Set-Content -LiteralPath (Join-Path $base "sound/smoke.sndshd") -Encoding ASCII
  [System.IO.File]::WriteAllBytes((Join-Path $base "sound/monsters/smoke/sight.wav"), (New-WavBytes -SampleRate 22050 -Channels 1 -BitsPerSample 16 -DurationMs 100))
  [System.IO.File]::WriteAllBytes((Join-Path $base "sound/monsters/smoke/alert.wav"), (New-WavBytes -SampleRate 22050 -Channels 1 -BitsPerSample 16 -DurationMs 100))
  [System.IO.File]::WriteAllBytes((Join-Path $base "sound/world/door_open.wav"), (New-WavBytes -SampleRate 44100 -Channels 2 -BitsPerSample 16 -DurationMs 100))
  New-Item -ItemType Directory -Force -Path (Join-Path $base "sound/weapons/pistol") | Out-Null
  [System.IO.File]::WriteAllBytes((Join-Path $base "sound/weapons/pistol/fire.wav"), (New-WavBytes -SampleRate 44100 -Channels 2 -BitsPerSample 16 -DurationMs 100))
  Set-Content -LiteralPath (Join-Path $base "video/smoke_intro.roq") -Value "RoQ!seed7 placeholder cinematic" -Encoding ASCII

  @'
seta com_fixedTic "16"
seta com_maxfps "60"
seta com_showfps "1"
bind "w" "_forward"
bind "mouse1" "_attack"
bind "e" "_use"
bind "escape" "togglemenu"
'@ | Set-Content -LiteralPath (Join-Path $base "config/default.cfg") -Encoding ASCII

  $zip = Join-Path $base "pak000.zip"
  $pk4 = Join-Path $base "pak000.pk4"
  Compress-Archive -Path (Join-Path $base "maps"), (Join-Path $base "materials"), (Join-Path $base "def"), (Join-Path $base "fx"), (Join-Path $base "particles"), (Join-Path $base "script"), (Join-Path $base "config"), (Join-Path $base "guis"), (Join-Path $base "strings"), (Join-Path $base "pda"), (Join-Path $base "skins"), (Join-Path $base "textures"), (Join-Path $base "video"), (Join-Path $base "models"), (Join-Path $base "sound") -DestinationPath $zip -Force
  Move-Item -LiteralPath $zip -Destination $pk4 -Force
  return $root
}

function New-Doom3Seed7OverrideFixture {
  $root = New-Doom3Seed7Fixture -Name "doom3-seed7-override-fixture"
  $base = Join-Path $root "base"
  $overrideRoot = Join-Path $root "override-src"
  New-Item -ItemType Directory -Force -Path (Join-Path $overrideRoot "maps/game") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $overrideRoot "materials") | Out-Null

  @'
Version 2
{
"classname" "worldspawn"
"name" "world"
}
{
"classname" "info_player_start"
"name" "override_player_start"
"origin" "256 0 64"
"angle" "90"
}
'@ | Set-Content -LiteralPath (Join-Path $overrideRoot "maps/game/mars_city1.map") -Encoding ASCII

  @'
textures/smoke/panel
{
 qer_editorimage textures/smoke/panel_override
 diffusemap textures/smoke/panel_override_d
}
'@ | Set-Content -LiteralPath (Join-Path $overrideRoot "materials/smoke.mtr") -Encoding ASCII

  $zip = Join-Path $base "pak001.zip"
  $pk4 = Join-Path $base "pak001.pk4"
  Compress-Archive -Path (Join-Path $overrideRoot "maps"), (Join-Path $overrideRoot "materials") -DestinationPath $zip -Force
  Move-Item -LiteralPath $zip -Destination $pk4 -Force
  return $root
}

if ($GenerateFixtureOnly) {
  $generatedRoot = New-Doom3Seed7Fixture -Name "doom3-seed7-browser-fixture"
  $generatedBase = Join-Path $generatedRoot "base"
  $sourcePk4 = Join-Path $generatedBase "pak000.pk4"
  $targetBase = $GeneratedFixtureOut

  New-Item -ItemType Directory -Force -Path $targetBase | Out-Null
  Copy-Item -LiteralPath $sourcePk4 -Destination (Join-Path $targetBase "pak000.pk4") -Force
  Write-Host "Generated synthetic Doom3 Seed7 fixture:"
  Write-Host "  $(Join-Path $targetBase "pak000.pk4")"
  exit 0
}

Invoke-Doom3Seed7 -Label "help" -ArgsToPass @("--help") -MustContain @(
  "Usage:",
  "No commercial assets are bundled"
)

Invoke-Doom3Seed7 -Label "inventory subsystem help" -Entry $InventoryEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_inventory.s7",
  "pickup/inventory readiness"
)

Invoke-Doom3Seed7 -Label "combat subsystem help" -Entry $CombatEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_combat.s7",
  "combat readiness"
)

Invoke-Doom3Seed7 -Label "ai subsystem help" -Entry $AiEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_ai.s7",
  "monster AI readiness"
)

Invoke-Doom3Seed7 -Label "objective subsystem help" -Entry $ObjectiveEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_objective.s7",
  "objective/progression readiness"
)

Invoke-Doom3Seed7 -Label "level subsystem help" -Entry $LevelEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_level.s7",
  "level transition readiness"
)

Invoke-Doom3Seed7 -Label "model subsystem help" -Entry $ModelEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_model.s7",
  "modelDef readiness"
)

Invoke-Doom3Seed7 -Label "pose subsystem help" -Entry $PoseEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_pose.s7",
  "skeletal pose/skinning readiness"
)

Invoke-Doom3Seed7 -Label "weapon subsystem help" -Entry $WeaponEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_weapon.s7",
  "weapon/projectile readiness"
)

Invoke-Doom3Seed7 -Label "projectile subsystem help" -Entry $ProjectileEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_projectile.s7",
  "projectile runtime readiness"
)

Invoke-Doom3Seed7 -Label "fx subsystem help" -Entry $FxEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_fx.s7",
  "FX/particle readiness"
)

Invoke-Doom3Seed7 -Label "cinematic subsystem help" -Entry $CinematicEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_cinematic.s7",
  "cinematic/video readiness"
)

Invoke-Doom3Seed7 -Label "gui subsystem help" -Entry $GuiEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_gui.s7",
  "GUI/HUD readiness"
)

Invoke-Doom3Seed7 -Label "sound subsystem help" -Entry $SoundEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_sound.s7",
  "sound subsystem readiness"
)

Invoke-Doom3Seed7 -Label "audio subsystem help" -Entry $AudioEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_audio.s7",
  "audio metadata readiness"
)

Invoke-Doom3Seed7 -Label "aas subsystem help" -Entry $AasEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_aas.s7",
  "AAS/navigation readiness"
)

Invoke-Doom3Seed7 -Label "script subsystem help" -Entry $ScriptEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_script.s7",
  "script binding readiness"
)

Invoke-Doom3Seed7 -Label "scheduler subsystem help" -Entry $SchedulerEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_scheduler.s7",
  "script scheduler readiness"
)

Invoke-Doom3Seed7 -Label "trace subsystem help" -Entry $TraceEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_trace.s7",
  "world trace readiness"
)

Invoke-Doom3Seed7 -Label "vfs subsystem help" -Entry $VfsEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_vfs.s7",
  "VFS override readiness"
)

Invoke-Doom3Seed7 -Label "platform subsystem help" -Entry $PlatformEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_platform.s7",
  "platform config, cvars, binds, timing, and input readiness"
)

Invoke-Doom3Seed7 -Label "console subsystem help" -Entry $ConsoleEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_console.s7",
  "console command-buffer readiness"
)

Invoke-Doom3Seed7 -Label "localization subsystem help" -Entry $LangEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_lang.s7",
  "localization/string-table readiness"
)

Invoke-Doom3Seed7 -Label "pda subsystem help" -Entry $PdaEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_pda.s7",
  "PDA/email/audio-log readiness"
)

Invoke-Doom3Seed7 -Label "access subsystem help" -Entry $AccessEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_access.s7",
  "PDA/security access readiness"
)

Invoke-Doom3Seed7 -Label "armor subsystem help" -Entry $ArmorEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_armor.s7",
  "armor/damage mitigation readiness"
)

Invoke-Doom3Seed7 -Label "survival subsystem help" -Entry $SurvivalEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_survival.s7",
  "armor-aware survival-loop readiness"
)

Invoke-Doom3Seed7 -Label "campaign subsystem help" -Entry $CampaignEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_campaign.s7",
  "campaign load/restart flow readiness"
)

Invoke-Doom3Seed7 -Label "playloop subsystem help" -Entry $PlayloopEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_runtime.s7",
  "end-to-end playable-loop readiness"
)

Invoke-Doom3Seed7 -Label "math subsystem help" -Entry $MathEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_math.s7",
  "vector, plane, bounds, yaw-basis, and frustum math readiness"
)

Invoke-Doom3Seed7 -Label "parser subsystem help" -Entry $ParserEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_parser.s7",
  "lexer/parser readiness"
)

Invoke-Doom3Seed7 -Label "decl subsystem help" -Entry $DeclEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_decl.s7",
  "declaration registry readiness"
)

Invoke-Doom3Seed7 -Label "resource subsystem help" -Entry $ResourceEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_resource.s7",
  "resource manager readiness"
)

Invoke-Doom3Seed7 -Label "texture subsystem help" -Entry $TextureEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_texture.s7",
  "texture metadata readiness"
)

Invoke-Doom3Seed7 -Label "material subsystem help" -Entry $MaterialEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_material.s7",
  "material compatibility readiness"
)

Invoke-Doom3Seed7 -Label "lighting subsystem help" -Entry $LightingEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_lighting.s7",
  "lighting/shadow readiness"
)

Invoke-Doom3Seed7 -Label "session subsystem help" -Entry $SessionEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_session.s7",
  "session/loading flow readiness"
)

Invoke-Doom3Seed7 -Label "save subsystem help" -Entry $SaveEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_save.s7",
  "save/restore readiness"
)

Invoke-Doom3Seed7 -Label "physics subsystem help" -Entry $PhysicsEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_physics.s7",
  "player physics readiness"
)

Invoke-Doom3Seed7 -Label "interaction subsystem help" -Entry $InteractionEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_interaction.s7",
  "player interaction readiness"
)

Invoke-Doom3Seed7 -Label "spawn subsystem help" -Entry $SpawnEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_spawn.s7",
  "entity spawn readiness"
)

Invoke-Doom3Seed7 -Label "mover subsystem help" -Entry $MoverEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_mover.s7",
  "mover/door readiness"
)

Invoke-Doom3Seed7 -Label "render subsystem help" -Entry $RenderEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_render.s7",
  "renderer-front-end readiness"
)

Invoke-Doom3Seed7 -Label "view subsystem help" -Entry $ViewEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_view.s7",
  "renderView/camera readiness"
)

Invoke-Doom3Seed7 -Label "submit subsystem help" -Entry $SubmitEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_submit.s7",
  "frame-to-render submission readiness"
)

Invoke-Doom3Seed7 -Label "compiled map subsystem help" -Entry $CompiledMapEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_compiledmap.s7",
  "compiled .proc/.cm map readiness"
)

Invoke-Doom3Seed7 -Label "frame subsystem help" -Entry $FrameEntry -ArgsToPass @("--help") -MustContain @(
  "doom3_seed7_frame.s7",
  "game-frame readiness"
)

Assert-FileContains -Path "doom3.html" -Needle $LauncherProbeNeedle -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "doom3_seed7_engine.s7" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "generated/doom3_seed7/manifest.txt" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "accept=`".pk4,.zip`"" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "Doom3 Seed7 Engine Shell" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "Launch" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "ensureDir('/doom3/base')" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "seed7UseDocumentCanvas: true" -Label "browser launcher"
Assert-FileContains -Path "doom3.html" -Needle "'--doom3_data_path', '/doom3'" -Label "browser launcher"
Assert-FileContains -Path "index.html" -Needle "doom3.html" -Label "doom3 launcher link"

Invoke-Doom3Seed7 -Label "missing assets error path" -ArgsToPass @(
  "--doom3_data_path",
  "missing-doom3-root",
  "--set",
  "com_showfps",
  "1"
) -MustContain @(
  "[error] Doom 3 base directory not found:",
  "[error] Expected a legal install path containing base/*.pk4",
  "first_custom_cvar=com_showfps=1"
)

$GeneratedFixture = New-Doom3Seed7Fixture
Invoke-Doom3Seed7 -Label "generated fixture assets" -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "target_compiled_assets proc=maps/game/mars_city1.proc cm=maps/game/mars_city1.cm",
  "compiled_assets proc=2 cm=2",
  "selected_compiled_map proc_found=TRUE cm_found=TRUE",
  "image_refs=6 image_assets=5 unique_image_assets=5",
  "entity_defs=7 named_entity_defs=7 unique_entity_defs=7",
  "entity_def_spawnargs health=1 model=6 sound=2 inherit=1 bounds=1",
  "material_decls=3 unique_materials=3",
  "material_texture_bindings=1 material_records=1",
  "material_flags noshadows=1 twosided=1 translucent=1 blend_stages=1",
  "script_functions=2 script_spawnargs=2",
  "map_brushes=2 map_patches=2",
  "map_classes light=2 func_static=0 door=1 trigger=1 monster=1",
  "map_classes item=1 pickup=2 player_start=2",
  "selected_map_entities=9 spawn_ready=8 named=9",
  "selected_map_keys origin=8 model=0 target=1 bounds=0",
  "selected_target_refs=1 unique=1 named_entities=9 resolved=1 missing=0",
  "runtime_entities=8 active=8 origin=8 solid=2 trigger=1 hostile=1",
  "runtime_entity_kinds player_spawn=1 light=1 static=0 door=1 trigger=1 monster=1 pickup=3",
  "runtime_custom_health_entities=1",
  "runtime_map_overrides health=0 sound=2",
  "runtime_sound_refs=3 unique=3 available=3 missing=0",
  "selected_lights=1 origin=1 radius=1 color=1",
  "first_light_name=light_smoke_1",
  "render_queue_lit_surfaces=1",
  "nearest_render_surface_lights=1",
  "nearest_render_surface_light_color=0.8 0.7 0.5",
  "surface_materials brush_refs=12 brush_unique=2 brush_declared=2 brush_missing=0",
  "surface_materials patch_refs=2 patch_unique=2 patch_declared=2 patch_missing=0",
  "touched_triggers=1",
  "first_touched_trigger=trigger_open_door",
  "first_touched_trigger_target=door_smoke_1",
  "activated_runtime_doors=1",
  "first_activated_door=door_smoke_1",
  "first_render_surface_texture_available=TRUE",
  "Stage 1 asset pipeline complete."
)

$OverrideFixture = New-Doom3Seed7OverrideFixture
Invoke-Doom3Seed7 -Label "pk4 override fixture assets" -Entry $VfsEntry -ArgsToPass @(
  "--doom3_data_path",
  $OverrideFixture
) -MustContain @(
  "pk4_archives=2",
  "pak000.pk4",
  "pak001.pk4",
  "selected_map_archive=",
  "player_start_origin=256 0 64",
  "player_spawn_x=256.0",
  "player_spawn_yaw=90.0",
  "vfs_override_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture platform subsystem" -Entry $PlatformEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture,
  "--doom3_save_path",
  "smoke/save",
  "--doom3_config_path",
  "smoke/config",
  "+set",
  "in_portable",
  "1",
  "+bind",
  "q",
  "_use",
  "+map",
  "game/mars_city1"
) -MustContain @(
  "pk4_archives=1",
  "save_path=smoke/save",
  "config_path=smoke/config",
  "config_files=1",
  "config_cvars=3",
  "config_binds=4",
  "command_buffer total=10 cfg=7 cli=3",
  "command_kinds set=4 bind=5 map=1",
  "first_config_file=config/default.cfg",
  "first_config_cvar=com_fixedTic=16",
  "first_config_bind=w=_forward",
  "first_cli_cvar=in_portable=1",
  "first_cli_bind=q=_use",
  "first_command=cfg:set",
  "command_path=cfg:set>cfg:set>cfg:set>cfg:bind>cfg:bind>cfg:bind>cfg:bind>cli:set>cli:bind>cli:map",
  "timing frame_msec=16 maxfps=60",
  "input_events=4 actions=4",
  "first_input_action=w=_forward",
  "input_state forward=TRUE attack=TRUE use=TRUE pause=TRUE",
  "platform_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture console subsystem" -Entry $ConsoleEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture,
  "+exec",
  "config/default.cfg",
  "+alias",
  "launch",
  "devmap game/mars_city1; wait",
  "+launch",
  "+unknowncmd"
) -MustContain @(
  "pk4_archives=1",
  "config_files=1",
  "command_buffer queued=4",
  "command_parse semicolon=1",
  "command_kinds set=6 bind=8",
  "devmap=1 exec=1",
  "wait=1 alias=1 unsupported=1",
  "console_state cvars=3 binds=4 aliases=1 final_map=game/mars_city1 devmap=TRUE",
  "first_config_file=config/default.cfg",
  "first_queued_command=cli:exec config/default.cfg",
  "first_executed_command=cfg:set",
  "first_console_cvar=com_fixedTic=16",
  "first_console_bind=w=_forward",
  "first_alias=launch=devmap game/mars_city1; wait",
  "first_alias_expansion=launch=devmap game/mars_city1; wait",
  "first_exec=config/default.cfg",
  "first_unsupported_command=unknowncmd",
  "console_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture localization subsystem" -Entry $LangEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "language=english",
  "lang_files total=1 selected=1",
  "lang_entries raw=5 unique=5 overrides=0",
  "localized_refs files=",
  "refs=4 unique=4 resolved=3 missing=1",
  "localized_ref_kinds gui=4 map=0 def=0 material=0",
  "placeholder_strings=1",
  "first_lang_file=strings/english.lang",
  "first_lang_key=#str_00001",
  "first_lang_value=Health",
  "first_localized_ref=#str_00001",
  "first_resolved_ref=#str_00001",
  "first_resolved_text=Health",
  "first_missing_ref=#str_99999",
  "first_gui_lang_ref=#str_00001",
  "lang_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture pda subsystem" -Entry $PdaEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "language=english",
  "pda_assets=1",
  "pda_defs=1 email=1 audio=1 video=1",
  "pda_refs sound=1 resolved=1 missing=0",
  "pda_refs video=1 resolved=1 missing=0",
  "pda_refs gui=1 resolved=1 missing=0",
  "pda_refs lang=3 resolved=3 missing=0",
  "pda_runtime entries=3 placeholders=0",
  "first_pda_asset=pda/smoke_security.pda",
  "first_pda_def=smoke_security",
  "first_pda_email=mail_smoke_access",
  "first_pda_audio=audio_smoke_log",
  "first_pda_video=video_smoke_intro",
  "first_pda_sound_ref=sound/monsters/smoke/sight.wav",
  "first_pda_video_ref=video/smoke_intro.roq",
  "first_pda_gui_ref=guis/hud.gui",
  "first_pda_lang_ref=#str_00002",
  "first_pda_lang_text=Smoke Access",
  "pda_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture access subsystem" -Entry $AccessEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map=maps/game/mars_city1.map",
  "requested_map_found=TRUE",
  "pda_assets=1 pda_defs=1",
  "authorization_tokens=1 unique_doors=1",
  "selected_map entities=9 doors=1 triggers=1 trigger_targets=1",
  "authorization_resolution resolved=1 missing=0 trigger_linked=1",
  "runtime_access locked_doors=1 unlocked_doors=1",
  "first_access_pda_asset=pda/smoke_security.pda",
  "first_access_pda=smoke_security",
  "first_authorized_door=door_smoke_1",
  "first_map_door=door_smoke_1",
  "first_access_trigger_target=door_smoke_1",
  "first_resolved_authorization=door_smoke_1",
  "first_unlocked_door=door_smoke_1",
  "first_access_path=pda>smoke_security>door>door_smoke_1",
  "access_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture armor subsystem" -Entry $ArmorEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map=maps/game/mars_city1.map",
  "requested_map_found=TRUE",
  "armor_collision cm=maps/game/mars_city1.cm found=TRUE models=1 polygons=2",
  "pda_armor assets=1 armor_entries=1 protection_entries=1",
  "armor_state initial=50 protection_percent=60",
  "damage_defs entity_defs=7 melee_damage_defs=1 first_damage=12",
  "selected_map entities=9 player_starts=1 monsters=1",
  "damage_resolution raw=12 armor_absorbed=7 health_damage=5 collision_ready=TRUE",
  "player_state health_before=100 armor_before=50 health_after=95 armor_after=43",
  "hud_armor_value=43",
  "hud_armor_bar=****",
  "first_armor_pda_asset=pda/smoke_security.pda",
  "first_armor_source=pda/smoke_security.pda",
  "first_damage_def=monster_smoke_base",
  "first_armor_player_start=player_start_1",
  "first_armor_monster_class=monster_smoke_child",
  "first_armor_path=damage>12>armor>7>health>5",
  "armor_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture survival subsystem" -Entry $SurvivalEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map=maps/game/mars_city1.map",
  "requested_map_found=TRUE",
  "survival_pda assets=1 armor_entries=1 protection_entries=1",
  "survival_defs entity_defs=7 health=1 inherit=1 melee_damage=1",
  "survival_weapon_defs weapons=1 projectiles=1 projectile_damage=1",
  "survival_map_catalog assets=2 unique=2",
  "survival_map entities=9 player_starts=1 monsters=1 weapons=1 ammo=1",
  "survival_nextmap refs=1 path=maps/game/mars_city2.map found=TRUE player_starts=1",
  "survival_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "survival_skill level=1 name=marine damage_percent=100 nightmare_health_floor=0",
  "survival_state health_before=100 armor_before=50 armor_protection=60 ammo_after_pickups=12",
  "survival_combat ticks=6 shots=6 hits=6 monster_attacks=5",
  "survival_damage shot=25 monster_base=12 monster_scaled=12 armor_absorbed=35 health_damage=25",
  "survival_result health_after=75 armor_after=15 ammo_after=6 monster_health_after=0 monster_alive=FALSE clear_ready=TRUE terminal=clear",
  "survival_transition_state=ready",
  "survival_post_terminal action=load_next target=maps/game/mars_city2.map player_start_ready=TRUE health=75 armor=15 ammo=6 monster_health=0",
  "survival_save_snapshot=map=maps/game/mars_city1.map;skill=1;health=75;armor=15;ammo=6;monster_health=0;monster_alive=FALSE;clear=TRUE;terminal=clear;next_map=maps/game/mars_city2.map;transition=ready;post_action=load_next;post_map=maps/game/mars_city2.map;post_health=75;post_ammo=6",
  "survival_restore verified=TRUE health=75 armor=15 ammo=6 skill=1 monster_health=0 clear=TRUE terminal=clear transition=ready post_action=load_next post_map=maps/game/mars_city2.map",
  "hud_health_value=75",
  "hud_health_bar=#######...",
  "hud_armor_value=15",
  "hud_armor_bar=###.......",
  "first_survival_pda_asset=pda/smoke_security.pda",
  "first_survival_armor_source=pda/smoke_security.pda",
  "first_survival_damage_def=monster_smoke_base",
  "first_survival_projectile_def=projectile_smoke_round",
  "first_survival_player_start=player_start_1",
  "first_survival_monster_class=monster_smoke_child",
  "first_survival_weapon_class=weapon_pistol",
  "first_survival_ammo_class=ammo_bullets",
  "first_survival_path=spawn>pickup>armor>combat>clear",
  "survival_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture nightmare survival subsystem" -Entry $SurvivalEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture,
  "+set",
  "g_skill",
  "3"
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "survival_map_catalog assets=2 unique=2",
  "survival_nextmap refs=1 path=maps/game/mars_city2.map found=TRUE player_starts=1",
  "survival_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "survival_skill level=3 name=nightmare damage_percent=200 nightmare_health_floor=25",
  "survival_damage shot=25 monster_base=12 monster_scaled=24 armor_absorbed=50 health_damage=70",
  "survival_result health_after=30 armor_after=0 ammo_after=6 monster_health_after=0 monster_alive=FALSE clear_ready=TRUE terminal=clear",
  "survival_transition_state=ready",
  "survival_post_terminal action=load_next target=maps/game/mars_city2.map player_start_ready=TRUE health=30 armor=0 ammo=6 monster_health=0",
  "survival_save_snapshot=map=maps/game/mars_city1.map;skill=3;health=30;armor=0;ammo=6;monster_health=0;monster_alive=FALSE;clear=TRUE;terminal=clear;next_map=maps/game/mars_city2.map;transition=ready;post_action=load_next;post_map=maps/game/mars_city2.map;post_health=30;post_ammo=6",
  "survival_restore verified=TRUE health=30 armor=0 ammo=6 skill=3 monster_health=0 clear=TRUE terminal=clear transition=ready post_action=load_next post_map=maps/game/mars_city2.map",
  "hud_health_value=30",
  "hud_health_bar=###.......",
  "hud_armor_value=0",
  "hud_armor_bar=..........",
  "first_survival_path=spawn>pickup>armor>combat>clear",
  "survival_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture death survival subsystem" -Entry $SurvivalEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture,
  "--doom3_player_health",
  "20",
  "--doom3_player_armor",
  "0",
  "+set",
  "g_skill",
  "3"
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "survival_map_catalog assets=2 unique=2",
  "survival_nextmap refs=1 path=maps/game/mars_city2.map found=TRUE player_starts=1",
  "survival_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "survival_skill level=3 name=nightmare damage_percent=200 nightmare_health_floor=25",
  "survival_state health_before=20 armor_before=0 armor_protection=60 ammo_after_pickups=12",
  "survival_combat ticks=6 shots=6 hits=6 monster_attacks=5",
  "survival_damage shot=25 monster_base=12 monster_scaled=24 armor_absorbed=0 health_damage=120",
  "survival_result health_after=0 armor_after=0 ammo_after=6 monster_health_after=0 monster_alive=FALSE clear_ready=FALSE terminal=dead",
  "survival_transition_state=failed",
  "survival_post_terminal action=restart_current target=maps/game/mars_city1.map player_start_ready=TRUE health=20 armor=0 ammo=0 monster_health=150",
  "survival_save_snapshot=map=maps/game/mars_city1.map;skill=3;health=0;armor=0;ammo=6;monster_health=0;monster_alive=FALSE;clear=FALSE;terminal=dead;next_map=maps/game/mars_city2.map;transition=failed;post_action=restart_current;post_map=maps/game/mars_city1.map;post_health=20;post_ammo=0",
  "survival_restore verified=TRUE health=0 armor=0 ammo=6 skill=3 monster_health=0 clear=FALSE terminal=dead transition=failed post_action=restart_current post_map=maps/game/mars_city1.map",
  "hud_health_value=0",
  "hud_health_bar=..........",
  "hud_armor_value=0",
  "hud_armor_bar=..........",
  "first_survival_path=spawn>pickup>armor>combat>dead",
  "survival_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture campaign subsystem" -Entry $CampaignEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "map_catalog assets=2 unique=2",
  "requested_map_found=TRUE",
  "current_map entities=9 player_start=1 objectives=1 monsters=1 doors=1 triggers=1",
  "next_map declared=TRUE path=maps/game/mars_city2.map found=TRUE player_start=1",
  "campaign_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "campaign_load state=current_loaded first_player_start=player_start_1",
  "campaign_clear action=load_next target=maps/game/mars_city2.map target_ready=TRUE carry_health=75 carry_ammo=6",
  "campaign_death action=restart_current target=maps/game/mars_city1.map target_ready=TRUE checkpoint_health=100 checkpoint_ammo=0",
  "campaign_path=boot>load_current>run_current>clear>autosave>load_next>spawn_next|death>checkpoint>restart_current>spawn_current",
  "campaign_restore clear=TRUE death=TRUE",
  "first_campaign_next_player_start=player_start_2",
  "first_campaign_clear_snapshot=slot=autosave0;version=1;map=maps/game/mars_city1.map;terminal=clear;post_action=load_next;post_map=maps/game/mars_city2.map;post_player_start=player_start_2;health=75;ammo=6",
  "first_campaign_death_snapshot=slot=checkpoint0;version=1;map=maps/game/mars_city1.map;terminal=dead;post_action=restart_current;post_map=maps/game/mars_city1.map;post_player_start=player_start_1;health=100;ammo=0",
  "campaign_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture playloop subsystem" -Entry $PlayloopEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "playloop_assets maps=2 proc=2 cm=2 gui=2 sounds=4 models=6",
  "playloop_compiled_selected proc=TRUE cm=TRUE proc_path=maps/game/mars_city1.proc cm_path=maps/game/mars_city1.cm",
  "playloop_input binds=4 forward=TRUE attack=TRUE use=TRUE pause=TRUE",
  "playloop_menu guis=1 actions=4 start=TRUE resume=TRUE restart=TRUE quit=TRUE ready=TRUE",
  "playloop_map entities=9 player_start=1 monsters=1 weapons=1 ammo=1 health=1 doors=1 triggers=1",
  "playloop_nextmap refs=1 path=maps/game/mars_city2.map found=TRUE player_start=1",
  "playloop_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "playloop_runtime session=TRUE input=TRUE gameplay=TRUE render=TRUE audio=TRUE hud=TRUE",
  "playloop_ticks ticks=6 movement=4 attack=6 use=1 render_frames=1 audio_events=3 hud_frames=1",
  "playloop_result health=75 ammo=6 enemies=0 clear=TRUE screen=cleared transition=ready",
  "playloop_path=load>input>move>use>attack>script>audio>render>hud>clear>load_next",
  "playloop_submit=view>world_surfaces>animated_actor>weapon_view>hud",
  "playloop_hud=health=75;ammo=6;enemies=0;screen=cleared",
  "playloop_present mode=browser_native size=640x360 passes=clear>world>actor>weapon>hud>swap ready=TRUE",
  "playloop_present_frame hash=10046 mid_row=.....******E*****.......",
  "playloop_transition_load action=load_next map=maps/game/mars_city2.map player_start=player_start_2 ready=TRUE",
  "playloop_post_transition screen=running health=75 ammo=6 frame_hash=5204 mid_row=...P....L....",
  "playloop_runtime_frames presented=2 hashes=10046>5204 ready=TRUE",
  "playloop_session_control path=running>pause>menu>resume>quicksave>running pause_frames=1 resumed_frames=1 ready=TRUE",
  "playloop_quicksave hash=9724 restore=TRUE snapshot=slot=quick0;map=maps/game/mars_city2.map;player_start=player_start_2;health=75;ammo=6;screen=running",
  "playloop_restart action=restart_current map=maps/game/mars_city1.map player_start=player_start_1 ready=TRUE",
  "playloop_restart_snapshot hash=10276 restore=TRUE snapshot=slot=checkpoint0;map=maps/game/mars_city1.map;player_start=player_start_1;health=100;ammo=0;screen=running",
  "playloop_restart_frame hash=10883 mid_row=...P..C.....",
  "first_playloop_next_player_start=player_start_2",
  "playloop_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "math subsystem deterministic contract" -Entry $MathEntry -ArgsToPass @() -MustContain @(
  "math_yaw=0.0",
  "vec_delta=64.0 32.0 0.0",
  "vec_delta_length_sq=5120.0",
  "yaw_forward=1.0 0.0 0.0",
  "yaw_right=0.0 1.0 0.0",
  "moved_point=160.0 0.0 64.0",
  "plane_distance_at_64=0.0",
  "segment_plane_hit=TRUE fraction_pct=50.0",
  "bounds_contains_player=TRUE",
  "expanded_bounds_min=160.0 0.0 32.0",
  "expanded_bounds_max=224.0 64.0 112.0",
  "bounds_intersect=TRUE",
  "frustum forward_dot=64.0 side_dot=32.0 visible=TRUE",
  "math_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture parser subsystem" -Entry $ParserEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "parser_files tokenized=6 maps=1 defs=1 materials=1 scripts=1 guis=2",
  "lexer_tokens total=853 quoted=152 words=701 braces=43/43 parens=82/82",
  "lexer_comments line=1 block=1",
  "parser_map entities=9 key_values=37 classnames=9",
  "parser_decls entityDef=7 materials=3",
  "parser_scripts functions=2 gui_windows=7",
  "first_tokenized_file=def/monsters.def",
  "first_token=entityDef",
  "first_quoted_token=spawnclass",
  "first_map_classname=worldspawn",
  "first_map_key_value=classname=worldspawn",
  "first_entityDef_decl=monster_smoke_base",
  "first_material_decl=textures/smoke/panel",
  "first_script_function=init",
  "first_gui_windowDef=Desktop",
  "parser_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture decl subsystem" -Entry $DeclEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "decl_files=4",
  "decl_registry raw=14 unique=14 overrides=0",
  "decl_types material=3 entityDef=7 skin=1 sound=2 model=1",
  "decl_details inherited_entityDefs=1 material_stages=4 skin_remaps=2 sound_samples=2",
  "first_decl_file=def/monsters.def",
  "first_decl_key=entityDef:monster_smoke_base",
  "first_material_decl=textures/smoke/panel",
  "first_entityDef_decl=monster_smoke_base",
  "first_skin_decl=skin_smoke_burned",
  "first_sound_decl=sound/monsters/smoke/sight",
  "first_model_decl=model_smoke_imp",
  "decl_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "pk4 override decl registry" -Entry $DeclEntry -ArgsToPass @(
  "--doom3_data_path",
  $OverrideFixture
) -MustContain @(
  "pk4_archives=2",
  "decl_registry raw=15 unique=14 overrides=1",
  "first_override_key=material:textures/smoke/panel",
  "pak001.pk4",
  "decl_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture resource subsystem" -Entry $ResourceEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "asset_catalog images=5 sounds=4 models=6 guis=2 scripts=1",
  "resource_decls skins=1 sound_shaders=2",
  "resource_textures refs=5 resolved=5 missing=0",
  "resource_models refs=6 resolved=6 missing=0",
  "resource_sounds refs=6 resolved=6 missing=0",
  "resource_gui refs=2 resolved=2 missing=0",
  "resource_skins refs=1 resolved=1 missing=0",
  "placeholder_resources=0",
  "first_resolved_texture=textures/smoke/panel_d",
  "first_resolved_model=models/monsters/smoke/smoke",
  "first_resolved_sound=sound/monsters/smoke/sight",
  "first_resolved_gui=guis/hud.gui",
  "first_resolved_skin=skin_smoke_burned",
  "resource_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "pk4 override resource placeholders" -Entry $ResourceEntry -ArgsToPass @(
  "--doom3_data_path",
  $OverrideFixture
) -MustContain @(
  "pk4_archives=2",
  "resource_textures refs=7 resolved=5 missing=2",
  "placeholder_resources=2",
  "first_missing_texture=textures/smoke/panel_override",
  "resource_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture texture subsystem" -Entry $TextureEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "texture_assets total=5 tga=4 dds=1 jpg=0 png=0",
  "texture_headers parsed=5 tga=4 dds=1 invalid=0",
  "texture_upload_plan compressed=1 uncompressed=4 mip_levels=4",
  "first_tga_texture=textures/smoke/panel_d.tga",
  "first_dds_texture=textures/smoke/trim_s.dds",
  "first_texture_summary=textures/smoke/panel_d.tga;format=tga;type=2;width=64;height=64;bpp=32",
  "texture_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture material subsystem" -Entry $MaterialEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "material_files=1",
  "material_decls raw=3 unique=3 overrides=0 renderer_ready=3 fallback=0",
  "material_stages blocks=1 blend=1 add=1 filter=0 fallback_blend=0",
  "material_images map=1 diffuse=1 bump=1 specular=1 editor=1",
  "material_transforms scroll=1 rotate=1 scale=0 animated=1 time_expr=0",
  "material_flags noshadows=1 twosided=1 translucent=1 nonsolid=1 sort=0",
  "unsupported_material_features programs=0 conditionals=0 cubemaps=0 deforms=0",
  "first_stage_texture=textures/smoke/panel_d",
  "first_compatibility_path=textures/smoke/panel:direct",
  "material_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "pk4 override material registry" -Entry $MaterialEntry -ArgsToPass @(
  "--doom3_data_path",
  $OverrideFixture
) -MustContain @(
  "pk4_archives=2",
  "material_files=2",
  "material_decls raw=4 unique=3 overrides=1 renderer_ready=4 fallback=0",
  "material_images map=1 diffuse=2 bump=1 specular=1 editor=2",
  "material_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture lighting subsystem" -Entry $LightingEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map=maps/game/mars_city1.map",
  "requested_map_found=TRUE",
  "lighting_materials total=3 shadow_casting=1 noshadows=1 translucent=1 nonsolid=1 twosided=1",
  "lighting_map entities=9 lights=1 radius=1 color=1 surfaces=4",
  "lighting_surfaces brush=2 patch=2 lit=4",
  "shadow_plan casters=1 suppressed=3 volumes=1 fallbacks=1",
  "first_light_name=light_smoke_1",
  "first_light_origin=32 32 96",
  "first_light_radius=160 160 160",
  "first_light_color=0.8 0.7 0.5",
  "first_lighting_material=textures/smoke/panel",
  "first_shadow_caster=textures/smoke/trim",
  "first_shadow_suppressed=textures/smoke/panel:noshadows",
  "first_shadow_plan=light=light_smoke_1;caster=textures/smoke/trim;mode=volume-fallback",
  "lighting_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture session subsystem" -Entry $SessionEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "map_catalog assets=2 unique=2",
  "session_assets guis=2 cfgs=1",
  "menu_assets guis=1 window_defs=5 actions=4",
  "menu_actions start=1 resume=1 restart=1 quit=1",
  "config_readiness cvars=3 binds=4 pause_bind=TRUE attack_bind=TRUE use_bind=TRUE",
  "selected_map entities=9 worldspawn=1 player_start=1",
  "selected_gui refs=1 resolved=1 missing=0",
  "next_map declared=TRUE path=maps/game/mars_city2.map found=TRUE player_start=1",
  "session_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "session_flow loading=loaded screen=running pause=paused restart=ready transition=ready",
  "first_menu_gui=guis/mainmenu.gui",
  "first_menu_action_path=mainmenu:start>resume>restart>quit",
  "first_session_path=boot>loading>running>pause>resume>save>restart>transition",
  "save_snapshot=map=maps/game/mars_city1.map;screen=running;pause=paused;restart=ready;transition=ready",
  "restore_verified=TRUE",
  "session_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "pk4 override session flow" -Entry $SessionEntry -ArgsToPass @(
  "--doom3_data_path",
  $OverrideFixture
) -MustContain @(
  "pk4_archives=2",
  "map_catalog assets=3 unique=2",
  "selected_map entities=2 worldspawn=1 player_start=1",
  "first_player_start=override_player_start",
  "next_map declared=FALSE path= found=FALSE player_start=0",
  "session_compiled_next proc=FALSE cm=FALSE proc_path= cm_path=",
  "session_flow loading=loaded screen=running pause=paused restart=ready transition=none",
  "session_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture save subsystem" -Entry $SaveEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture,
  "--doom3_save_path",
  "smoke/save"
) -MustContain @(
  "pk4_archives=1",
  "save_path=smoke/save",
  "requested_map_found=TRUE",
  "map_catalog assets=2 unique=2",
  "save_map entities=9 worldspawn=1 player_start=1 monsters=1 objectives=1",
  "save_slots total=3 autosave=1 quicksave=1 checkpoint=1",
  "save_transition next_declared=TRUE path=maps/game/mars_city2.map found=TRUE next_player_start=1",
  "save_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "save_transition_ready=TRUE",
  "save_snapshot bytes=",
  "save_manifest=autosave0=maps/game/mars_city1.map;quick0=maps/game/mars_city1.map;checkpoint0=maps/game/mars_city1.map",
  "checkpoint_manifest=checkpoint0=maps/game/mars_city1.map",
  "restore_verified=TRUE checksum=TRUE",
  "restore_state map=maps/game/mars_city1.map health=40 ammo=6 objective=TRUE screen=cleared",
  "checkpoint_restart action=restart_current target=maps/game/mars_city1.map player_start=player_start_1 health=100 ammo=0 verified=TRUE",
  "restart_snapshot bytes=",
  "restart_restore_verified=TRUE checksum=TRUE map=maps/game/mars_city1.map health=100 ammo=0",
  "first_save_player_start=player_start_1",
  "first_save_next_player_start=player_start_2",
  "first_save_snapshot=slot=autosave0;version=1;map=maps/game/mars_city1.map;save_path=smoke/save;player_start=player_start_1;health=40;ammo=6;objective_complete=TRUE;screen=cleared;next_map=maps/game/mars_city2.map;transition_ready=TRUE;next_proc=TRUE;next_cm=TRUE",
  "first_restart_snapshot=slot=checkpoint0;version=1;map=maps/game/mars_city1.map;save_path=smoke/save;player_start=player_start_1;health=100;ammo=0;objective_complete=FALSE;screen=running;post_action=restart_current;post_map=maps/game/mars_city1.map",
  "save_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture physics subsystem" -Entry $PhysicsEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "requested_cm_found=TRUE",
  "physics_map entities=9 player_start=1 brushes=2",
  "physics_materials decls=3 nonsolid=1",
  "physics_spawn name=player_start_1 origin=128 0 64 yaw=180",
  "physics_collision cm_found=TRUE models=1 polygons=2 brushes=1",
  "physics_collision_classification blocking=1 nonblocking=1 planes=2",
  "physics_cm_identity version=1 model=world",
  "first_physics_collision_plane=normal=1 0 0;dist=-64",
  "first_physics_collision_material=textures/smoke/panel;blocking=TRUE",
  "physics_contacts floor=TRUE ground_z=0 player_height=64",
  "physics_move frames=4 attempted=4 accepted=3 blocked=1",
  "physics_response slide=1 step_up=1 step_height=16 clipped_velocity=TRUE",
  "physics_gravity ticks=4 per_tick=8 grounded=TRUE",
  "first_physics_trace=blocker=world:textures/smoke/panel;fraction_pct=50;clip_plane=normal=1 0 0;dist=-64",
  "physics_final_origin=80 0 64",
  "physics_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture interaction subsystem" -Entry $InteractionEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "interaction_collision cm=maps/game/mars_city1.cm found=TRUE models=1 polygons=2",
  "interaction_config cfgs=1 binds=4 use_bind=TRUE",
  "interaction_map entities=9 named=9 player_start=1",
  "interaction_links triggers=1 doors=1 target_refs=1 resolved=1",
  "interaction_gui assets=2 refs=1 resolved=1 on_action=5",
  "interaction_player name=player_start_1 origin=128 0 64 yaw=180",
  "interaction_focus candidates=2 found=TRUE entity=trigger_open_door class=trigger_multiple",
  "interaction_use events=1 triggered_targets=1 activated_doors=1 gui_events=1",
  "first_interaction_bind=w=_forward",
  "first_interaction_gui_asset=guis/hud.gui",
  "first_interaction_gui_ref=guis/hud.gui",
  "first_interaction_trigger=trigger_open_door",
  "first_interaction_trigger_target=door_smoke_1",
  "first_interaction_activated_door=door_smoke_1",
  "first_interaction_path=focus>trigger_open_door>use>door_smoke_1",
  "first_use_trace=fraction_pct=75;range=64;radius=32",
  "interaction_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture spawn subsystem" -Entry $SpawnEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "spawn_collision cm=maps/game/mars_city1.cm found=TRUE models=1 polygons=2",
  "spawn_templates entity_defs=7 inherit=1 health=1 model=6 sound=2 gui=1 spawnclass=1 bounds=1",
  "map_spawn entities=9 named=9 origins=8 player_start=1",
  "spawn_kinds light=1 monster=1 door=1 trigger=1 pickup=3",
  "runtime_spawns total=8 transform=8 health=2 model=4 sound=3",
  "runtime_components target=1 gui=1 collision=3 think=1 pickup=3 light=1",
  "spawn_resolution model_refs=4 model_resolved=4 model_missing=0 sound_refs=3 sound_resolved=3 sound_missing=0",
  "spawn_resolution_gui refs=1 resolved=1 missing=0 target_refs=1 target_resolved=1 target_missing=0",
  "spawn_overrides health=0 sound=2",
  "first_spawn_template=monster_smoke_base",
  "first_spawn_inherit=monster_smoke_child>monster_smoke_base",
  "first_spawn_entity=player_start_1",
  "first_spawn_kind=player_start",
  "first_spawn_path=info_player_start>player_start",
  "first_spawn_health=player_start_1=100",
  "first_spawn_model=monster_smoke_1=models/monsters/smoke/smoke.md5mesh",
  "first_spawn_sound=monster_smoke_1=sound/monsters/smoke/alert.wav",
  "first_spawn_gui=weapon_pickup_1=guis/hud.gui",
  "first_spawn_target=trigger_open_door>door_smoke_1",
  "first_spawn_bounds=monster_smoke_1=-16 -16 0 16 16 64",
  "first_spawn_spawnclass=monster_smoke_1=idAI",
  "spawn_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture mover subsystem" -Entry $MoverEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "mover_collision_map cm=maps/game/mars_city1.cm found=TRUE models=1 polygons=2",
  "mover_map entities=9 doors=1 triggers=1 script_calls=1",
  "mover_targets refs=1 resolved=1",
  "mover_sounds refs=1 resolved=1 missing=0",
  "mover_activation trigger=1 script=1 unique_doors=1 idempotent=TRUE",
  "mover_states closed=1 opening=1 open=1",
  "mover_timing ticks=16 msec=256",
  "mover_collision closed_solid=TRUE open_solid=FALSE",
  "first_mover_door=door_smoke_1",
  "first_mover_trigger=trigger_open_door",
  "first_mover_target=trigger_open_door>door_smoke_1",
  "first_mover_sound=door_smoke_1=sound/world/door_open.wav",
  "first_mover_path=closed>opening>open",
  "first_mover_positions=closed=240 0 64;open=240 0 128",
  "mover_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture inventory subsystem" -Entry $InventoryEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "inventory_collision cm=maps/game/mars_city1.cm found=TRUE models=1 polygons=2",
  "map_entities=9 player_start=1 pickup=3",
  "pickup_classes health=1 ammo=1 weapon=1",
  "pickups_with_origin=3",
  "player_start_parsed=TRUE",
  "pickup_path steps=4 step_distance=16.0 touch_radius=32.0 collision_ready=TRUE",
  "touched_pickups=3 health=1 ammo=1 weapon=1",
  "first_touched_pickup=health_pickup_1",
  "inventory_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture combat subsystem" -Entry $CombatEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "combat_collision cm=maps/game/mars_city1.cm found=TRUE models=1 polygons=2",
  "entity_defs=7 health=1 inherit=1",
  "map_entities=9 player_start=1 monster=1",
  "combat_pickups weapon=1 ammo=1",
  "combat_ready player=TRUE weapon=TRUE ammo=TRUE monster=TRUE",
  "combat_origins player=TRUE monster=TRUE",
  "combat_shots_fired=1 hits=1 ammo_after=11",
  "combat_trace hitscan_ready=TRUE collision_models=1 collision_polygons=2",
  "first_monster=monster_smoke_1",
  "first_monster_class=monster_smoke_child",
  "first_monster_health_before=150",
  "first_monster_health_after=125",
  "first_monster_alive_after=TRUE",
  "monster_ai in_range=TRUE attacks=1 hits=1",
  "player_health_before=100",
  "player_health_after=88",
  "combat_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture ai subsystem" -Entry $AiEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "entity_defs=7 monster_defs=3 inherits=1",
  "monster_spawnargs health=1 spawnclass=1 anim=1 sound=1 scriptobject=1 melee_range=1 melee_damage=1",
  "map_ai_entities monsters=1 player_start=TRUE",
  "monster_binding anim=TRUE sound=TRUE scriptobject=TRUE spawnclass=TRUE",
  "ai_state transitions=2 in_range=TRUE attacks=1 player_health_after=88",
  "requested_aas=maps/game/mars_city1.aas",
  "requested_aas_found=TRUE",
  "ai_navigation aas_found=TRUE areas=2 reachabilities=2 path=TRUE steps=1 cost=64",
  "ai_nav_movement monster_area=2 player_area=1 next_x=176.0 next_y=0.0",
  "first_monster_def=monster_smoke_base",
  "first_monster_spawn=monster_smoke_1",
  "first_monster_class=monster_smoke_child",
  "first_monster_anim=models/monsters/smoke/idle.md5anim",
  "first_monster_sound=sound/monsters/smoke/sight.wav",
  "first_monster_scriptobject=monster_smoke_base",
  "first_monster_spawnclass=idAI",
  "first_ai_aas_asset=maps/game/mars_city1.aas",
  "first_ai_aas_agent=monster_smoke_child",
  "first_ai_nav_path=area2>area1",
  "first_ai_state_path=idle>alert>melee",
  "ai_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture objective subsystem" -Entry $ObjectiveEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "map_entities=9 player_start=1 triggers=1 doors=1 monsters=1",
  "objective_metadata objectives=1 next_maps=1",
  "objective_next_map path=maps/game/mars_city2.map found=TRUE player_start=1",
  "objective_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "target_resolution refs=1 resolved=1 missing=0",
  "progression_sim touched_triggers=1 activated_doors=1 completed_objectives=1 clear_ready=TRUE",
  "first_objective=Restore access to the smoke door",
  "first_next_map=game/mars_city2",
  "first_trigger=trigger_open_door",
  "first_trigger_target=door_smoke_1",
  "first_activated_door=door_smoke_1",
  "first_progression_path=spawn>trigger>door>clear>game/mars_city2",
  "objective_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture level subsystem" -Entry $LevelEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "map_assets=2 unique=2",
  "requested_map_found=TRUE",
  "current_map entities=9 player_start=1 objectives=1 next_maps=1 monsters=1 doors=1 triggers=1",
  "next_map_declared=TRUE path=maps/game/mars_city2.map found=TRUE",
  "level_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "next_map entities=3 player_start=1 objectives=1 next_maps=0",
  "transition_state=ready",
  "transition_path=maps/game/mars_city1.map>clear>maps/game/mars_city2.map",
  "carried_state=health=40;ammo=6;objective_complete=TRUE",
  "first_current_objective=Restore access to the smoke door",
  "first_current_nextmap=game/mars_city2",
  "first_next_player_start=player_start_2",
  "level_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture model subsystem" -Entry $ModelEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "model_assets=6 unique=6",
  "model_defs=1 mesh_values=1",
  "entity_defs=7 model_refs=6",
  "entity_model_resolution resolved=6 missing=0",
  "entity_anim_refs=1 resolved=1 missing=0",
  "skin_assets=1 unique=1 skin_decls=1 remaps=1",
  "entity_skin_refs=1 resolved=1 missing=0",
  "md5_mesh_assets=5 parsed=1 version10=1",
  "md5_mesh_metadata joints=1 meshes=1 shaders=1 verts=3 tris=1 weights=3",
  "md5_anim_assets=1 parsed=1 version10=1",
  "md5_anim_metadata frames=2 joints=1 framerate_total=24 components=6 hierarchy=1 bounds=1 baseframe=1",
  "md5_anim_playback_samples=1 first_frame_75ms=1",
  "md5_anim_interpolation samples=1 first_next_frame=0 first_blend_percent=82",
  "md5_pose_compat pairs=1 first_joint_count=1",
  "first_model_asset=models/monsters/smoke/idle.md5anim",
  "first_model_def=model_smoke_imp",
  "first_model_def_mesh=model_smoke_imp=models/monsters/smoke/smoke",
  "first_entity_anim_ref=models/monsters/smoke/idle.md5anim",
  "first_resolved_entity_anim=models/monsters/smoke/idle.md5anim=models/monsters/smoke/idle",
  "first_skin_asset=skins/smoke.skin",
  "first_skin_decl=skin_smoke_burned",
  "first_skin_remap=textures/smoke/panel>textures/smoke/panel_burned",
  "first_entity_skin_ref=skin_smoke_burned",
  "first_resolved_entity_skin=skin_smoke_burned",
  "first_md5_mesh=models/monsters/smoke/smoke.md5mesh",
  "first_md5_shader=textures/smoke/panel",
  "first_md5_anim=models/monsters/smoke/idle.md5anim",
  "model_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture pose subsystem" -Entry $PoseEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map=maps/game/mars_city1.map",
  "requested_map_found=TRUE",
  "md5_assets mesh=5 anim=1 parsed_mesh=1 parsed_anim=1",
  "md5_pose joints=1 verts=3 weights=3 tris=1 frames=2 frame_rate=24 components=6",
  "pose_sample sample_ms=75 current_frame=1 next_frame=0 blend_percent=82 root_shift_cent=36",
  "skinning vertices=3 weighted=3 triangles=1 bounds_ready=TRUE",
  "first_pose_mesh=models/monsters/smoke/smoke.md5mesh",
  "first_pose_anim=models/monsters/smoke/idle.md5anim",
  "first_pose_shader=textures/smoke/panel",
  "first_skinned_vertex_cent=36 0 0",
  "first_skinned_bounds_cent=36 0 0 1636 1600 0",
  "first_triangle=0 1 2",
  "animated_render_entities candidates=1 model_bound=1 anim_bound=1 skin_bound=1",
  "animated_render_draw surfaces=1 vertices=3 triangles=1 texture_resolved=1",
  "animated_render_visibility camera_bound=1 depth_tested=TRUE occlusion_tests=1 world_occluded=0 light_influences=1",
  "first_animated_camera=player_start_1;origin_cent=12800 0 6400;yaw=180",
  "first_animated_light=light_smoke_1;origin_cent=3200 3200 9600;radius_cent=16000 16000 16000;color=0.8 0.7 0.5",
  "first_animated_entity=monster_smoke_1",
  "first_animated_class=monster_smoke_child",
  "first_animated_model=models/monsters/smoke/smoke",
  "first_animated_anim=models/monsters/smoke/idle",
  "first_animated_skin=skin_smoke_burned",
  "first_animated_skin_remap=textures/smoke/panel>textures/smoke/panel_burned",
  "first_animated_material=textures/smoke/panel",
  "first_animated_texture=textures/smoke/panel_d",
  "first_animated_world_bounds_cent=19236 0 6400 20836 1600 6400",
  "first_animated_drawcall=entity=monster_smoke_1;material=textures/smoke/panel;texture=textures/smoke/panel_d;tris=1",
  "first_animated_visibility=entity=monster_smoke_1;camera_depth_cent=7236;occluded=FALSE;lights=1",
  "pose_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture weapon subsystem" -Entry $WeaponEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "weapon_collision cm=maps/game/mars_city1.cm found=TRUE models=1 polygons=2",
  "entity_defs=7 weapon_defs=1 projectile_defs=1",
  "weapon_spawnargs ammo_type=1 ammo_required=1 clip_size=1 num_projectiles=1 spread=1 projectile=1 fire_sound=1 view_model=1",
  "projectile_spawnargs damage=1 splash_damage=1 splash_radius=1 speed=1",
  "map_weapon_entities weapons=1 ammo=1 monsters=1",
  "weapon_resolution pickup=TRUE ammo=TRUE projectile=TRUE fire_sound=TRUE view_model=TRUE",
  "weapon_fire_sim shots=1 ammo_before=12 ammo_after=11 damage=25 projectiles=1 spread=0",
  "weapon_trace fire_ready=TRUE collision_models=1 collision_polygons=2",
  "first_weapon_def=weapon_pistol",
  "first_weapon_ammo_type=ammo_bullets",
  "first_weapon_projectile=projectile_smoke_round",
  "first_projectile_def=projectile_smoke_round",
  "first_weapon_fire_sound=sound/weapons/pistol/fire.wav",
  "first_weapon_view_model=models/weapons/pistol/pickup",
  "first_map_weapon_pickup=weapon_pickup_1",
  "weapon_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture projectile subsystem" -Entry $ProjectileEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "projectile_collision cm=maps/game/mars_city1.cm found=TRUE models=1 polygons=2",
  "entity_defs=7 weapons=1 projectiles=1",
  "projectile_spawnargs refs=1 num_projectiles=1 spread=1 damage=1 splash_damage=1 splash_radius=1 speed=1 model_refs=1",
  "projectile_model_resolution refs=1 resolved=TRUE model_assets=5",
  "map_runtime entities=9 player_start=1 monsters=1 player_origin=TRUE monster_origin=TRUE",
  "projectile_resolution projectile=TRUE model=TRUE",
  "projectile_trace impact_ready=TRUE collision_models=1 collision_polygons=2",
  "projectile_launch_plan count=1 spread=0 deterministic=TRUE",
  "projectile_sim spawned=TRUE impacted=TRUE removed=TRUE ticks=4 travel=64.0",
  "projectile_damage damage=25 monster_before=150 monster_after=125",
  "projectile_splash damage=10 radius=48 targets=1",
  "first_weapon_projectile=projectile_smoke_round",
  "first_projectile_model=models/weapons/pistol/projectile.md5mesh",
  "first_resolved_projectile_model=models/weapons/pistol/projectile",
  "first_projectile_launch_plan=count=1;spread=0;deterministic=TRUE",
  "first_projectile_splash=origin=monster_smoke_1;radius=48;damage=10;targets=1",
  "first_impact_summary=projectile_smoke_round>monster_smoke_1",
  "projectile_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture fx subsystem" -Entry $FxEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "fx_assets files=1 decls=1 particles=1",
  "fx_catalog materials=3 sounds=4",
  "fx_projectiles entity_defs=7 projectile_defs=1 fx_refs=1 resolved=1 missing=0",
  "fx_refs particles=1 resolved=1 missing=0 sounds=1 sound_resolved=1",
  "fx_refs decals=1 resolved=1 missing=0 lights=1",
  "runtime_fx events=1 particle=1 sound=1 decal=1 light=1",
  "first_fx_file=fx/smoke.fx",
  "first_fx_decl=fx/smoke_impact",
  "first_particle_asset=particles/smoke_impact.prt",
  "first_fx_projectile_def=projectile_smoke_round",
  "first_projectile_fx_ref=projectile_smoke_round=fx/smoke_impact",
  "first_fx_particle_ref=particles/smoke_impact.prt",
  "first_fx_sound_ref=sound/weapons/pistol/fire.wav",
  "first_fx_decal_ref=textures/smoke/panel",
  "first_fx_light_ref=1.0 0.45 0.2",
  "first_runtime_fx_event=projectile_impact>fx/smoke_impact",
  "first_fx_timeline=impact@0ms>particle@128ms>sound@0ms>decal@0ms>light@0ms",
  "fx_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture cinematic subsystem" -Entry $CinematicEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "cinematic_assets videos=1 roq=1 gui_assets=2",
  "cinematic_headers roq_parsed=1 fallback=0",
  "cinematic_gui refs=1 resolved=1 missing=0",
  "cinematic_map entities=9 refs=1 resolved=1 missing=0",
  "runtime_cinematics total=2 gui=1 world=1 fallback_frames=0",
  "first_video_asset=video/smoke_intro.roq",
  "first_cinematic_gui_asset=guis/hud.gui",
  "first_gui_video_ref=video/smoke_intro.roq",
  "first_map_video_ref=video/smoke_intro.roq",
  "first_runtime_cinematic=gui>video/smoke_intro.roq",
  "first_cinematic_playback=open>decode@0ms>frame@33ms>loop",
  "cinematic_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture gui subsystem" -Entry $GuiEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "gui_assets=2 unique=2",
  "gui_structure window_defs=7 named=2 rects=7 visible=7 matcolor=7 on_action=5",
  "entity_defs=7 gui_refs=1",
  "entity_gui_resolution resolved=1 missing=0",
  "map_entities=9 gui_refs=1",
  "map_gui_resolution resolved=1 missing=0",
  "runtime_gui_surfaces=1 hud_bindings=1",
  "first_gui_asset=guis/hud.gui",
  "first_gui_window=Desktop",
  "first_entity_gui_ref=guis/hud.gui",
  "first_map_gui_ref=guis/hud.gui",
  "first_runtime_gui_binding=world=guis/hud.gui",
  "gui_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture sound subsystem" -Entry $SoundEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "sound_assets=4 unique=4",
  "sound_shader_files=1 decls=2",
  "sound_shader_samples refs=2 resolved=2 missing=0",
  "entity_defs=7 sound_refs=2",
  "entity_sound_resolution resolved=2 missing=0",
  "map_entities=9 sound_refs=2",
  "map_sound_resolution resolved=2 missing=0",
  "runtime_sound_events=2 shader=0 direct_sample=2",
  "first_sound_shader=sound/monsters/smoke/sight",
  "first_sound_shader_sample=sound/monsters/smoke/sight.wav",
  "first_entity_sound_ref=sound/monsters/smoke/sight.wav",
  "first_map_sound_ref=sound/monsters/smoke/alert.wav",
  "first_runtime_sound_event=monster_smoke_1=sound/monsters/smoke/alert.wav",
  "sound_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture audio subsystem" -Entry $AudioEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "audio_assets total=4 wav=4 ogg=0",
  "audio_headers parsed=4 wav=4 ogg=0 invalid=0",
  "audio_mix_plan pcm=4 non_pcm=0 mono=2 stereo=2 total_duration_ms=400",
  "first_sound_asset=sound/monsters/smoke/alert.wav",
  "first_wav_sample=sound/monsters/smoke/alert.wav",
  "first_sample_summary=sound/monsters/smoke/alert.wav;format=wav;channels=1;rate=22050;bits=16;duration_ms=100",
  "audio_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture aas subsystem" -Entry $AasEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map=maps/game/mars_city1.map",
  "requested_map_found=TRUE",
  "requested_aas=maps/game/mars_city1.aas",
  "requested_aas_found=TRUE",
  "aas_assets=1",
  "map_ai_entities player_start=TRUE monsters=1",
  "aas_graph areas=2 reachabilities=2",
  "aas_settings agents=1 version=1",
  "aas_path start_area=1 goal_area=2 found=TRUE steps=1 cost=64",
  "aas_runtime monster_area=2 player_area=1 path=TRUE cost=64",
  "aas_runtime_move next_x=176.0 next_y=0.0 attack=TRUE player_health_after=88",
  "first_aas_asset=maps/game/mars_city1.aas",
  "first_agent_class=monster_smoke_child",
  "first_monster_name=monster_smoke_1",
  "first_monster_class=monster_smoke_child",
  "first_reachability=area1>area2;cost=64",
  "first_path=area1>area2",
  "first_runtime_path=area2>area1",
  "aas_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture script subsystem" -Entry $ScriptEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "script_files=1",
  "script_functions=2 unique=2",
  "script_objects=1 unique=1",
  "script_events executable_functions=1 print=1 trigger=1 wait=1 objective=1",
  "entity_defs=7 scriptobjects=1",
  "entity_scriptobject_resolution resolved=1 missing=0",
  "map_entities=9 call_refs=1",
  "map_call_resolution resolved=1 missing=0",
  "map_call_event_resolution executable=1",
  "first_script_function=init",
  "first_script_object=monster_smoke_base",
  "first_executable_function=smoke_entry",
  "first_script_event_path=smoke_entry:print>trigger>wait>objective",
  "first_entity_scriptobject=monster_smoke_base",
  "first_map_call_ref=smoke_entry",
  "script_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture scheduler subsystem" -Entry $SchedulerEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "script_files=1 functions=1 executable=1",
  "map_script_calls entities=9 call_refs=1 resolved=1",
  "scheduler_entities named=9 doors=1 monsters=1",
  "scheduler_events immediate=2 queued=1 dispatched=1",
  "scheduler_event_kinds print=1 trigger=1 wait=1 objective=1",
  "scheduler_time ticks=32 msec=512",
  "scheduler_effects activated_doors=1 objective_complete=TRUE",
  "scheduler_next_map declared=TRUE path=maps/game/mars_city2.map found=TRUE player_start=1",
  "scheduler_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "scheduler_frame_gate ticks=6 monster_health_after=0 monster_alive_after=FALSE clear_ready=TRUE",
  "first_script_function=smoke_entry",
  "first_executable_function=smoke_entry",
  "first_map_call_ref=smoke_entry",
  "first_target_entity=door_smoke_1",
  "first_activated_door=door_smoke_1",
  "first_queued_event=objective@500ms",
  "first_dispatched_event=objective@512ms",
  "first_event_timeline=print>trigger>wait(500ms)>objective",
  "scheduler_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture trace subsystem" -Entry $TraceEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "map_entities=9 player_start=1",
  "trace_materials decls=3 nonsolid=1",
  "entity_defs=7 inherits=1 bounds=1",
  "brush_bounds=2 complete=2",
  "compiled_collision_map cm_found=TRUE collision_models=1 vertex_decls=1 edge_decls=1 polygon_decls=1 brush_decls=1",
  "compiled_collision_geometry vertices=4 edges=4 polygons=2 brushes=1",
  "compiled_collision_polygons classified=2 blocking=1 nonblocking=1 planes=2",
  "compiled_collision_version=1",
  "compiled_collision_model_name=world",
  "trace_brush_materials refs=2 declared=2 solid=1 nonsolid=1",
  "runtime_trace_entities solid=2 trigger=1 hostile=1 bounds=1",
  "player_start_parsed=TRUE",
  "movement_traces=1 clear=1 blocked=0 hull_tests=1",
  "wall_traces=1 brush_hits=1",
  "hitscan_traces=1 entity_hits=1 bounds_tests=1",
  "trigger_touches=1 resolved_targets=1",
  "first_blocked_trace_reason=brush",
  "first_hitscan_entity=monster_smoke_1",
  "first_touched_trigger=trigger_open_door",
  "first_touched_trigger_target=door_smoke_1",
  "first_trace_entitydef_bounds=monster_smoke_base",
  "first_trace_runtime_bounds=monster_smoke_1=-16 -16 0 16 16 64",
  "first_trace_brush_material=textures/smoke/panel",
  "first_compiled_collision_model=models=1;vertices=4;edges=4;polygons=2;brushes=1",
  "first_compiled_collision_polygon=material=textures/smoke/panel;contents=solid",
  "compiled_collision_polygon_material_declared=TRUE",
  "compiled_collision_polygon_blocking=TRUE",
  "first_compiled_collision_plane=normal=1 0 0;dist=-64",
  "compiled_plane_tests=1",
  "first_compiled_plane_trace=point=64 0 0;distance=0;hit=TRUE",
  "first_compiled_plane_segment=start=32 0 0;end=96 0 0;start_dist=-32;end_dist=32;hit=TRUE;fraction_pct=50",
  "compiled_segment_trace planes=2 blocking_hits=1 nonblocking_skipped=1 nearest_fraction_pct=50",
  "first_compiled_segment_hit=material=textures/smoke/panel;contents=solid;fraction_pct=50",
  "first_trace_mode=movement_hull",
  "trace_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture render subsystem" -Entry $RenderEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "material_decls=3 texture_bindings=2 image_assets=5",
  "material_image_directives=4",
  "first_material_image_directive=qer_editorimage=textures/smoke/trim_editor",
  "material_stages=1 blend_stages=1 animated=1 transforms=2 time_expr=1",
  "model_assets=5 unique=5",
  "md5_render_assets mesh=5 anim=1 parsed_mesh=1 parsed_anim=1",
  "md5_render_geometry verts=3 tris=1 weights=3 anim_frames=2 anim_frame_rate=24",
  "entity_defs=7 model_refs=6 skin_refs=1 inherits=1",
  "entity_def_anims refs=1",
  "render_skin_assets=1 unique=1 skin_decls=1 remaps=1",
  "map_entities=9 player_start=1",
  "map_lights=1 radius=1 color=1",
  "player_start_parsed=TRUE",
  "render_surfaces=4 brush=2 patch=2 visible=3 textured=3 fallback=0 lit=3",
  "compiled_render_map proc_found=TRUE models=1 surfaces=1 portals=2",
  "compiled_render_identity version=4 model=world",
  "compiled_render_portals areas=3 portals=2",
  "compiled_render_geometry vert_decls=1 index_decls=1 vertices=3 indexes=3",
  "compiled_render_materials refs=1 unique=1 texture_resolved=1 texture_missing=0",
  "first_compiled_render_surface=material=textures/smoke/panel;texture=textures/smoke/panel_d;verts=3;indexes=3",
  "first_compiled_render_drawcall=material=textures/smoke/panel;texture=textures/smoke/panel_d;tris=1;portal_areas=3",
  "first_compiled_render_portals=areas=3;portals=2",
  "first_compiled_render_portal=points=4;positive_area=0;negative_area=1",
  "first_compiled_visibility_scope=camera_area=0;visible_areas=2;via_portals=2",
  "compiled_visibility_flood=camera_area=0;visible_areas=3;portal_links=2",
  "render_light_influences=3",
  "framebuffer=24x12 columns=25 pixels=90",
  "depth_buffer writes=18 occluded=7",
  "render_entities candidates=4 visible=1 occluded=3",
  "render_entity_models refs=4 resolved=4 missing=0 visible=1 occluded=2",
  "render_entity_anims refs=1 resolved=1 missing=0",
  "render_entity_skins refs=1 resolved=1 missing=0 remaps=1",
  "first_visible_entity=weapon_pickup_1",
  "first_occluded_entity=trigger_open_door",
  "first_render_entity_model=monster_smoke_1=models/monsters/smoke/smoke",
  "first_render_entity_anim=monster_smoke_1=models/monsters/smoke/idle",
  "first_render_skin_binding=monster_smoke_1=skin_smoke_burned",
  "first_render_skin_remap=monster_smoke_1=textures/smoke/panel>textures/smoke/panel_burned",
  "nearest_surface_material=textures/smoke/panel",
  "nearest_surface_texture=textures/smoke/panel_d",
  "nearest_surface_depth=32.0",
  "nearest_surface_lights=1",
  "nearest_surface_light_color=0.8 0.7 0.5",
  "first_animated_material=textures/smoke/panel",
  "first_animated_texture=textures/smoke/panel_d",
  "first_animated_transform=scroll+rotate",
  "material_anim_sample time=2.0 scroll_u=0.5 scroll_v=0.0 rotation=30.0",
  "animated_actor_handoff candidates=1 drawcalls=1 vertices=3 triangles=1 texture_resolved=1 light_influences=1",
  "first_md5_render_mesh=models/monsters/smoke/smoke.md5mesh",
  "first_md5_render_anim=models/monsters/smoke/idle.md5anim",
  "first_animated_actor=monster_smoke_1",
  "first_animated_actor_drawcall=entity=monster_smoke_1;mesh=models/monsters/smoke/smoke;anim=models/monsters/smoke/idle;shader=textures/smoke/panel;texture=textures/smoke/panel_d;tris=1",
  "first_animated_actor_visibility=entity=monster_smoke_1;camera_bound=TRUE;texture_resolved=1;lights=1",
  "frame_mid_row=.....******E*****.......",
  "render_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture view subsystem" -Entry $ViewEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "requested_proc_found=TRUE",
  "view_config fov_x=90.0 width=1280 height=720",
  "render_view player_start=TRUE entities=9 player_starts=1 origin=128 0 64 yaw=180.0",
  "view_axes forward=",
  "bucket=west",
  "view_projection fov_y=",
  "planes=4 bucket=wide-16x9",
  "view_viewport viewport=0 0 1280 720 scissor=0 0 1280 720",
  "portal_view proc_models=1 areas=3 portals=2 camera_area=0 visible_areas=3",
  "weapon_view model_view_refs=1 resolved=1 depth_hack=1",
  "first_view_player_start=player_start_1",
  "first_view_axis=yaw=180.0;bucket=west",
  "first_view_projection=fov_x=90.0;",
  "first_portal_scope=camera_area=0;visible_areas=3;portal_links=2",
  "first_weapon_view_plan=model_view=models/weapons/pistol/pickup.md5mesh;fov=70.0;depth_hack=weapon",
  "view_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture submit subsystem" -Entry $SubmitEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map=maps/game/mars_city1.map",
  "requested_map_found=TRUE",
  "submit_assets mesh=5 anim=1 parsed_mesh=1 parsed_anim=1",
  "submit_geometry verts=3 tris=1 weights=3 anim_frames=2 anim_frame_rate=24",
  "submit_entity_defs=7",
  "submit_entity candidates=1 model_bound=1 anim_bound=1 skin_bound=1 spawnclass_bound=1",
  "submit_view_weapon candidates=1 model_view_bound=1",
  "submit_frame sample_ms=75 frame=1 next=0 blend_percent=82 health=150",
  "first_submit_mesh=models/monsters/smoke/smoke.md5mesh",
  "first_submit_anim=models/monsters/smoke/idle.md5anim",
  "first_submit_shader=textures/smoke/panel",
  "first_submit_entity=monster_smoke_1",
  "first_submit_class=monster_smoke_child",
  "first_submit_model=models/monsters/smoke/smoke",
  "first_submit_anim_ref=models/monsters/smoke/idle",
  "first_submit_skin=skin_smoke_burned",
  "first_submit_spawnclass=idAI",
  "first_submit_view_weapon=weapon_pickup_1",
  "first_submit_view_weapon_class=weapon_pistol",
  "first_submit_view_model=models/weapons/pistol/pickup",
  "submit_drawcalls=1",
  "first_submit_drawcall=entity=monster_smoke_1;mesh=models/monsters/smoke/smoke;anim=models/monsters/smoke/idle;shader=textures/smoke/panel;frame=1;next=0;blend=82;verts=3;tris=1",
  "first_submit_state=entity=monster_smoke_1;spawnclass=idAI;skin=skin_smoke_burned;health=150;alive=TRUE",
  "submit_view_drawcalls=1",
  "first_submit_view_drawcall=entity=weapon_pickup_1;class=weapon_pistol;mesh=models/weapons/pistol/pickup;view_relative=TRUE;depth_hack=weapon",
  "submit_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture compiled map subsystem" -Entry $CompiledMapEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map=maps/game/mars_city1.map",
  "requested_map_found=TRUE",
  "compiled_assets map=2 proc=2 cm=2 materials=3 images=5",
  "selected_compiled_map proc_found=TRUE cm_found=TRUE",
  "selected_proc=maps/game/mars_city1.proc models=1 surfaces=1 portals=2",
  "selected_proc_portals areas=3 portals=2",
  "selected_proc_geometry vert_decls=1 index_decls=1 vertices=3 indexes=3",
  "selected_proc_materials refs=1 unique=1 declared=1 missing=0",
  "selected_proc_textures refs=1 resolved=1 missing=0",
  "compiled_material_collision nonsolid=1",
  "selected_cm=maps/game/mars_city1.cm collision_models=1 vertex_decls=1 edge_decls=1 polygon_decls=1 brush_decls=1",
  "selected_cm_geometry vertices=4 edges=4 polygons=2 brushes=1",
  "selected_cm_polygons classified=2 blocking=1 nonblocking=1 planes=2",
  "first_proc_version=4",
  "first_proc_model=world",
  "first_cm_version=1",
  "first_cm_model=world",
  "compiled_model_pair=proc=world;cm=world;match=TRUE",
  "first_cm_collision=model=world;vertices=4;edges=4;polygons=2;brushes=1",
  "first_cm_polygon=material=textures/smoke/panel;contents=solid",
  "cm_polygon_material_declared=TRUE",
  "cm_polygon_blocking=TRUE",
  "first_cm_plane=normal=1 0 0;dist=-64",
  "cm_segment_trace planes=2 blocking_hits=1 nonblocking_skipped=1 nearest_fraction_pct=50",
  "first_cm_segment_hit=material=textures/smoke/panel;contents=solid;fraction_pct=50",
  "first_compiled_material_decl=textures/smoke/panel",
  "first_proc_material_ref=textures/smoke/panel",
  "first_proc_texture_binding=textures/smoke/panel=textures/smoke/panel_d",
  "first_proc_surface=material=textures/smoke/panel;verts=3;indexes=3",
  "first_proc_portals=areas=3;portals=2",
  "first_proc_portal=points=4;positive_area=0;negative_area=1",
  "first_proc_visibility_scope=camera_area=0;visible_areas=2;via_portals=2",
  "proc_visibility_flood=camera_area=0;visible_areas=3;portal_links=2",
  "first_compiled_surface=material=textures/smoke/panel;texture=textures/smoke/panel_d;verts=3;indexes=3",
  "first_compiled_drawcall=material=textures/smoke/panel;texture=textures/smoke/panel_d;tris=1;portal_areas=3",
  "compiled_map_probe_ready=TRUE"
)

Invoke-Doom3Seed7 -Label "generated fixture frame subsystem" -Entry $FrameEntry -ArgsToPass @(
  "--doom3_data_path",
  $GeneratedFixture
) -MustContain @(
  "pk4_archives=1",
  "requested_map_found=TRUE",
  "entity_defs=7 health=1 inherit=1 spawnclass=1",
  "frame_weapon_defs weapons=1 projectiles=1 ammo_required=1 clip_size=1 projectile_refs=1 fire_sound=1 projectile_damage=1",
  "map_entities=9 runtime=8 player_start=1",
  "runtime_kinds monster=1 pickup=3 door=1 trigger=1",
  "player_start_parsed=TRUE",
  "frame_movement requested=4 accepted=3 blocked=TRUE",
  "frame_movement_blockers brush=1 entity=0",
  "frame_player_final_x=80.0",
  "frame_script_bindings files=1 event_functions=1 map_calls=1 resolved_events=1",
  "frame_sound_assets=4 unique=4",
  "frame_model_assets=6 unique=6 model_defs=1 mesh_values=1",
  "frame_model_bindings refs=4 resolved=4 missing=0 anim_refs=1 anim_resolved=1 anim_missing=0",
  "frame_skin_assets=1 unique=1 skin_decls=1 remaps=1",
  "frame_skin_bindings refs=1 resolved=1 missing=0",
  "frame_spawnclass_bindings refs=1 resolved=1 unsupported=0",
  "frame_anim_playback assets=1 parsed=1 samples=1 interpolation=1",
  "first_frame_anim_sample frame_75ms=1 next_frame=0 blend_percent=82",
  "frame_gui_assets=2 unique=2 window_defs=7 rects=7 visible=7 matcolor=7 on_action=5",
  "frame_gui_refs entity=1 entity_resolved=1 entity_missing=0 map=1 map_resolved=1 map_missing=0",
  "frame_gui_runtime surfaces=1 hud_bindings=1",
  "frame_map_catalog assets=2 unique=2",
  "current_map_next_maps=1",
  "frame_brush_trace boxes=2 complete=2",
  "frame_pickups touched=3 health=1 ammo=1 weapon=1",
  "frame_inventory weapon=TRUE ammo_before=0 ammo_after_pickups=12 ammo_after_combat=11",
  "frame_weapon_runtime class=weapon_pistol projectile=projectile_smoke_round ammo_required=1 clip_size=12 damage=25",
  "frame_trigger touches=1 activated_doors=1",
  "frame_script calls=1 prints=1 triggers=1 waits=1 objectives=1",
  "frame_sound_events candidates=3 emitted=3 resolved=3 missing=0",
  "frame_sound_kinds door=1 weapon=1 monster=1",
  "frame_hitscan traces=1 clear=1 blocked=0 hits=1",
  "frame_combat shots=1 monster_hits=1 monster_attacks=1",
  "player_health before=100 after_pickups=100 after_combat=88",
  "first_frame_pickup=weapon_pickup_1",
  "first_frame_trigger=trigger_open_door",
  "first_activated_door=door_smoke_1",
  "first_frame_script_call=smoke_entry",
  "first_frame_script_event_path=smoke_entry:print>trigger>wait>objective",
  "first_frame_sound_event=door_open=sound/world/door_open.wav",
  "first_frame_model_binding=monster_smoke_1=models/monsters/smoke/smoke",
  "first_frame_anim_binding=monster_smoke_1=models/monsters/smoke/idle",
  "first_frame_skin_asset=skins/smoke.skin",
  "first_frame_skin_binding=monster_smoke_1=skin_smoke_burned",
  "first_frame_spawnclass_binding=monster_smoke_1=idAI",
  "first_frame_gui_asset=guis/hud.gui",
  "first_frame_gui_binding=world=guis/hud.gui",
  "first_frame_hitscan_target=monster_smoke_1",
  "first_frame_movement_blocker=brush",
  "first_monster=monster_smoke_1",
  "first_monster_class=monster_smoke_child",
  "first_monster_health_before=150",
  "first_monster_health_after=125",
  "first_monster_alive_after=TRUE",
  "loop_ticks=6",
  "loop_state pickups_consumed=3 doors_open=1",
  "loop_combat shots=6 monster_hits=6 monster_attacks=5",
  "loop_ammo_after=6",
  "loop_player_health_after=40",
  "loop_monster_health_after=0",
  "loop_monster_alive_after=FALSE",
  "loop_clear_condition=TRUE",
  "hud_health_value=40",
  "hud_health_bar=####......",
  "hud_ammo_value=6",
  "hud_ammo_bar=#####.....",
  "hud_enemies_remaining=0",
  "hud_objective_complete=TRUE",
  "screen_state=cleared",
  "frame_transition next_declared=TRUE path=maps/game/mars_city2.map found=TRUE next_player_start=1",
  "frame_compiled_next proc=TRUE cm=TRUE proc_path=maps/game/mars_city2.proc cm_path=maps/game/mars_city2.cm",
  "frame_transition_state=ready",
  "frame_transition_path=maps/game/mars_city1.map>cleared>maps/game/mars_city2.map",
  "save_snapshot=map=maps/game/mars_city1.map;health=40;ammo=6;monster_health=0;monster_alive=FALSE;doors_open=1;clear=TRUE;screen=cleared;next_map=maps/game/mars_city2.map;transition=ready",
  "restore_verified=TRUE",
  "restore_state health=40 ammo=6 doors_open=1 clear=TRUE screen=cleared",
  "first_frame_next_map=game/mars_city2",
  "first_frame_next_player_start=player_start_2",
  "frame_probe_ready=TRUE"
)

if ($FixturePath) {
  Invoke-Doom3Seed7 -Label "fixture assets" -ArgsToPass @(
    "--doom3_data_path",
    $FixturePath
  ) -MustContain @(
    "pk4_archives=",
    "Stage 1 asset pipeline complete."
  )
}

if ($RealDoom3Path) {
  Invoke-Doom3Seed7 -Label "real Doom 3 assets" -ArgsToPass @(
    "--doom3_data_path",
    $RealDoom3Path
  ) -MustContain @(
    "pk4_archives=",
    "Stage 1 asset pipeline complete."
  )
}

Write-Host "doom3_seed7 smoke tests passed"
