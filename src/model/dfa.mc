include "graph.mc"
include "char.mc"
include "map.mc"
include "string.mc"

-- Represents a deterministic finite automaton.
-- Equality and print functions are required for
-- the states (eqv,s2s) and labels (eql,l2s) for the 
-- construct function (dfaConstr).

-- States are represented by a vertex in a directed graph.
-- They are unique integers, there cannot be two states
-- whose value of the equality function is true.

-- transitions are represented as edges in a directed graph
-- (digraph), where the vertices are states. All labels for
-- the transitions are chars. All labels between two states
-- also has to be unique. 

type DFA = {
             graph: Digraph,
             alphabet: [b],
             startState: a,
             acceptStates: [a]
            }
	    
-- get equality function for states
let dfaGetEqv = lam dfa.
    dfa.graph.eqv

-- get equality functions for labels
let dfaGetEql = lam dfa.
    dfa.graph.eql

-- get all states in dfa
let dfaStates = lam dfa.
    digraphVertices dfa.graph

-- get all transitions in dfa
let dfaTransitions = lam dfa.
    digraphEdges dfa.graph


-- check for specific duplicate label
recursive
let checkSpecificDuplicate = lam trans. lam rest. lam eqv. lam eql.
    if(eqi (length rest) 0) then false
    else
    let first = head rest in
    let rest = tail rest in
    if(and (eqv first.0 trans.0) (eql first.2 trans.2)) then true
    else checkSpecificDuplicate trans rest eqv eql
end

-- check for duplicate labels
recursive
let checkDuplicateLabels = lam trans. lam eqv. lam eql.
    if(eqi (length trans) 1) then (false, (0,0))
    else
    let first = head trans in
    let rest = tail trans in
    if(checkSpecificDuplicate first rest eqv eql) then (true, (first.0, first.2))
    else
    checkDuplicateLabels rest eqv eql
end

-- check that all labels for transitions are in the alphabet
let dfaCheckLabels = lam graph. lam alph. lam eql.
    all (lam x. (any (lam y. eql x.2 y) alph)) graph

-- check that values are accaptable for the DFA
let dfaCheckValues = lam trans. lam s. lam alph. lam eqv. lam eql. lam accS. lam startS.
    if not (dfaCheckLabels trans alph eql) then error "Some labels are not in the defined alphabet" else
        if not (setIsSubsetEq eqv accS s) then error "Some accepted states do not exist" else 
        if not (setMem eqv startS s) then error "The start state does not exist"
        else
	let err = checkDuplicateLabels trans eqv eql in
	if(err.0) then error "There are duplicate labels for same state outgoing transition at"
	else true

-- States are represented by vertices in a directed graph
let dfaAddState =  lam dfa. lam state.{
        graph = (digraphAddVertex state dfa.graph),
        alphabet = dfa.alphabet,
        startState = dfa.startState,
        acceptStates = dfa.acceptStates
    }


-- Transitions between two states are represented by edges between vertices
let dfaAddTransition = lam dfa. lam trans.
    {
        graph = (digraphAddEdge trans.0 trans.1 trans.2 dfa.graph),
        alphabet = dfa.alphabet,
        startState = dfa.startState,
        acceptStates = dfa.acceptStates
    }
    

let dfaConstr = lam s. lam trans. lam alph. lam startS. lam accS. lam eqv. lam eql.
    if dfaCheckValues trans s alph eqv eql accS startS then
    let emptyDigraph = digraphEmpty eqv eql in
    let initDfa = {
    graph = emptyDigraph,
    alphabet = alph,
    startState = startS,
    acceptStates = accS
    } in
    foldl dfaAddTransition (foldl dfaAddState initDfa s) trans
    else error "The values are not right"
    

-- returns true if state s is a accapted state in the dfa
let isAcceptedState = lam s. lam dfa. 
    setMem dfa.graph.eqv s dfa.acceptStates

-- check if there is a transition with label lbl from state s
let stateHasTransition = lam s. lam trans. lam lbl.
    let neighbors = digraphEdgesFrom s trans in
    --check if lbl is a label in the neighbors list
    setMem trans.eql lbl (map (lam x. x.2) neighbors)

-- get next state from state s with label lbl. Throws error if no transition is found
let nextState = lam from. lam graph. lam lbl.
    let neighbors = digraphEdgesFrom from graph in
    let nxt = find (lam x. graph.eql x.2 lbl) neighbors in
    match nxt with Some t then
    -- The transition contains (from,to,label). Take out 'to' state
    t.1
    else error "No transition was found"

-- goes through the dfa, one char of the input at a time. Returns a list of {state, status, input}
-- where status is either 1 (accepted) 0 (neutral) -1 (stuck) or -2 (not accepted)
recursive
let makeInputPath = lam i. lam currentState. lam inpt. lam dfa. 
    let graph = dfa.graph in
    if (eqi (length inpt) 0) then
        if (isAcceptedState currentState dfa) then [{state = currentState,index = i, status = 1}]
        else [{state = currentState,index = i, status = negi 2}]
    else 
    let first = head inpt in
    let rest = tail inpt in 
    -- check if transition exists. If yes, go to next state
    if stateHasTransition currentState graph first then
        let config = [{state = currentState,index = i, status = 0}] in
        join [config, (makeInputPath (addi i 1) (nextState currentState graph first) rest dfa) ]
    else [{state = currentState,index = i, status = negi 1}]
end

let dfaAcceptedInput = lam inpt. lam dfa.
    let path = makeInputPath (negi 1) dfa.startState inpt dfa  in
    if (lti (length path) (length inpt)) then "stuck" else
    let last = last path in
    if (isAcceptedState last dfa) then "accepted" else "not accepted"

mexpr
let alphabet = ['0','1'] in
let states = [0,1,2] in
let transitions = [(0,1,'1'),(1,1,'1'),(1,2,'0'),(2,2,'0'),(2,1,'1')] in
let startState = 0 in
let acceptStates = [2] in 
let newDfa = dfaConstr states transitions alphabet startState acceptStates eqi eqchar in
utest setEqual eqchar alphabet newDfa.alphabet with true in
utest eqi startState newDfa.startState with true in
utest setEqual eqi acceptStates newDfa.acceptStates with true in
utest (digraphHasVertices states newDfa.graph) with true in
utest (digraphHasEdges transitions newDfa.graph) with true in
utest dfaCheckLabels transitions alphabet eqchar with true in
utest dfaCheckLabels [(1,2,'2')] alphabet eqchar with false in
utest (digraphHasEdges [(1,2,'1')] (dfaAddTransition newDfa (1,2,'1')).graph) with true in
utest (digraphHasVertex 7 (dfaAddState newDfa 7).graph) with true in
utest isAcceptedState 2 newDfa with true in
utest isAcceptedState 3 newDfa with false in
utest nextState 1 newDfa.graph '0' with 2 in
utest makeInputPath (negi 1) newDfa.startState "10" newDfa  with [{status = 0,state = 0,index = (negi 1)},{status = 0,state = 1,index = 0},{status = 0,state = 2,index = 1}] in
-- utest makeInputPath 0 "1011" newDfa newDfa.startState with [0,1,2,1,1] in
-- utest makeInputPath 0 "010" newDfa newDfa.startState with [0] in
-- utest makeInputPath 0 "10" newDfa newDfa.startState with [0,1,2] in
-- utest makeInputPath 0 "00000000111111110000" newDfa newDfa.startState with [0] in
-- utest makeInputPath 0 "" newDfa newDfa.startState with [0] in
-- utest dfaAcceptedInput "1010" newDfa with "accepted" in
-- utest dfaAcceptedInput "1011" newDfa with "not accepted" in
-- utest dfaAcceptedInput "00000000111111110000" newDfa with "stuck" in
()
