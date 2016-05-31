grammar edu:umn:cs:melt:exts:ableC:algDataTypes:gc;

imports silver:langutil only ast, pp, errors; 
imports silver:langutil:pp with implode as ppImplode ;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:abstractsyntax;

-- trigger the test
import edu:umn:cs:melt:exts:ableC:algDataTypes:gc:mda_test;

{-

datatype Type;

datatype Type {
 Unit();
 Arrow(Type*, Type*);
 Var(char *);
};


-}

-- e.g. "datatype Type { ... };"
-- ADTs as structurally different from C structs
concrete productions top::Declaration_c
| 'datatype' a::ADTDecl_c
  { top.ast = a.ast; }

nonterminal ADTDecl_c with ast<Decl>, location ;

concrete productions top::ADTDecl_c 
| n::Identifier_t '{' c::ConstructorList_c '}'
    { top.ast = datatypeDecl( adtDecl(fromId(n), c.ast) ); }


nonterminal ConstructorList_c with ast<ConstructorList>;
concrete productions top::ConstructorList_c
| c::Constructor_c cl::ConstructorList_c
     { top.ast = consConstructor(c.ast, cl.ast); }
|
     { top.ast = nilConstructor(); }


nonterminal Constructor_c with ast<Constructor>;
concrete productions top::Constructor_c
| n::Identifier_t '(' ad::TypeNameList_c ')' ';'
     { top.ast = gcConstructor(n.lexeme, ad.ast); }


nonterminal TypeNameList_c with ast<TypeNames>;
concrete productions top::TypeNameList_c
| tn::TypeName_c tl::TailTypeNameList_c
     { top.ast = consTypeName(tn.ast, tl.ast); }
|
     { top.ast = nilTypeName() ; }

nonterminal TailTypeNameList_c with ast<TypeNames>;
concrete productions top::TailTypeNameList_c
| ',' tn::TypeName_c tl::TailTypeNameList_c
     { top.ast = consTypeName(tn.ast, tl.ast); }
|
     { top.ast = nilTypeName() ; }


abstract production gcConstructor
top::Constructor ::= n::String tms::TypeNames
{
  forwards to allocConstructor(n, tms, \ty::String -> txtExpr("(" ++ ty ++ " *) gcMalloc (sizeof(" ++ ty ++ "))", location=builtIn()));
}