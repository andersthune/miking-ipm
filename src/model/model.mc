include "./dfa.mc"

-- Represents models that can be visualized and its associated data.
type Model
con Digraph : (Digraph,    vertex2str, edge2str ) -> Model
con DFA     : (DFA, input, state2str,  trans2str) -> Model
con Graph   : (Graph,      vertex2str, edge2str ) -> Model
con NFA     : (NFA, input, state2str,  trans2str) -> Model



mexpr

let alfabeth = ['0','1'] in
let states = ["a","b","c"] in
let transitions = [("a","b",'1'),("b","c",'0'),("c","a",'1')] in
let startState = "a" in
let acceptStates = ["a", "c"] in
let dfa = dfaConstr states transitions alfabeth startState acceptStates (setEqual eqchar) eqchar in
let state2string = lam b. b in
let trans2string = (lam b. [b]) in
let model = DFA(dfa, "1011", state2string, trans2string) in 

utest match model with DFA(d,i,s2s,t2s) then i else "" with "1011" in
utest match model with DFA(d,i,s2s,t2s) then d.acceptStates else "" with ([(['a']),(['c'])]) in 
()