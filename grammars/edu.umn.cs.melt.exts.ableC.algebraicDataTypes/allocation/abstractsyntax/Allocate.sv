grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:abstractsyntax;

abstract production allocateDecl
top::Decl ::= id::Name  allocator::Name
{
  top.pp = pp"allocate datatype ${id.pp} with ${allocator.pp});";
  
  local expectedAllocatorType::Type =
    functionType(
      pointerType(
        nilQualifier(),
        builtinType(nilQualifier(), voidType())),
      protoFunctionType([builtinType(nilQualifier(), unsignedType(longType()))], false),
      nilQualifier());
  local adtLookupErrors::[Message] =
    case lookupTag(id.name, top.env) of
    | adtRefIdTagItem(refId) :: _ ->
      case lookupRefId(refId, top.env) of
      | adtRefIdItem(_) :: _ -> []
      | _ -> [err(id.location, "datatype " ++ id.name ++ " does not have a definition")]
      end
    | _ -> [err(id.location, "Tag " ++ id.name ++ " is not a datatype")]
    end;
  local localErrors::[Message] =
    adtLookupErrors ++ allocator.valueLookupCheck ++
    (if !compatibleTypes(expectedAllocatorType, allocator.valueItem.typerep, true, false)
     then [err(allocator.location, s"Allocator must have type void *(unsigned long) (got ${showType(allocator.valueItem.typerep)})")]
     else []);
  
  local d::ADTDecl =
    case id.tagItem of
    | adtRefIdTagItem(refId) ->
      case lookupRefId(refId, top.env) of
      | adtRefIdItem(d) :: _ -> d
      end
    end;
  d.env = top.env;
  d.returnType = top.returnType;
  d.adtGivenName = d.name;
  d.allocatorName = allocator;
  
  forwards to
    if !null(adtLookupErrors)
    then warnDecl(localErrors)
    else if !null(localErrors)
    then decls(foldDecl([warnDecl(localErrors), defsDecl(d.allocatorErrorDefs)]))
    else defsDecl(d.allocatorDefs);
}

autocopy attribute allocatorName::Name occurs on ADTDecl, ConstructorList, Constructor;
synthesized attribute allocatorDefs::[Def] occurs on ADTDecl, ConstructorList, Constructor;
synthesized attribute allocatorErrorDefs::[Def] occurs on ADTDecl, ConstructorList, Constructor;

aspect production adtDecl
top::ADTDecl ::= n::Name cs::ConstructorList
{
  top.allocatorDefs = cs.allocatorDefs;
  top.allocatorErrorDefs = cs.allocatorErrorDefs;
}

aspect production consConstructor
top::ConstructorList ::= c::Constructor cl::ConstructorList
{
  top.allocatorDefs = c.allocatorDefs ++ cl.allocatorDefs;
  top.allocatorErrorDefs = c.allocatorErrorDefs ++ cl.allocatorErrorDefs;
}

aspect production nilConstructor
top::ConstructorList ::=
{
  top.allocatorDefs = [];
  top.allocatorErrorDefs = [];
}

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  local allocateConstructorName::String = top.allocatorName.name ++ "_" ++ n.name;
  top.allocatorDefs =
    [valueDef(
       allocateConstructorName,
       allocateConstructorValueItem(
         name(top.adtGivenName, location=builtin),
         top.allocatorName, n, ps.typereps))];
  top.allocatorErrorDefs = [valueDef(allocateConstructorName, errorValueItem())];
}

abstract production allocateConstructorValueItem
top::ValueItem ::= adtName::Name allocatorName::Name constructorName::Name paramTypes::[Type]
{
  top.pp = pp"allocateConstructorValueItem(${adtName.pp}, ${allocatorName.pp}, ${constructorName.pp})";
  top.typerep = errorType();
  top.sourceLocation = allocatorName.location;
  top.directRefHandler =
    \ n::Name l::Location ->
      errorExpr([err(l, s"Allocate constructor ${n.name} cannot be referenced, only called directly")], location=builtin);
  top.directCallHandler =
    allocateConstructorCallExpr(adtName, allocatorName, constructorName, paramTypes, _, _, location=_);
}

abstract production allocateConstructorCallExpr
top::Expr ::= adtName::Name allocatorName::Name constructorName::Name paramTypes::[Type] n::Name args::Exprs
{
  top.pp = parens(ppConcat([n.pp, parens(ppImplode(cat(comma(), space()), args.pps))]));
  local localErrors::[Message] = args.errors ++ args.argumentErrors;
  
  args.expectedTypes = paramTypes;
  args.argumentPosition = 1;
  args.callExpr = decorate declRefExpr(n, location=n.location) with {env = top.env; returnType = top.returnType;};
  args.callVariadic = false;
  
  local resultTypeExpr::BaseTypeExpr = adtTagReferenceTypeExpr(nilQualifier(), adtName);
  local fwrd::Expr =
    ableC_Expr {
      ({$BaseTypeExpr{resultTypeExpr} *result = $Name{allocatorName}(sizeof($BaseTypeExpr{resultTypeExpr}));
        *result = $Name{constructorName}($Exprs{args});
        result;})
    };
  forwards to mkErrorCheck(localErrors, fwrd);
}
