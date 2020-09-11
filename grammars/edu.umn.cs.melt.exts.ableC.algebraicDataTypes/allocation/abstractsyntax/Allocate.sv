grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:abstractsyntax;

abstract production allocateDecl
top::Decl ::= id::Name  allocator::Name
{
  top.pp = pp"allocate datatype ${id.pp} with ${allocator.pp};";
  
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
  
  local adtLookup::Decorated ADTDecl =
    case id.tagItem of
    | adtRefIdTagItem(refId) ->
      case lookupRefId(refId, top.env) of
      | adtRefIdItem(d) :: _ -> d
      end
    end;
  -- Re-decorate the found ADT decl, also supplying the allocator name
  local d::ADTDecl = new(adtLookup);
  d.env = top.env; -- TODO: Not exactly correct, but the decl needs to see the tag to avoid re-generating the refId
  d.returnType = adtLookup.returnType;
  d.isTopLevel = adtLookup.isTopLevel;
  d.givenRefId = adtLookup.givenRefId;
  d.adtGivenName = adtLookup.adtGivenName;
  d.allocatorName = allocator;
  
  forwards to
    if !null(adtLookupErrors)
    then warnDecl(localErrors)
    else if !null(localErrors)
    then decls(foldDecl([warnDecl(localErrors), defsDecl(d.allocatorErrorDefs)]))
    else defsDecl(d.allocatorDefs);
}

autocopy attribute allocatorName::Name occurs on ADTDecl, ConstructorList, Constructor;
monoid attribute allocatorDefs::[Def] with [], ++;
monoid attribute allocatorErrorDefs::[Def] with [], ++;
attribute allocatorDefs, allocatorErrorDefs occurs on ADTDecl, ConstructorList, Constructor;

flowtype allocatorDefs {decorate, allocatorName} on ADTDecl, ConstructorList, Constructor;
flowtype allocatorErrorDefs {decorate, allocatorName} on ADTDecl, ConstructorList, Constructor;

propagate allocatorDefs, allocatorErrorDefs on ADTDecl, ConstructorList;

aspect production constructor
top::Constructor ::= n::Name ps::Parameters
{
  production allocateConstructorName::String = top.allocatorName.name ++ "_" ++ n.name;
  top.allocatorDefs :=
    [valueDef(
       allocateConstructorName,
       allocateConstructorValueItem(
         name(top.adtGivenName, location=builtin),
         top.allocatorName, n, ps.typereps))];
  top.allocatorErrorDefs := [valueDef(allocateConstructorName, errorValueItem())];
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
  local resultName::String = "result_" ++ toString(genInt());
  local fwrd::Expr =
    ableC_Expr {
      ({$BaseTypeExpr{resultTypeExpr} *$name{resultName} = $Name{allocatorName}(sizeof($BaseTypeExpr{resultTypeExpr}));
        *$name{resultName} = $Name{constructorName}($Exprs{args});
        $name{resultName};})
    };
  forwards to mkErrorCheck(localErrors, fwrd);
}
