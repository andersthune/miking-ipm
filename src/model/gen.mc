include "string.mc"
include "map.mc"
include "dfa.mc"

-- Formatting the states
recursive
let parseStates = lam states. lam startState. lam dfa. lam output. 
    if (eqi (length states) 0) then output
    else
    let first = head states in
    let rest = tail states in
    let parsedFirst = strJoin "" [
    "{\"name\":\"",
    (dfa.s2s first),
    "\"},\n"] in
    parseStates rest startState dfa (concat output parsedFirst)
end

let parseVertices = lam vertices. lam v2s.
        strJoin ""(map (lam x. strJoin "" [
            "{",
            "\"name\":\"",
            v2s x,
            "\"},\n"
        ]) vertices)

-- Find the Starting State ID
recursive
let startID = lam states. lam startState. lam dfa.
    let first = head states in
    let rest = tail states in
    if (dfa.eqs startState first) then (strJoin "" ["startID = '", (int2string first.id) , "',\n"])
    else
    startID rest startState dfa
end

let eqTrans = lam eq. lam l. lam r. if and (eq (l.0) (r.0)) (eq (l.1) (r.1)) then true else false

-- parse transitions and squash transitions between the same states.
recursive
let parseTransitions = lam trans. lam v2s. lam eqv.
    if (eqi (length trans) 0) then "" else
    let first = head trans in
    let parsedFirst = ["{\"from\": \"", (v2s (first.0)), "\", \"to\": \"" ,(v2s (first.1)) , "\", \"label\": \"" , (first.2) , "\"},\n"] in
    if(eqi (length trans) 1) then
    strJoin "" parsedFirst
    else
    let second = head (tail trans) in
    if (eqTrans eqv first second) then parseTransitions (join [[(first.0,first.1,join [first.2,second.2])], (tail (tail trans))]) v2s eqv
    else
    join [strJoin "" parsedFirst, parseTransitions (tail trans) v2s eqv]
end

let eqEdge = lam eq. lam l. lam r. if or (and (eq (l.0) (r.0)) (eq (l.1) (r.1))) (and (eq (l.1) (r.0)) (eq (l.0) (r.1))) then true else false 
let parseEdges = lam edges. lam v2s. lam l2s. lam eqv.
        let edges_string = map (lam x. (x.0,x.1,l2s x.2)) edges in
        parseTransitions edges_string v2s eqv

-- Getting the input path parsed
recursive
let parseInputPath = lam path. lam output. lam state2string.
    if(eqi (length path) 0) then output
    else
    let first = head path in
    let rest = tail path in
    parseInputPath rest (strJoin "" [output,"\"",(state2string first),"\"", ","]) state2string
end

-- Parse input-line
recursive
let parseInput = lam input. lam output. lam dfa.
    if(eqi (length input) 0) then output
    else
    let first = head input in
    let rest = tail input in
    let output = strJoin "" [output,"\"" ,(dfa.l2s first) , "\","] in
    parseInput rest output dfa
end

-- return a string with n tabs
let tab = lam n. if(lti n 0) then error "Number of tabs can not be smaller than 0" 
    else strJoin "" (unfoldr (lam b. if eqi b n then None () else Some ("\t", addi b 1)) 0)

-- add tabs after every \n to string, tab according to brackets ('{','}','[,']')
recursive
let addTabs = lam inpt. lam t.
    if (eqi (length inpt) 0 ) then ""
    else if (eqi (length inpt) 1) then inpt
    else
    let first = head inpt in
    let snd = head (tail inpt) in
    let rest = tail inpt in
    if (eqchar first '\n') then 
        if or (eqchar snd '}') (eqchar snd ']') then concat (strJoin "" [[first],tab (subi t 1)]) (addTabs rest t) 
        else concat (strJoin "" [[first],tab t]) (addTabs rest t) 
    else if or (eqchar (first) '{') (eqchar first '[') then concat [first] (addTabs rest (addi t 1))
    else if (or (eqchar (first) '}') (eqchar (first) ']')) then concat [first] (addTabs rest (subi t 1)) 
    else concat [first] (addTabs rest t) 
end

-- Parse a DFA to JS code and visualize
let dfaVisual = lam model.
    let dfa = model.model in
    let input = model.input in
    let transitions = map (lam x. (x.0,x.1,dfa.l2s x.2)) (dfaTransitions dfa) in
    let js_code = strJoin "" [
        "{\n",
            "\"type\" : \"dfa\",\n",
            "\"simulation\" : {\n",
                "\"input\" : [", (parseInput input "" dfa),"],\n",
                "\"configurations\" : [", (parseInputPath (makeInputPath input dfa dfa.startState) "" dfa.s2s), "],\n",
                "\"state\" : ","\"",dfaAcceptedInput input dfa,"\"", ",\n",
            "},\n",
            "\"model\" : {\n",
                "\"states\" : [\n",parseStates (dfaStates dfa) dfa.startState dfa "" ,"],\n",
                "\"transitions\" : [\n", (parseTransitions transitions dfa.s2s (dfaGetEqv dfa)) ,"], \n",
                "\"startID\" : \"", (dfa.s2s dfa.startState) , "\",\n",
                "\"acceptedIDs\" : [",(strJoin "" (map (lam s. strJoin "" ["\"", (dfa.s2s s), "\","]) dfa.acceptStates)),"],\n",
            "}\n",
        "},\n"
    ] in
    js_code

-- Parse a digraph to JS code and visualize
let digraphVisual = lam model.
    let digraph = model.model in
    let edges = digraphEdges digraph in
    let node2string = model.v2s in
    let label2string = model.l2s in
    strJoin "" [
    "{\n",
        "\"type\" : \"",model.modelType,"\",\n",
        "\"model\" : {\n",
            "\"nodes\" : [\n",(parseVertices (digraphVertices digraph) node2string) ,"],\n",
            "\"edges\" : [\n", (parseEdges (digraphEdges digraph) node2string label2string digraph.eqv), "], \n",
        "},\n",
    "\n},\n"]

-- Parse a graph to JS code and visualize
let graphVisual = lam model.
    let graph = model.model in
    let edges = graphEdges graph in
    let node2string = model.v2s in
    let label2string = model.l2s in
    strJoin "" [
    "{\n",
        "\"type\" : \"",model.modelType,"\",\n",
        "\"model\" : {\n",
            "\"nodes\" : [\n",(parseVertices (graphVertices graph) node2string) ,"],\n",
            "\"edges\" : [\n", (parseEdges (graphEdges graph) node2string label2string graph.eqv), "], \n",
        "},\n",
    "\n},\n"]

-- make all models into string object
let visualize = lam models.
    let models = strJoin "" (map (lam x. if(setEqual eqchar x.modelType "dfa") then dfaVisual x 
        else if(setEqual eqchar x.modelType "digraph") then digraphVisual x
        else graphVisual x) models) in
    addTabs (strJoin "" [
    "let data = {\n",
    "\t\"models\": [\n",
    models, 
    "]\n}\n"]) 0
mexpr

let alfabeth = [0,1,2] in
let states = [1,2,3] in
let transitions = [(1,2,0),(3,1,0),(1,2,1),(2,3,1),(1,2,2),(3,1,1)] in
let startState = 1 in
let acceptStates = [1] in
let input = [0,1,0] in
let newDfa = {modelType="dfa",model=dfaConstr states transitions alfabeth startState acceptStates eqi eqi int2string int2string,input=input} in
let output = visualize [newDfa] in
-- print (addTabs (strJoin "" ["\"states\" : [\n[","" ,"\n],\n"]) 0 )
print output
