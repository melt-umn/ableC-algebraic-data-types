grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:concretesyntax;

imports silver:langutil;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:host;
imports edu:umn:cs:melt:ableC:concretesyntax;

imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:abstractsyntax;
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype;

marking terminal Allocate_t 'allocate' lexer classes {Keyword, Global};
terminal Datatype_t 'datatype' lexer classes {Keyword};
terminal With_t 'with' lexer classes {Keyword};
terminal Prefix_t 'prefix' lexer classes {Keyword};

concrete production allocateDecl_c
-- id is Identifer_t here to avoid follow spillage
top::Declaration_c ::= 'allocate' 'datatype' id::Identifier_t 'with' alloc::Identifier_c ';'
{ top.ast = allocateDecl(fromId(id), alloc.ast, nothing()); }
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

concrete production allocateDeclPrefix_c
top::Declaration_c ::= 'allocate' 'datatype' id::Identifier_t 'with' alloc::Identifier_t 'prefix' pfx::Identifier_c ';'
{ top.ast = allocateDecl(fromId(id), fromId(alloc), just(pfx.ast)); }
action {
  local constructors::Maybe<[String]> = lookupBy(stringEq, id.lexeme, adtConstructors);
  if (constructors.isJust)
    context =
      addIdentsToScope(
        map(
          \ c::String -> name(pfx.ast.name ++ "_" ++ c, location=id.location),
          constructors.fromJust),
        Identifier_t,
        context);
  -- If the datatype hasn't been declared, then do nothing
}
