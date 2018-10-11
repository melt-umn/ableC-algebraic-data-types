grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;

imports silver:langutil only ast, pp, errors; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

{-

datatype Type;

datatype Type {
 Unit();
 Arrow(Type*, Type*);
 Var(char *);
};


-}

marking terminal Datatype_t 'datatype' lexer classes {Ckeyword};

-- e.g. "datatype Type { ... };"
-- ADTs as structurally different from C structs
concrete productions top::Declaration_c
| 'datatype' a::ADTDecl_c
  { top.ast = a.ast; }

nonterminal ADTDecl_c with ast<Decl>, location;

concrete productions top::ADTDecl_c 
| n::Identifier_c '{' cs::ConstructorList_c '}'
    { top.ast = datatypeDecl(adtDecl(n.ast, cs.ast, location=top.location)); }


nonterminal ConstructorList_c with ast<ConstructorList>;
concrete productions top::ConstructorList_c
| c::Constructor_c cl::ConstructorList_c
     { top.ast = consConstructor(c.ast, cl.ast); }
|
     { top.ast = nilConstructor(); }


nonterminal Constructor_c with ast<Constructor>, location;
concrete productions top::Constructor_c
| n::Identifier_c '(' ad::ParameterTypeList_c ')' ';'
     { top.ast = constructor(n.ast, foldParameterDecl(ad.ast), location=top.location); }
| n::Identifier_c '(' ')' ';'
     { top.ast = constructor(n.ast, nilParameters(), location=top.location); }
