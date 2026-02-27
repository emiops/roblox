# EmiOps Lizard World - Roblox Game

A Roblox world with nature (trees, rocks, caves, lakes, flowers, butterflies) and catchable lizards that escape and vary in size and appearance.

## Requirements

- **Roblox Studio** (free) — [roblox.com/create](https://create.roblox.com)
- **Roblox account**

---

## Part 1: Build the World (Terrain & Nature)

### 1. Create New Place

1. Open **Roblox Studio**
2. **New** → **Baseplate** or **Flat Terrain**
3. Save as "EmiOps Lizard World"

### 2. Terrain (Hills, Lakes, Caves)

1. Open **Home** tab → **Terrain**
2. **Generate** → Create hills, valleys, water
3. **Paint** → Add grass, sand, rock textures
4. **Add Water** → Click to place lakes
5. **Add Caves** → Use the **Grow** tool to carve caves, or add hollow parts

### 3. Trees

- **Model** tab → **Toolbox** → Search "tree"
- Or: **View** → **Explorer** → Right‑click **Workspace** → **Insert from File** (if you have tree models)
- Place trees around the map

### 4. Rocks

- Toolbox → Search "rock" or "boulder"
- Place rocks near caves, lakes, and paths

### 5. Flowers

- Toolbox → Search "flower"
- Place flowers in open areas

### 6. Butterflies

- Toolbox → Search "butterfly"
- Or create: small Parts with **Decal**/color, add a **Script** that moves them in a pattern
- Place near flowers

---

## Part 2: Add the Lizard Scripts

### 1. Create a Lizards Folder

1. In **Explorer**, right‑click **Workspace**
2. **Insert Object** → **Folder**
3. Name it **Lizards**

### 2. Add LizardManager Script

1. Right‑click **ServerScriptService**
2. **Insert Object** → **Script**
3. Name it **LizardManager**
4. Delete the default code
5. Copy the contents of `ServerScriptService/LizardManager_Fixed.lua` into it

### 3. Add LizardInventory Module

1. Right‑click **ReplicatedStorage**
2. **Insert Object** → **ModuleScript**
3. Name it **LizardInventory**
4. Delete the default code
5. Copy the contents of `ReplicatedStorage/LizardInventory.lua` into it

### 4. Add CatchController Script

1. Right‑click **ServerScriptService**
2. **Insert Object** → **Script**
3. Name it **CatchController**
4. Delete the default code
5. Copy the contents of `ServerScriptService/CatchController.lua` into it

### 5. Add Inventory GUI (Optional)

1. Right‑click **StarterGui**
2. **Insert Object** → **LocalScript**
3. Name it **InventoryGUI**
4. Delete the default code
5. Copy the contents of `StarterGui/InventoryGUI.lua` into it

### 6. Test

1. Press **Play** (F5)
2. Lizards should spawn and run away when you get close
3. Walk into a lizard to catch it
4. Press **I** to open your lizard inventory
5. Check **leaderstats** → **LizardsCaught** for total count

---

## Part 3: Optional Improvements

### Custom Lizard Model

Replace the simple Part in `LizardManager_Fixed.lua` with your own lizard model:

1. Create or download a lizard model in Roblox Studio
2. Put it in **ReplicatedStorage** as "LizardTemplate"
3. Update the script to clone that instead of creating a Part

### Butterfly Script (Simple)

```lua
-- Place in a Butterfly model in Workspace
local part = script.Parent.PrimaryPart or script.Parent:FindFirstChildWhichIsA("BasePart")
local startPos = part.Position
while true do
    for i = 1, 50 do
        part.CFrame = startPos * CFrame.new(math.sin(i/10)*2, math.sin(i/5)*1, 0)
        task.wait(0.05)
    end
end
```

### Spawn Settings

In `LizardManager_Fixed.lua` you can change:

- `ESCAPE_DISTANCE` — how close the player must be for lizards to run (default: 14)
- `ESCAPE_SPEED` — how fast they run (default: 16)
- `SPAWN_INTERVAL` — seconds between spawns (default: 6)
- `MAX_LIZARDS` — max lizards at once (default: 20)
- `SPAWN_RADIUS` — area where lizards spawn (default: 60)

---

## File Structure

```
EmiOps-Roblox/
├── ServerScriptService/
│   ├── LizardManager_Fixed.lua (spawn + behavior)
│   └── CatchController.lua     (catching + inventory)
├── ReplicatedStorage/
│   └── LizardInventory.lua     (ModuleScript - inventory logic)
├── StarterGui/
│   └── InventoryGUI.lua        (LocalScript - press I to view)
└── README.md
```

---

## Quick Start Checklist

- [ ] Create new Baseplate in Roblox Studio
- [ ] Add terrain (hills, water, caves)
- [ ] Add trees, rocks, flowers from Toolbox
- [ ] Add butterflies (Toolbox or custom)
- [ ] Create **Lizards** folder in Workspace
- [ ] Add **LizardInventory** ModuleScript to ReplicatedStorage
- [ ] Add **LizardManager_Fixed** script to ServerScriptService
- [ ] Add **CatchController** script to ServerScriptService
- [ ] Add **InventoryGUI** LocalScript to StarterGui (optional)
- [ ] Press Play and test — press **I** to view inventory

---

© EmiOps — Have fun catching lizards!
