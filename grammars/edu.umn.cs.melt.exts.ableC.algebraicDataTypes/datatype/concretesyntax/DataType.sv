grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;

imports silver:langutil only ast, pp, errors; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax:showWith
  with edu:umn:cs:melt:exts:ableC:string:concretesyntax;

{-

datatype Type;

datatype Type {
 Unit();
 Arrow(Type*, Type*);
 Var(char *);
};


-}

-- Record the constructors of every ADT so that allocation declarations can add the
-- appropriate names to the parser context.
parser attribute adtConstructors::[Pair<String [String]>]
  action { adtConstructors = []; };

marking terminal Datatype_t 'datatype' lexer classes {Keyword, Global};

-- e.g. "datatype Type { ... };"
-- ADTs as structurally different from C structs
concrete production datatypeDecl_c
top::Declaration_c ::= 'datatype' n::Identifier_c '{' cs::ConstructorList_c '}'
{
  top.ast = datatypeDecl(adtDecl(nilAttribute(), n.ast, cs.ast, location=top.location));
}
action {
  context = addIdentsToScope(cs.constructorNames, Identifier_t, context);
  adtConstructors = pair(n.ast.name, map((.name), cs.constructorNames)) :: adtConstructors;
}

concrete production datatypeAttrDecl_c
top::Declaration_c ::= 'datatype' aa::Attributes_c n::Identifier_c '{' cs::ConstructorList_c '}'
{
  top.ast = datatypeDecl(adtDecl(aa.ast, n.ast, cs.ast, location=top.location));
}
action {
  context = addIdentsToScope(cs.constructorNames, Identifier_t, context);
  adtConstructors = pair(n.ast.name, map((.name), cs.constructorNames)) :: adtConstructors;
}


synthesized attribute constructorNames::[Name];

nonterminal ConstructorList_c with ast<ConstructorList>, constructorNames;
concrete productions top::ConstructorList_c
| c::Constructor_c cl::ConstructorList_c
  {
    top.ast = consConstructor(c.ast, cl.ast);
    top.constructorNames = c.constructorName :: cl.constructorNames;
  }
|
  {
    top.ast = nilConstructor();
    top.constructorNames = [];
  }


synthesized attribute constructorName::Name;

nonterminal Constructor_c with ast<Constructor>, constructorName, location;
concrete productions top::Constructor_c
| n::Identifier_c '(' ad::ParameterTypeList_c ')' ';'
  {
    top.ast = constructor(n.ast, foldParameterDecl(ad.ast), location=top.location);
    top.constructorName = n.ast;
  }
| n::Identifier_c '(' ')' ';'
  {
    top.ast = constructor(n.ast, nilParameters(), location=top.location);
    top.constructorName = n.ast;
  }
