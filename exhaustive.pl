
:- use_module(library(lists)).
:- use_module(library(clpfd)).
:- consult('core').
:- ['example'].
%:-['infra','app'].

%-----------------------------------------------------------------------------------------------

% Request format: request(SortType, AppId, AppVersion, PreferredMELVersion, MaxCost, UserID). 
request((0,highest), app1, adaptive, full, 999).
% request((0,highest), app2, adaptive, full, 999).
% request((0,highest), app3, adaptive, full, 999).
request((0,highest), arApp, adaptive, full, 110).

%-----------------------------------------------------------------------------------------------

best(BestPlacements,BestProfit) :-
    % prende tutte le richieste da gestire
    findall((SortType, AppId, AppVersion, PreferredMELVersion, MaxCost), request(SortType, AppId, AppVersion, PreferredMELVersion, MaxCost), As),
    % trova tutti i piazzamenti possibili per tutte le applicazioni, con il relativo profitto totale
    findall(sol(Profit,Placements),  ( place([], As, Placements, []), profit(Placements, Profit) ), Solutions), 
    % ordina le soluzioni in ordine decrescente di profitto e prendi la (prima) soluzione ottima
    sort(Solutions, Tmp), reverse(Tmp, [sol(BestProfit,BestPlacements)|_]). 

% calcola il profitto totale dei piazzamenti
profit([s(_,ProfitP)|Ps], Profit) :-
    profit(Ps,TmpProfit),
    Profit is ProfitP + TmpProfit.
profit([], 0).

% OldHw format = AllocatedHW format: [(Node, HwUsed)].
place(Placements, [A|As], NewPlacements, OldHw) :-
    % piazza l'applicazione A in uno dei modi possibili tenendo conto dell'hardware utilizzato dai piazzamenti precedentemente effettuati presenti in "Placements"
    place_app(Placements, A, TempPlacements, OldHw, NewHw),
    place(TempPlacements, As, NewPlacements, NewHw). % ricorre sulle altre applicazioni
place(Placements, [_|As], NewPlacements, OldHw) :-
    % non piazzare l'applicazione A, ricorre quindi sulle altre applicazioni
    place(Placements, As, NewPlacements, OldHw). 
place(Placements, [], Placements, _). % caso base: non ci sono altre applicazioni da piazzare

place_app(Placements, (_, AppId, AppVersion, _, MaxCost), [s(Placement, PlacementProfit)|Placements], OldHw, NewHw) :-
    % ottiene un singolo piazzamento ammissibile di A, tenendo conto delle risorse Hw già allocate, presenti in OldHw
    % restuiendomi così il Placement che concatena insieme agli altri per la creazione della lista soluzione, il profitto e l'hw allocato del placement 
    placement(AppId, AppVersion, MaxCost, Placement, PlacementProfit, AllocatedHW, OldHw),
    % aggiorna le risorse Hw allocate
    merge(AllocatedHW, OldHw, NewHw).

merge([(N,H)|As], OldHw, NewHw) :-
    member((N,H1), OldHw),
    NewH is H1+H,
    select((N,H1), OldHw, (N,NewH), TmpHw),
    merge(As,TmpHw, NewHw).
merge([(N,H)|As], OldHw, NewHw) :-
    \+ member((N,H), OldHw),
    merge(As, [(N,H)|OldHw], NewHw).
merge([],H,H).

%-----------------------------------------------------------------------------------------------

go(SortType, AppName, AppVersion, PreferredMelVersion, MaxCost, VC, C, Best, Time) :-
statistics(cputime, Start),
goForBest(SortType, AppName, AppVersion, PreferredMelVersion, MaxCost, BestPlacement),
statistics(cputime, Stop), Time is Stop - Start,
nth0(1,BestPlacement,VC), nth0(2,BestPlacement,C), nth0(3,BestPlacement,Best).


% goForBest((0,highest), arApp, adaptive, full, 110, BestPlacement, PlacementsHw, []).
% goForBest((0,highest), testApp, adaptive, full, 999, BestPlacement, PlacementsHw, []).
goForBest(SortType, AppName, AppVersion, PreferredMelVersion, MaxCost, BestPlacement, PlacementsHw, OldHw) :-
    findall((Placement, PlacementProfit, AllocatedHW), placement(AppName, AppVersion, MaxCost, Placement, PlacementProfit, AllocatedHW, OldHw), PlacementsHw),
    maplist(extractPlacements, PlacementsHw, Placements),
    evalPlacements(AppName, AppVersion, PreferredMelVersion, Placements, EvaluatedPlacements),
    best(SortType,EvaluatedPlacements,BestPlacement).

extractPlacements((Placement, PlacementProfit, _), (Placement, PlacementProfit)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% placement(arApp, adaptive, 110, Placement, PlacementProfit, AllocatedHW, []).
% placement(testApp, adaptive, 999, Placement, PlacementProfit, AllocatedHW, []).
placement(AppName, AppVersion, MaxCost, Placement, TotCost, AllocatedHW, OldHw) :-
    application((AppName, AppVersion), MELs),
    melPlacementOK(MELs, Placement, [], 0, TotCost, MaxCost, AllocatedHW, OldHw),
    findall(mel2mel(M1,M2,Latency), mel2mel_in_placement(M1,M2,Latency,Placement), FlowConstraints),
    flowsOK(FlowConstraints, Placement).

% evalPacements ranks a list of placements
evalPlacements(_, _, _, [], []).
evalPlacements(AppName, AppVersion, PreferredMelVersion, [(Placement,Cost)], [[_, VersionCompliance, Cost, Placement]]):-
    application((AppName, AppVersion), Mels), length(Mels, NMels), 
    findall(S, member(on(S, PreferredMelVersion, _), Placement), Ls), length(Ls, NPreferredVersionMels),
    VersionCompliance is div(100*NPreferredVersionMels,NMels).
    evalPlacements(AppName, AppVersion, PreferredMelVersion, Placements, EvaluatedPlacements):-
    length(Placements, L), L>1, 
    application((AppName, AppVersion), Mels), length(Mels, NMels),
    maxANDmin(Placements, MinAllCosts, MaxAllCosts),
    findall([Formula, VersionCompliance, Cost, Placement], 
            (member((Placement, Cost), Placements), 
            findall(S, member(on(S, PreferredMelVersion, _), Placement), Ls), length(Ls, NPreferredVersionMels),
            VersionCompliance is div(100*NPreferredVersionMels,NMels),
            ( (MaxAllCosts-MinAllCosts > 0, NormalizedCost is div((100*(MaxAllCosts - Cost)),(MaxAllCosts - MinAllCosts))); NormalizedCost is 100 ),
            Formula is VersionCompliance + NormalizedCost),
            EvaluatedPlacements).

maxANDmin([(_, Cost)|Rest], MinCost, MaxCost) :- 
    length(Rest,L),L>0,
    maxANDmin(Rest, RestMinCost, RestMaxCost),
    ((Cost =< RestMinCost, MinCost is Cost); (Cost > RestMinCost, MinCost is RestMinCost)),
    ((Cost >= RestMaxCost, MaxCost is Cost); (Cost < RestMaxCost, MaxCost is RestMaxCost)).
    maxANDmin([(_, Cost)], Cost, Cost). 

best(_, [], none).
best(_, [P], P).
best(ST, EPs, BestP) :- length(EPs, L), L>1, best2(ST, EPs, BestP).
best2(_, [E], E).
best2(ST, [E|Es], BestP) :- length(Es, L), L>0, best2(ST, Es, BestOfEs), choose(ST, E, BestOfEs, BestP).
choose((S,highest), E, BestOfEs, E) :- nth0(S, E, V), nth0(S, BestOfEs, W), V > W.
choose((S,highest), E, BestOfEs, BestOfEs) :- nth0(S, E, V), nth0(S, BestOfEs, W), V =<  W.
choose((S,lowest), E, BestOfEs, E) :- nth0(S, E, V), nth0(S, BestOfEs, W), V =< W.
choose((S,lowest), E, BestOfEs, BestOfEs) :- nth0(S, E, V), nth0(S, BestOfEs, W), V > W.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Returns the best and worst placement (BestP, WorstP) out of all placements, with statistics on CPU time.
% It also returns the best and worst ranking, version compliance and cost.
% Given an input placement HeuP, it evaluates the same also for it.
% Sample query:
% goForAll(arApp, adaptive, full, 110, HeuP, HeuF, BestP, BestF, BestVC, BestC, WorstP, WorstF, WorstVC, WorstC, Time).
goForAll(AppName, AppVersion, PreferredMelVersion, MaxCost, HeuP, HeuF, BestP, BestF, BestVC, BestC, WorstP, WorstF, WorstVC, WorstC, Time) :-
    statistics(cputime, Start),
findall((Placement, PlacementProfit), placement(AppName, AppVersion, MaxCost, Placement, PlacementProfit), Placements),
evalPlacements(AppName, AppVersion, PreferredMelVersion, Placements, EvaluatedPlacements),
sort(1,@>=,EvaluatedPlacements, SPlacements),
SPlacements=[Best|_],
    statistics(cputime, Stop),
    Time is Stop - Start,
nth0(0,Best,BestF),nth0(1,Best,BestVC), nth0(2,Best,BestC), nth0(3,Best,BestP),
last(SPlacements, Worst),
nth0(0,Worst,WorstF),nth0(1,Worst,WorstVC), nth0(2,Worst,WorstC), nth0(3,Worst,WorstP),
findHeuristicF(HeuP, HeuF, SPlacements).

findHeuristicF(HeuP, HeuF, SPlacements):-
member([PF,_,_, P], SPlacements),
sort(HeuP,HeuPSorted), sort(P,PSorted),
PSorted = HeuPSorted,
( (ground(PF), HeuF is PF) ; HeuF = 200).

myPrint([]).
myPrint([X|Xs]):-write_ln(X),myPrint(Xs).
