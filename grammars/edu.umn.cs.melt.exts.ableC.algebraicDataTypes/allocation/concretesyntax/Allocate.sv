grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:concretesyntax;

imports silver:langutil;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype;

marking terminal Allocate_t 'allocate' lexer classes {Ckeyword};
terminal Datatype_t 'datatype';
terminal With_t 'with';

{--
concrete production allocateDecl_c
-- id is Identifer_t here to avoid follow spillage
top::Declaration_c ::= 'allocate' 'datatype' id::Identifier_t 'with' alloc::Identifier_c ';'
{ top.ast = allocateDecl(fromId(id), alloc.ast); }
action {
  local constructors::Maybe<[String]> = lookupBy(stringEq, id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(alloc.ast.name ++ "_" ++ c, location=id.location),
          constructors.fromJust),
        Identifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
--}

concrete production allocateDeclShortName_c
top::Declaration_c ::= 'allocate' 'datatype' id::Identifier_t 'with' alloc::Identifier_c ';'
{ top.ast = allocateDecl(fromId(id), alloc.ast); }
action {
  local constructors::Maybe<[String]> = lookupBy(stringEq, id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(c, location=id.location),
          constructors.fromJust),
        Identifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
