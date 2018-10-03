grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:ref:abstractsyntax;

abstract production refExpr
top::Expr ::= e::Expr  allocator::Expr
{
  local expectedAllocatorType::Type =
    functionType(
      pointerType(
        nilQualifier(),
        builtinType(nilQualifier(), voidType())),
      protoFunctionType([builtinType(nilQualifier(), unsignedType(longType()))], false),
      nilQualifier());
  local localErrors::[Message] =
    e.errors ++ allocator.errors ++
    (if !compatibleTypes(expectedAllocatorType, allocator.typerep, true, false)
     then [err(e.location, s"Allocator must have type void *(unsigned long) (got ${showType(allocator.typerep)})")]
     else []);
  
  local tempName::String = "_ref_result_" ++ toString(genInt());
  local fwrd::Expr =
    ableC_Expr {
      ({$directTypeExpr{e.typerep} *$name{tempName} =
          $Expr{allocator}(sizeof($directTypeExpr{e.typerep}));
        *$name{tempName} = $Expr{e};
        $name{tempName};})
    };
  
  forwards to mkErrorCheck(localErrors, fwrd);
}

abstract production mallocRefExpr
top::Expr ::= e::Expr
{
  top.pp = pp"&#${e.pp}";
  local localErrors::[Message] =
    e.errors ++
    (if null(lookupValue("malloc", top.env))
     then [err(top.location, "&@ operator requires definition of malloc (include <stdlib.h>?)")]
     else []);
  
  local tempName::String = "_ref_result_" ++ toString(genInt());
  local fwrd::Expr =
    refExpr(e, declRefExpr(name("malloc", location=builtin), location=builtin), location=builtin);
  
  forwards to mkErrorCheck(localErrors, fwrd);
}
