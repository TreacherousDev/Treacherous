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
For deomstration purposes, numbers shall be expressed in hexadecimal notation (1 - F) so that each number occupies only 1 character to make diagrams look more uniform.


# Automata Sequence
The algorithm starts by initializing a root room from (0, 0). The branch direction of the cell are marked and set as children of the origin.
In this example, the root room is 3, which has an up (1) and right (2) direction.
So we set (0, 1) and (1,0) as children of (0,0).
```
-------   -------
-------   ---@---
---3---   ---3@--
-------   -------
-------   -------
```
We then proceed with the folllowing sequence:
1. Get all children of the current cell.
2. For each child, do as follows:
   1.  Get all non-empty neighbors
   2.  Get the powerset of the combination of all non-empty neighbors (include empty)
   3.  For each set in the powerset, append the parent direction and get the sum of all elements in each set. Store the values in a list called room_selection
   5.  Select 1 random element from room_selection and set it as the new value of the current cell
   6.  Mark all the opening directions of the current cell, excluding the direction of its parent
   7.  For each marked direction, set it as a child of the current cell.
3. If there exists at least 1 element in next_active_cells:
   1.  Move the contents of next_active_cells to active_cells
   2.  Run the algorithm again.

Let's run through this algorithm step by step and simulate the map in real time.
In the example earlier, the root room has two children: (0,1) and (1,0)
We iterate through all children starting with (0, 1). In the diagram below, X will be used to show the currently selected child.
```
-------     
---X---  
---3@--     
-------   
-------   
```
We get all empty von neumann neighbors of X. In this case, the empty neighbors are up, right and left.
```
-------   ---#---  
---X---   --#X#-- 
---3@--   ---3@--   
-------   -------  
-------   -------  
```
We then get the powerset of the set of all empty neighbors.
Converted into their respective int values:
```
{up, right, left}
{1, 2, 8}
```
We then calculate for P( {1, 2, 4} ), which produces:
```
{ {}, {1}, {2}, {8}, {1, 2}, {1, 8}, {2, 8}, {1, 2, 8} }
```
We then get the parent direction of the current cell (0,1) which is 8 (parent is located down), and append it to every element in the powerset. So our updated set would be:
```
{ {4}, {1, 4}, {2, 4}, {8, 4}, {1, 2, 4}, {1, 8, 4}, {2, 8, 4, {1, 2, 8, 4} }
```
Lastly, we take the sum of the elements of each sub element to get the room IDs, which will now be our room selection.
```
{4, 5, 6, 7, C, D, E, F}
```
We then select a random element from this list and set it as the coordinate's room ID. 
```
------- 
---E---
---3@-- 
-------
-------
```
Then, we mark all branching directions of the cell based on its ID (E) excluding its parent, and set those cells as its children.
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


