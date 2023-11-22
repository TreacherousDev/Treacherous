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
The algorithm starts by initializing a root room from [0, 0]. The branch direction of the room are then marked and set as children of this room.  
In this example, the root room is 3, which has an up (1) and right (2) direction.  
So we set [0, 1] (up) and [1, 0] (right) as children of [0, 0] and mark them accordingly. We'll use the symbol @ to visualize marked cells.
```
-------   -------
-------   ---@---
---3---   ---3@--
-------   -------
-------   -------
```
We then proceed with the folllowing sequence:
1. For each marked cell, do as follows:
   1.  Get all its non-empty neighbors
   2.  Get the powerset of the combination of all non-empty neighbors (include empty)
   3.  For each set in the powerset, append the parent direction and get the sum of all elements in each set. Store the values in a list called room_selection
   5.  Select 1 random element from room_selection and set it as the new value of the current cell
   6.  Mark all the opening directions of the current cell based in its value (room ID), excluding the direction of its parent
   7.  For each marked direction, set it as a child of the current cell.
2. Get the next batch of marked directions and repeat.

Let's run through this algorithm step by step and simulate the map in real time.
In the example earlier, there are 2 marked cells: [0, 1] and [1, 0]
We iterate through all marked cells starting with [0, 1]. The symbol X will be used to show the currently selected child.
```
-------     
---X---  
---3@--     
-------   
-------   
```
We get all empty von neumann neighbors of X. In this case, the empty neighbors are up, right and left, as expressed with the # symbols.
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
We then select a random element from this list and set it as the coordinate's new value (room ID). 
```
------- 
---E---
---3@-- 
-------
-------
```
Then, we mark all its branching directions based on its room ID (E) excluding its parent, and set those cells as its children.  
We'll use the symbol $ to differentiate newly marked cells from the current marked cells we iterate through.
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

We repeat the same sequence of events for (1, 0), and it should look like this:
```
-------   -------   -------   -------
--$E$--   --$E$--   --$E$--   --$E$--
---3X--   ---3X#-   ---3C--   ---3C--
-------   ----#--   -------   ----$--
-------   -------   -------   -------
```
After all marked cells are iterated through, we get the next batch of marked cells and iterate through them. So we'll transform all $ into @ and repeat the process till there isnt any $ or @ left to update. 
Example iteration:
```
-------
--$E$--
---3C--
----$--
-------
      
-------   -------   --#----   -------   -------   ----#--   -------   ----$--   ----$--   ----$--   ----$--   ----$--
--@E@--   --XE@--   -#XE@--   --2E@--   --2EX--   --2EX#-   --2E5--   --2E5--   --2E5--   --2E5--   --2E5--   --2E5--
---3C--   ---3C--   --#3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--
----@--   ----@--   ----@--   ----@--   ----@--   ----@--   ----@--   ----@--   ----X--   ---#X#-   ----9--   ---$9--
-------   -------   -------   -------   -------   -------   -------   -------   -------   ----#--   -------   -------

----@--   ----X--   ---#X#-   ----C--   ---$C--   ---$C--   ---$C--   ---$C--   ---$C--
--2E5--   --2E5--   --2E5--   --2E5--   --2E5--   --2E5--   --2E5--   --2E5--   --2E5--
---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--   ---3C--
---@9--   ---@9--   ---@9--   ---@9--   ---@9--   ---X9--   --#X9--   ---A9--   --$A9--
-------   -------   -------   -------   -------   -------   ---#---   -------   -------

---@C--   ---XC--   --#XC--   ---2C--   ---2C--   ---2C--   ---2C--   ---2C--
--2E5--   --2E5--   --2E5--   --2E5--   --2E5--   --2E5--   --2E5--   --2E5--
---3C--   ---3C--   ---3C--   ---3C--   ---3C--   --#3C--   ---3C--   ---3C--
--@A9--   --@A9--   --@A9--   --@A9--   --XA9--   -#XA9--   --6A9--   --6A9--
-------   -------   -------   -------   -------   --#----   -------   --$----

---2C--   ---2C--   ---2C--   ---2C--
--2E5--   --2E5--   --2E5--   --2E5--
---3C--   ---3C--   ---3C--   ---3C--
--6A9--   --6A9--   --6A9--   --6A9--
--@----   --X----   -#X#---   --1----
```

