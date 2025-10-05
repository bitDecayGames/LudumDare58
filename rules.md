# Rules of Play

## Tile Types

- Snow
  - Can walk onto
  - Can melt into ice
- Ice
  - Can walk onto
  - Automatically slides in original direction to next tile
- Stone
  - Can Walk onto
- Cracked Ice
  - Can walk onto
  - Automatically slides in original direction to next tile
  - Destroyed after player or block leaves becoming water tile
- Empty Tile / Water tile  
  - Player dies if moved onto
  - Blocks disappear if moved onto


## Objects

- Bear
  - Controlled by the player
  - Moves one input at a time
  - Melts snow into ice when leaving snow tiles
- Seal
  - "Collectable" object
  - Eaten when Bear moves onto same tile
- Crates
  - Can be pushed by player
  - Cannot be pushed onto seals.
- Ice Wall
  - Immovable tile, Cannot be pushed 
- Life Saver
  - End of level when bear steps onto

## Bear controls

- Directional input
  - Arrow Keys / WASD to move and interact
- Moving into blocks
  - Crates
    - Cannot push crates while standing on ice
    - 