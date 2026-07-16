% Automatically generated knowledge base V2.
:- op(550, xfy, rdiv).
learned_proof_strategy(goal{context:[n(is_complete(A))], vars:[A, B]}, introduce(n(euclid_number(B, A)))) :-
    sequent_engine:product_of_list(A, C),
    B is C+1,
    B>1.
learned_proof_strategy(goal{context:[n(euclid_number(A, B))], vars:[A, B]}, case_split(n(prime(A)), n(composite(A)))).
