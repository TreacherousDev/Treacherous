# Treacherous

A family of cellular procedural generation algorithms powered by probabilistic, context-sensitive tree automata.


# Introduction to Tree Automata
A tree automaton is a computational model used in computer science and mathematics to process and analyze tree-like structures.

Formally, a tree automaton comprises a set of states, a transition function, and acceptance criteria. These automata traverse a tree structure in a top-down manner, moving from node to node based on the transition function and changing states accordingly. At each step, the automaton reads the current node's label and transitions to available states according to the rules defined in the transition function.

Example:
```
S --> A
A --> A | A + b | b | A + c | c

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
The example above  is what can be described as a context-free tree automata. Transition functions are based solely on the current state of the automaton and the label of the current node being processed in the tree. These transitions are context-free in nature and do not consider the larger context or surrounding nodes.

In context sensitive tree automata meanwhile, transitions are based not only on the current node's label but also on the context or surrounding nodes. The rules governing transitions in context sensitive automata take into account a broader context, allowing for more sophisticated language recognition.   
This procedural generator is exactly that. Production of rooms are implemented on a 2 dimensional grid, and is context-sensitive to its surrounding neighbors, in such that a node must only produce a room that branches towards valid (unoccupied) cells.

In the diagram below, X has an unobstructed path to all its von neumann neighbors.  As such, it can produce new nodes on all 4 directions
```
-------
-------
---X---
-------
-------
```
In this next diagram however, the left and right neighbors are obstructed, so it can only produce new nodes above and below.
```
-------
-------
--OXO--
-------
-------
```

# Defining the Rules
This tree automaton can be defined by the following rules and constraints: 
1. The automaton is implemented on a 2 dimensional grid, and each node in the tree can detect the vacancy of its von neumann neighbors.
2. Each node stores a reference direction to its parent.
3. A node represents a room, which must comprise of 1 or more branch directions from the set of all cardinal directions (up, right, down, left).  
We can create 15 unique rooms by combining 1 to 4 directions like so:.  
![mapcombos](https://github.com/TreacherousDev/Cellular-Procedural-Generation-with-Tilemaps/assets/55629534/243fadcb-2b51-468b-ba0d-9513f2921067)
4. Each room shall produce 1 room for each branch, 1 tile away towards its respective direction. The branch connecting to its parent is excluded from this rule.
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

{right} --> {left} | {right, left} | {down, left} | {right, down, left}
```
Here, we take {right, down, left} as the production of {right}, so we produce the selected room at its right neighbor. Then, we get the selected room's directions and transition to all non-parent directions. In this case, the non-parent directions are up and down.
![Screenshot (543)](https://github.com/TreacherousDev/Cellular-Procedural-Generation-with-Tilemaps/assets/55629534/9a2da299-1bcf-4d3f-822c-f194b30a66fe)
```
Let R = {right, down, left}

Parent directon = left

N(right) = {right}
O(right) = left

N(down) = {down}
O(down) = up

{left, right, down} --> ( {left} | {right, left} ) + ( {up} | (up, down} )
```
The automaton will continue transitioning unitll there are no more transitions left to occur. An end state is determined if a room R produced is one of 4 primary directions {up, right, down, left}, as it means that it has only a branch to its parent and cannot produce more branches, according to rule 4.


# Automata Sequence
## Design Architecture
To avoid collision conflict, it is crucial thar the tree automaton produces new rooms in a single thread. That is, there must only be one active room transitioning at any given time, and transition calculation and execution must be done completely before selecting another room to activate.
To ensure a fair growth pattern, producton of new rooms must be done in a breadth first manner. That is, we select active rooms by batch, and we set the newly produced rooms from the current batch as the next batch. We only move to the next batch after we are done iterating through all rooms in the current batch.

## Syntax Implementation
We can assign each primary direction an int value that acts as a bit flag. In this algorithm, the values assigned are as follows:  
| Direction     | Int Value     |
| ------------- | ------------- |
| UP            | 1             |
| RIGHT         | 2             |
| DOWN          | 4             |
| LEFT          | 8             |

With the assigned values, we can map each room to their unique room number by getting the sum of their directions.
For deomstration purposes, numbers shall be expressed in hexadecimal notation (1 - F) so that each number occupies only 1 character to make diagrams look more uniform.  
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
   2.  Get the powerset of the combination of all nunoccupied neighbors (include empty)
   3.  For each set in the powerset, append the parent direction and get the sum of all elements in each set. Store the values in a list called room_selection
   5.  Select 1 random element from room_selection and set it as the new value of the current cell
   6.  Based on its value (room ID), mark all the opening directions and set them as children, excluding the direction of its parent.
2. Get the next batch of marked cells and repeat.

Let's run through this algorithm step by step and simulate the map in real time.
In the example earlier, there are 2 marked cells.
We iterate through all marked cells starting with the top one. The symbol X will be used to show the currently selected cell.
```
-------     
---X---  
---3@--     
-------   
-------   
```
We get all unoccupied von neumann neighbors of the currently selected cell. In this case, the unoccupied neighbors are up, right and left, as expressed with the # symbols.
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
{ {4}, {1, 4}, {2, 4}, {8, 4}, {1, 2, 4}, {1, 8, 4}, {2, 8, 4, {1, 2, 8, 4} }
```
Lastly, we take the sum of the elements of each sub element to get the room IDs, which will now be our room selection.
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
We'll use the symbol $ to differentiate newly marked cells from the currently marked cells we iterate through.
```
E: [2, 4, 8]
parent direction: 4
[2, 4, 8] - 4 = [2, 8]
Mark directions 2 and 8
```
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

WIP - Will keep this updated!
