Treacherous

A family of tree automata based cellular procedural generation algorithms, created by TreacherousDev.

Introduction to Tree Automata:
A tree automaton is a computational model used in computer science and mathematics to process and analyze tree-like structures. 

Formally, a tree automaton comprises a set of states, a transition function, and acceptance criteria. These automata traverse a tree structure in a top-down manner, moving from node to node based on the transition function and changing states accordingly. At each step, the automaton reads the current node's label and transitions between states according to the rules defined in the transition function.

In the context of procedural generation, tree automoata can be utilized to create acyclic dungeons and mazes when implemented onto a 2 dimensional grid with context-sensitive production rules based on von neumann neighborhood.

Given the von neumann directions Up, Right, Down and Left, we can assign each one of these an int value that acts as a bit flag, which allows us to map a unique room ID for all possible combinations of directions. 

In this algorithm, the values are as follows:
Up: 1
Right: 2
Down: 4
Left: 8


The algorithm starts by initializing a root room from the origin. We configure its cell data like this:
cell_data[root_room][0, null, null, [1, 2, 4, 8]]
The indexes for the cell data are as follows:
Index 0: Cell Depth — How many rooms to traverse before reaching the root room
Index 1: Cell Parent Direction — The direction of the parent relative to the current cell, expressed as a bit flag int. 
Index 2: Cell Parent Position — The position of the parent cell, expressed as a Vector2i.
Index 3: Open Direction — An array of all the unoccupied von neumann neighbors of the cell, each direction expressed as a bit flag. 

Because the root room has no parent, we set index 1 and 2 to null, but the proceeding cells will have these values filled accordingly. 

Afterwards, we move onto the spawning process. Spawning happens in 2 phases: The first phase spawns the room with the assigned ID, and the second phase spawns temporary dots to the directions it branches towards.

This second phase plays a crucial role in avoiding collision conflict as diagonally adjacent neighbors will now detect the coordinate with a temporary dot as occupied, and wont try to branch towards it. This works because the algorithm runs on a single thread, and that the second phase of the last cell must first be completed before proceeding with the first phase of the next cell.

After the spawning phase is completed, the root room is appended to the active_cells array, and the function run_algorithm() is called. This function is responsible for iterating through all elements in active cells and is the primary loop that powers this procedural generator.

