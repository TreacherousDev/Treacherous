### Version 1.0 Release Summary - Cellular Procedural Generation Map Algorithm

This powerful algorithm creates intricate and diverse maps using cellular automata. Here's a summary of what is included in this release:

### Key Features:
1. Flexible Map Generation:
    Generate complex maps with branching paths.
    Easily customizable parameters to control map size, room types, and expansion behavior.

2. Dynamic Room Spawning:
    The algorithm intelligently spawns rooms, ensuring connectivity and logical layout.
    i.e: a room with an open left branch always connects to a room with an open right branch

3. Map Expansion Customization:
    Choose from multiple expansion modes (Max, Min, Random, Custom) to handle map expansion when generation stops prematurely

4. Reproducibility and Seed Support:
    Utilizes RandomNumberGenerator to ensure reproducibility via seeding.
    Create consistent maps for replicable gameplay / debugging

5. Customizability:
    Clear and well-commented codebase for easy understanding and modification.
    Customize room spawning rules, map expansion behavior, and room selection strategies.
   
6. Pathfinding:
    Click on any room in the map to draw a path to the origin

### Use Cases:
1. Roguelike Levels
    Seamlessly integrate this algorithm into your roguelike game project to serve as its map generator, ensuring a unique yet consistent experience with each run.

https://github.com/TreacherousDev/Cellular-Procedural-Generation-with-Tilemaps/assets/55629534/8c0011b7-291a-4d2b-849e-e305e007b105



2. Realistic Island Outlines
    Given a large enough map size and custom modification of room spawning conditions, this generator is able to create organic looking shapes that resemble large islands.

https://github.com/TreacherousDev/Cellular-Procedural-Generation-with-Tilemaps/assets/55629534/c726e56b-3b55-47b8-a6bf-307f902d1dc8


### How to Use:
1. Install this as a ZIP file
2. Open Godot Enigne and extract from there
NOTE: For versions 4.0 and above only!

Documentation is a work in progress, but the codebase is well maintained with comments for the meantime.



