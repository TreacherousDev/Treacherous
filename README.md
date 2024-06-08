# Treacherous

A family of cellular procedural generation algorithms powered by probabilistic, context-sensitive tree automata.

### A. Roguelike Dungeons
![Dungeons](https://github.com/TreacherousDev/Treacherous/assets/55629534/217a8cbd-9a1d-48af-a7fa-77cbb47b3384)

### B. Caverns
![Caverns](https://github.com/TreacherousDev/Treacherous/assets/55629534/b4d8eb0e-657a-43f3-bf0d-1ec7715559fd)

### C. Mazes
![Mazes](https://github.com/TreacherousDev/Treacherous/assets/55629534/56503eb5-d377-4c94-8c44-ef030b323fb4)


# Introduction to Tree Automata
A tree automaton is a computational model used in computer science and mathematics to process and analyze tree-like structures.

Formally, a tree automaton comprises a set of states, a transition function, and acceptance criteria. These automata traverse a tree structure in a top-down manner, moving from node to node based on the transition function and changing states accordingly. At each step, the automaton reads the current node's label and transitions to available states according to the rules defined in the transition function.

Consider the language below:
```
S --> A
A --> A | A + b | b | A + c | c
```
With this set of rules, a sample production would look like this:
```
    S
    |
    A
   / \
  A   b
 / \
A   c
|
A
|
b
```
The example above  is what can be described as a context-free tree automaton. The transition functions are based solely on the current state of the automaton and the label of the current node being processed in the tree. These transitions are context-free in nature and do not consider the larger context or surrounding nodes.

In context sensitive tree automata meanwhile, transitions are based not only on the current node's label but also on the context or surrounding nodes. The rules governing transitions in context sensitive automata take into account a broader context, allowing for more sophisticated language recognition.   
This procedural generator is exactly that. Production of rooms are implemented on a 2 dimensional grid, and is context-sensitive to its surrounding von neumann neighbors, in such that a node can only produce a new node towards a valid (unoccupied) cell.

In the diagram below, X has an unobstructed path to all its von neumann neighbors.  As such, it can produce a new node on all 4 directions
```
-------
-------
---X---
-------
-------
```
In this next diagram however, the left and right neighbors are obstructed, so it can only produce a new node above and below.
```
-------
-------
--OXO--
-------
-------
```

# Defining the Rules
This tree automaton can be defined by the following rules and constraints: 
1. The automaton is implemented on a 2 dimensional grid. Each node in the tree occupies one cell, and can detect the state of its von neumann neighbors.
2. Each node stores a reference direction to its parent.
3. A node represents a room, which must comprise of 1 or more branch directions from the set of all cardinal directions (up, right, down, left).  
We can create 15 unique rooms by combining 1 to 4 directions like so:.  
![mapcombos](https://github.com/TreacherousDev/Cellular-Procedural-Generation-with-Tilemaps/assets/55629534/243fadcb-2b51-468b-ba0d-9513f2921067)
4. Each room shall produce 1 room for each branch, 1 cell away towards its respective direction. The branch connecting to its parent is excluded from this rule.
5. Each room produced must consist of zero or more branches connecting to an unoccupied von neumann neighbor, plus a brach connecting to its parent.
6. The automata initializes with a root room which must contain 1 or more branches connecting to an unoccupied von neumann neighbor.

## Formal Grammar Definition
With this set of rules, the grammar for our automata will be as follows:
```
Let directions = D
	D: {up, right, down, left}
Let opposite direction = O(x)
	O(up) = down
	O(right) = left
	O(down) = up
	O(left) = right
Let branch = B
	B ∈ D
Let unoccupied directions = N
	N ⊆ D | B in N = unoccupied, for every B in N
Let room produced = R'
	R' = { A + O(B) | A ⊆ N }

S = { R | R ⊆ N | R ≠ ∅ }
S --> { R' | R' = A + O(B) | A ⊆ N } at location B from S, for every B in S
R --> { R' | R' = A + O(B) | A ⊆ N } at location B from R, for every B in R, excluding parent direction
```

## Sample Production
Let's take this illustration below as an example. The root room is {right}, and must transition to all its open branches. Since it has a right branch, it must spawn a valid room to its right neighbor.
![Screenshot (542)](https://github.com/TreacherousDev/Cellular-Procedural-Generation-with-Tilemaps/assets/55629534/5d105a1f-b875-440a-aea0-fdbbc6bc95e3)
```
Let S = {right}

N(right) = {right, down}
O(right) = left

{right} --> ( {left} | {right, left} | {down, left} | {right, down, left} ) at location right from S
```
Here, we take {right, down, left} as the production of {right}, so we produce the selected room at its right neighbor. Then, we get the selected room's directions and transition to all non-parent directions. In this case, we shall produce a valid room to its right neighbor and another to its down neighbor..
![Screenshot (543)](https://github.com/TreacherousDev/Cellular-Procedural-Generation-with-Tilemaps/assets/55629534/9a2da299-1bcf-4d3f-822c-f194b30a66fe)
```
Let R = {right, down, left}

Parent directon = left

N(right) = {right}
O(right) = left

N(down) = {down}
O(down) = up

{left, right, down} --> ( {left} | {right, left} ) at location right from R    +    ( {up} | (up, down} ) at location down from R
```
The automaton will continue transitioning unitll there are no more transitions left to occur. An end state is determined if a room R' produced is one of 4 primary directions {up, right, down, left}, as it means that it has only a branch to its parent and cannot produce more branches, according to rule 4.


# Automata Sequence
## Design Architecture
To avoid collision conflict, it is crucial that room production is done on a single thread. That is, there must only be one active room transitioning at any given time, and transition calculation and execution must be done completely before selecting another room to activate.
To ensure a fair growth pattern, producton of new rooms must be done in a breadth first manner. That is, we select active rooms by batch, and we set the newly produced rooms from the current batch as the next batch. We only move to the next batch after we are done iterating through all rooms in the current batch.

## Syntax Implementation
We can assign each primary direction an int value that acts as a bit flag. In this algorithm, the values assigned are as follows:  
| Direction     | Int Value     |
| ------------- | ------------- |
| UP            | 1             |
| RIGHT         | 2             |
| DOWN          | 4             |
| LEFT          | 8             |

With these assigned values, we can map each room to their unique room number by getting the sum of their directions.
For demonstration purposes, numbers shall be expressed in hexadecimal notation (1 - F) so that each number occupies only 1 character to make diagrams look more uniform.  
![tileset](https://github.com/TreacherousDev/Treacherous/assets/55629534/8d6f0203-dd5b-4180-b6b6-af52358b6e81)

## Sequence
The algorithm starts by initializing a root room from the origin. Its branch directions are then marked and set as its children.  
In this example, the root room is 3, which has an up (1) and right (2) direction.  
So we set the cell above it and the cell to its right as its children, and mark them accordingly. We'll use the symbol @ to visualize marked cells.
```
-------   -------
-------   ---@---
---3---   ---3@--
-------   -------
-------   -------
```
We then proceed with the folllowing sequence:
1. For each marked cell, do as follows:
   1.  Get all its unoccupied neighbors
   2.  Get the powerset of the combination of all unoccupied neighbors (include empty)
   3.  For each set in the powerset, append the parent direction and get the sum of all elements in each set. Store the values in a list called room_selection
   5.  Select 1 random element from room_selection and set it as the new value of the current cell
   6.  Based on its value (room ID), mark all the opening directions and set them as children, excluding the direction of its parent.
2. Get the next batch of marked cells and repeat.

Let's run through this algorithm step by step and simulate the map in real time.  
In the example earlier, there are 2 marked cells. We iterate through all marked cells starting with the top one. The symbol X will be used to show the currently selected cell.
```
-------     
---X---  
---3@--     
-------   
-------   
```
We get all unoccupied von neumann neighbors of the currently selected cell.   
In this case, the unoccupied neighbors are up, right and left, as expressed with the # symbols.
```
-------   ---#---  
---X---   --#X#-- 
---3@--   ---3@--   
-------   -------  
-------   -------  
```
We then get the powerset of the set of all unoccupied neighbors.  
Converted into their respective int values:
```
{up, right, left}
{1, 2, 8}
```
We calculate for its powerset P( {1, 2, 8} ) which produces:
```
{ {}, {1}, {2}, {8}, {1, 2}, {1, 8}, {2, 8}, {1, 2, 8} }
```
We then get the parent direction of the current cell (which is 4 as the parent is located down), and append it to every element in the powerset. So our updated set would be:
```
{ {4}, {1, 4}, {2, 4}, {8, 4}, {1, 2, 4}, {1, 8, 4}, {2, 8, 4}, {1, 2, 8, 4} }
```
Lastly, we take the sum of the elements of each sub-element to get the room IDs, which will now be our room selection.
```
{4, 5, 6, 7, C, D, E, F}
```
We then select a random element from this list and set it as the coordinate's new value (room ID). 
```
------- 
---E---
---3@-- 
-------
-------
```
Then, we mark all its branching directions according to its room ID (E) excluding its parent direction, and set those cells as its children.  
```
E: [2, 4, 8]
parent direction: 4
[2, 4, 8] - 4 = [2, 8]
Mark directions 2 and 8 and set as children
```
We'll use the symbol $ to differentiate newly marked cells from the currently marked cells we iterate through.
```
------- 
--$E$--
---3@-- 
-------
-------
```

We repeat the same sequence of events for the right cell, and it should look like this:
```
-------   -------   -------   -------
--$E$--   --$E$--   --$E$--   --$E$--
---3X--   ---3X#-   ---3C--   ---3C--
-------   ----#--   -------   ----$--
-------   -------   -------   -------
```
Notice how X now detects up as an occupied direction, because it was previously updated by the cell that came before it. This avoids collision conflict that would have otherwise resulted if both of them were to detect directions at the same time.

After all marked cells are iterated through, we get the next batch of marked cells and iterate through them. So we'll transform all $ into @ and repeat the process till there isnt any $ left to update.  
Sample production:
```
-------
--$E$--
---3C--
----$--
-------
	  
-------   -------   --#----   -------   -------   ----#--   -------   ----$--   ----$--   ----$--   ----$--   ----$--   
--@E@--   --XE@--   -#XE@--   --2E@--   --2EX--   --2EX#-   --2E9--   --2E9--   --2E9--   --2E9--   --2E9--   --2E9--   
---3C--   ---3C--   --#3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   
----@--   ----@--   ----@--   ----@--   ----@--   ----@--   ----@--   ----@--   ----X--   ---#X#-   ----9--   ---$9--   
-------   -------   -------   -------   -------   -------   -------   -------   -------   ----#--   -------   -------   

----@--   ----X--   ---#X#-   ----C--   ---$C--   ---$C--   ---$C--   ---$C--   ---$C--
--2E9--   --2E9--   --2E9--   --2E9--   --2E9--   --2E9--   --2E9--   --2E9--   --2E9--
---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--
---@9--   ---@9--   ---@9--   ---@9--   ---@9--   ---X9--   --#X9--   ---A9--   --$A9--
-------   -------   -------   -------   -------   -------   ---#---   -------   -------

---@C--   ---XC--   --#XC--   ---2C--   ---2C--   ---2C--   ---2C--   ---2C--
--2E9--   --2E9--   --2E9--   --2E9--   --2E9--   --2E9--   --2E9--   --2E9--
---3C--   ---3C--   ---3C--   ---3C--   ---3C--   --#3C--   ---3C--   ---3C--
--@A9--   --@A9--   --@A9--   --@A9--   --XA9--   -#XA9--   --6A9--   --6A9--
-------   -------   -------   -------   -------   --#----   -------   --$----

---2C--   ---2C--   ---2C--   ---2C--
--2E9--   --2E9--   --2E9--   --2E9--
---3C--   ---3C--   ---3C--   ---3C--
--6A9--   --6A9--   --6A9--   --6A9--
--@----   --X----   -#X#---   --1----
```
If we map each number to their respective room value, it should look like this:

![map](https://github.com/TreacherousDev/Cellular-Procedural-Generation-with-Tilemaps/assets/55629534/9c00c436-1a28-4e9c-86d3-0e3ae5c57dce)


# Map Customization
Because our tree automata is not deterministic, in that node production relies on picking a random element from an element pool, there is no proper way to control the growth of the map to adhere to a certain cell count. One production might lead to an incredibly small room, while another might be infinitely large. With this, there are 2 main problems we have to tackle, which are:
1. Map Closing, for when the automata approaches the cell count limit
2. Map Expansion, for when the automata stops prematurely before the expected limit is reached

## Map Closing
Handling map closing is pretty straightforward. Each node produced will be given access to a global variable that will be used to track the current cell count. Each node production increases the value of this variable by 1. A map size constant can then be declared to compare against this variable, so that the generator will force spawn closing rooms when it approaches the desired size. This can be easily achieved by referencing the node's parent direction and setting its tilemap coordinate to the direction's assigned room ID.


Take this given map configuration with 10 determined rooms from earlier as an example. If we declared the map size to be 11, then X has to spawn a closing room as to not produce any more rooms on the next iteration. 

``` 
---2C--   
--2E9--  
---3C--  
--6A9--   
-#X#--- 
```
You get the parent direction of X, which in this case is up, and and assign it as the new value of the rom ID of X, disregarding all other options.
``` 
up = 1

---2C--   
--2E9--  
---3C--  
--6A9--   
--1---- 
```

## Map Expansion
Similar to map closing, we can also conditionally manipulate the spawning conditions of the node in such that it is guaranteed to produce more branches. We can set a variable that tracks the current number of pending spawners, and if it is less than a certain amount, remove closing rooms from the room selection. 

Take this configuration with 9 determined rooms and 1 pending for instance:
If the desired map size is 11 or higher, then we remove the parent direction from the room pool to stop it from closing prematurely.
```
---2C--   
--2E9--   
--#3C--  
-#XA9--   
--#----

{ {}, {1}, {4}, {8}, {1, 4}, {1, 8}, {4, 8}, {1, 4, 8} }
{ {2}, {2, 1}, {2, 4}, {2, 8}, {2, 1, 4}, {2, 1, 8}, {2, 4, 8}, {2, 1, 4, 8} }
parent direction removed = { {2, 1}, {2, 4}, {2, 8}, {2, 1, 4}, {2, 1, 8}, {2, 4, 8}, {2, 1, 4, 8} }
```



We can also implement a heuristic with a higher depth and perfect precision by removing high numbered branches as the map approaches the max size. 
In the example earlier in map closing, if instead the max map size is 12, we do not assign X as the parent room direction as that would close the map 1 cell prematurely. But what we can do is remove the rooms with 3 or more branches to ensure that the next iteration can only spawn a max of 1 other cell to complete the 12 room map size.
``` 
---2C--   
--2E9--  
---3C--  
--6A9--   
-#X#---

Cell Count: 10
Desired Map Size: 12
{ {], {2}, {8}, {2, 8} }
{ {1], {1, 2}, {1, 8}, {1, 2, 8} }
3 or more directions removed = { {1], {1, 2}, {1, 8} }
cell count not yet reached, remove closing room = { {1, 2}, {1, 8} }
selection = { 3, 9 }

---2C--   ---2C--   ---2C--  
--2E9--   --2E9--   --2E9--    
---3C--   ---3C--   ---3C--   
--6A9--   --6A9--   -#6A9--   
--3----   -@3----   #X3----   

Cell Count: 11
Desired Map Size: 12
{ {], {1}, {8}, {1, 8} }
{ {2], {2, 1}, {2, 8}, {2, 1, 8} }
cell count approaching room, select closing room = { {2} }
selection = { 2 }

---2C--     
--2E9--    
---3C--    
--6A9--   
-23----
```


## Advanced Map Expansion
There are certain cases where removing closing rooms from the room pool is not enough to ensure that the cell quota is reached. Pending nodes that are supposed to expand to at least one other direction can get completely blocked by surrounding cells and will not be able to branch out any further. Below is an example:

![image](https://github.com/TreacherousDev/Treacherous/assets/55629534/246700b7-4424-455e-8cb6-22e255eec9fe)


Therefore, we must implement a way for the map to expand from existing cells, and consequentially change their room ID on the fly to accomodate for the expansion.

We do this by having each room keep track of how many of its von neumann neighbors are currently empty. If an expansion is requested, we can then select one room from the list of rooms with at least 1 empty neighbor to expand from. Then, we select one of its available branching directions and place a connecting node adjacent to it. We then update the room that was expanded from, to also include the new expanded direction. Lastly, we handle the logic for determining the spawnable rooms of the newly created node like normal, and repeat the process with as many expansions as needed.

##
Manipulating the Map Structure

WIP - Will keep this updated!
