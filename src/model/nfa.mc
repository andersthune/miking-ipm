include "dfa.mc"

-- Represents a nondeterministic finite automaton
-- Equality and print functions are required for
-- the states (eqv,s2s) and labels (eql,l2s) for the 
-- construct function (nfaConstr).

-- States are represented by a vertex in a directed graph.
-- They are unique, there cannot be two states whose value of the
-- equality function is true.

-- transitions are represented as edges in a directed graph
-- (digraph), where the vertices are states.

type NFA = {
     graph: Digraph,
     alphabet: [b],
     startState: a,
     acceptStates: [a]
}

	    
-- get equality function for states
let nfaGetEqv = lam nfa.
    nfa.graph.eqv

-- get equality functions for labels
let nfaGetEql = lam nfa.
    nfa.graph.eql

-- get all states in nfa
let nfaStates = lam nfa.
    digraphVertices nfa.graph

-- get all transitions in nfa
let nfaTransitions = lam nfa.
    digraphEdges nfa.graph

-- check that all labels for transitions are in the alphabet
let nfaCheckLabels = lam graph. lam alph. lam eql.
    all (lam x. (any (lam y. eql x.2 y) alph)) graph

-- check that values are accaptable for the NFA
let nfaCheckValues = lam trans. lam s. lam alph. lam eqv. lam eql. lam accS. lam startS.
    if not (nfaCheckLabels trans alph eql) then error "Some labels are not in the defined alphabet" else
        if not (setIsSubsetEq eqv accS s) then error "Some accepted states do not exist" else 
        if not (setMem eqv startS s) then error "The start state does not exist"
        else true

-- States are represented by vertices in a directed graph
let nfaAddState =  lam nfa. lam state.{
        graph = (digraphAddVertex state nfa.graph),
        alphabet = nfa.alphabet,
        startState = nfa.startState,
        acceptStates = nfa.acceptStates
    }


-- Transitions between two states are represented by edges between vertices
let nfaAddTransition = lam nfa. lam trans.
    {
        graph = (digraphAddEdge trans.0 trans.1 trans.2 nfa.graph),
        alphabet = nfa.alphabet,
        startState = nfa.startState,
        acceptStates = nfa.acceptStates
    }


-- returns true if state s is a accapted state in the nfa
let nfaIsAcceptedState = lam s. lam nfa. 
    setMem nfa.graph.eqv s nfa.acceptStates


-- check if there is a transition with label lbl from state s
let nfaStateHasTransition = lam s. lam trans. lam lbl.
    let neighbors = digraphEdgesFrom s trans in
    --check if lbl is a label in the neighbors list
    setMem trans.eql lbl (map (lam x. x.2) neighbors)

-- get next state from state s with label lbl. Throws error if no transition is found
let nfaNextState = lam from. lam graph. lam lbl.
    let neighbors = digraphEdgesFrom from graph in
    let nxt = partition (lam x. graph.eql x.2 lbl) neighbors in
    let matches = nxt.0 in
    match matches with [] then
    error "No transition was found"
    else
    -- The transition contains (from,to,label). Take out 'to' state
    matches



-- goes through the nfa, one state of the input at a time. Returns a list of {state, status, input}
-- where status is either 1 (accepted) 0 (neutral) -1 (stuck) or -2 (not accepted)
recursive
let nfaMakeInputPath = lam i. lam currentState. lam inpt. lam nfa.
    let graph = nfa.graph in
    if (eqi (length inpt) 0) then
       if (nfaIsAcceptedState currentState nfa) then [{state = currentState,index = i, status = 1}]
       else [{state = currentState, index = i, status = negi 2}]
    else
    let first_inpt = head inpt in
    let rest_inpt = tail inpt in 
    -- check if transition exists. If yes, go to next state
    if nfaStateHasTransition currentState graph first_inpt then
       let config = [{state = currentState,index = i, status = 0}] in
       let next = nfaNextState currentState graph first_inpt in
       let branches = map (lam x. join [config, (nfaMakeInputPath (addi i 1) x.1 rest_inpt nfa)]) next in
    	join branches
    else
    [{state = currentState, index = i, status = negi 1}]
end    




-- constructor for the NFA
let nfaConstr = lam s. lam trans. lam alph. lam startS. lam accS. lam eqv. lam eql.
    if nfaCheckValues trans s alph eqv eql accS startS
    then
    let emptyDigraph = digraphEmpty eqv eql in
    let initNfa = {
    graph = emptyDigraph,
    alphabet = alph,
    startState = startS,
    acceptStates = accS
    } in
    foldl nfaAddTransition (foldl nfaAddState initNfa s) trans
    else {}


mexpr
let alphabet = ['0','1'] in
let states = [0,1,2] in
let transitions = [(0,1,'1'),(1,1,'1'),(1,2,'0'),(2,2,'0'),(2,1,'1')] in
let startState = 0 in
let acceptStates = [2] in 
let newNfa = nfaConstr states transitions alphabet startState acceptStates eqi eqchar in
utest setEqual eqchar alphabet newNfa.alphabet with true in
utest eqi startState newNfa.startState with true in
utest setEqual eqi acceptStates newNfa.acceptStates with true in
utest (digraphHasVertices states newNfa.graph) with true in
utest (digraphHasEdges transitions newNfa.graph) with true in
utest nfaCheckLabels transitions alphabet eqchar with true in
utest nfaCheckLabels [(1,2,'2')] alphabet eqchar with false in
utest (digraphHasEdges [(1,2,'1')] (nfaAddTransition newNfa (1,2,'1')).graph) with true in
utest (digraphHasVertex 7 (nfaAddState newNfa 7).graph) with true in
utest isAcceptedState 2 newNfa with true in
utest isAcceptedState 3 newNfa with false in
utest nextState 1 newNfa.graph '0' with 2 in
utest makeInputPath "1010" newNfa newNfa.startState with [0,1,2,1,2] in
utest makeInputPath "1011" newNfa newNfa.startState with [0,1,2,1,1] in
utest makeInputPath "010" newNfa newNfa.startState with [0] in
utest makeInputPath "10" newNfa newNfa.startState with [0,1,2] in
utest makeInputPath "00000000111111110000" newNfa newNfa.startState with [0] in
utest makeInputPath "" newNfa newNfa.startState with [0] in
()


