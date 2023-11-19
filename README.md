# Treacherous

A family of cellular procedural generation algorithms powered by context sensitive tree automata, created by TreacherousDev.


# Introduction to Tree Automata
A tree automaton is a computational model used in computer science and mathematics to process and analyze tree-like structures. 

Formally, a tree automaton comprises a set of states, a transition function, and acceptance criteria. These automata traverse a tree structure in a top-down manner, moving from node to node based on the transition function and changing states accordingly. At each step, the automaton reads the current node's label and transitions between states according to the rules defined in the transition function.

In the context of procedural generation, tree automoata can be utilized to create acyclic dungeons and mazes when implemented onto a 2 dimensional grid with context-sensitive production rules based on von neumann neighborhood.

Given the von neumann directions Up, Right, Down and Left, we can assign each one of these an int value that acts as a bit flag. In this algorithm, the values are as follows:
| Direction     | Int Value     |
| ------------- | ------------- |
| UP            | 1             |
| RIGHT         | 2             |
| DOWN          | 4             |
| LEFT          | 8             |

Given these values, we can create 15 unique combinations of rooms which comprises of 1 to 4 of these directions, all with their own unique number from 1 to 15.
For deomstration purposes, numbers 10 to 15 shall be expressed in hexadecimal notation (A - F) to make diagrams look more uniform.


# Automata Sequence
The algorithm starts by initializing a root room from the origin (0, 0). Then, the branch direction of the cell are marked.

In this example, the root room will be 3, which has an up (1) and right (2) direction.
```
-------   -------
-------   ---@---
---3---   ---3@--
-------   -------
-------   -------
```
We then create 2 lists: active_cells and next_active_cells, both with an empty starting value.
The root cell is then put into next_active_cells list, and the main algorithm loop starts.

The algorithm sets the value of next_active_cells into active_cells, and the contents of next_active_cells are cleared. The reason this is done is important and will be explained later on.
The algorithm then iterates through all cells in active_cells.

For each cell in active cells, it does the following:
1. Get the branch directions of the current cell, excluding its parent
2. For each branch direction, store a reference to the current cell. These cells will be assigned as children of the current cell.
3. Iterate through all children and do as follows:
   1.  Write it down onto the next_active_cells list
   2.  Get all non-empty neighbors of the cell
   3.  Get the powerset of the combination of all non-empty neighbors (include empty)
   4.  For each set in the powerset, append the parent direction and get the sum of all elements. Store the values in a new list called room_selection
   5.  Select 1 random element from the room_selection list
   6.  Mark all the opening directions of the selected element, excluding the direction of its parent
4. If there exists at least 1 element in next_active_cells:
   1.  Move the contents of next_active_cells to active_cells
   2.  Run the algorithm again.

Let's run through this algorithm step by step and simulate the map in real time.
In the example earlier, the branch directions of the root node are up and right. Since this is the root node, it does nto have a parent so we ignore that rule.
We then set (0, 0) as the parent of all branch directions, and assign each direction a reference value to its parent. We give the cell at coordinate (0, 1) a parent direction of 4 (down), the one at (1, 0) a parent direction of 8 (left).

```
-------   -------
-------   ---@---
---3---   ---3@--
-------   -------
-------   -------
```
We then iterate through all children of (0, 0). Let's start with (0,1).
```
-------     
---X---  
---3@--     
-------   
-------   
```
We then get all non-empty neighbors of (0, 1), as expressed with the symbol \#
```
-------   ---#---  
---X---   --#X#-- 
---3@--   ---3@--   
-------   -------  
-------   -------  
```
We then get the powerset of all non-empty directions. The directions up, right and left are converted into their respective int values: {1, 2, 4}
And we calculate for P{ 1, 4, 8 }, which produces:
```
{ {}, {1}, {2}, {4}, {1, 2}, {1, 4}, {2, 4}, {1, 2, 4} }
```
We then get the parent direction of (0, 1) which we set earlier as 8, and append it to every element in the powerset. So our updated set would be:
```
{ {8}, {1, 8}, {2, 8}, {4, 8}, {1, 2, 8}, {1, 4, 8}, {2, 4, 8}, {1, 2, 4, 8} }
```
Lastly, we take the sum of the elements of each sub element to get the room IDs, which will now be out room selection.
```
{8, 9, A, C, B, D, E, F}
```
We then select a random element from this list and set it as the coordinate's room ID. 
```
------- 
---A---
---3@-- 
-------
-------
```
Then, we mark all branching directions of the room (E) excluding its parent.
```
------- 
--@E@--
---3@-- 
-------
-------
```

We repeat the same sequence of events for (1, 0), and it should look like this:
```
-------   -------   -------   -------
--@E@--   --@E@--   --@E@--   --@E@--
---3x--   ---3X#-   ---3C--   ---3C--
-------   ----#--   -------   ----@--
-------   -------   -------   -------
```
<!---
We configure its cell data like this:
```
cell_data[root_room][0, null, null, [1, 2, 4, 8]]
```
The indexes for the cell data are as follows:
| Index | Label             | Description                                                                                                  |
| ----- | ----------------- | ------------------------------------------------------------------------------------------------------------ |
| 0     | Depth             | How many rooms to traverse before reaching the root room                                                     |
| 1     | Parent Direction  | The direction of the parent relative to the current cell, expressed as a bit flag int                        |
| 2     | Parent Position   | The position of the parent cell, expressed as a Vector2i.                                                    |
| 3     | Open Directions   | An array of all the unoccupied von neumann neighbors of the cell, each direction expressed as a bit flag int |
---> 
will continue later.


