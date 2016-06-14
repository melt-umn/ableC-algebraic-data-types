grammar edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite:abstractsyntax;

abstract production applyStrategy
e::Expr ::= expr::Expr strategy::Expr
{
  e.errors <-
    case expr.typerep of
    | pointerType(_, adtTagType(_, _, _)) -> []
    | errorType() -> []
    | _ -> [err(expr.location,
                "Rewritten expression does not have adt pointer type (got " ++
                showType(expr.typerep) ++ ")")]
    end;
  {-
  e.errors <-
    case strategy.typerep of
    | noncanonicalType(typedefType(_, "strategy", _)) -> []
    | errorType() -> []
    | _ -> [err(strategy.location,
                "Applied strategy does not have strategy type (got " ++
                showType(strategy.typerep) ++ ")")]
    end;-}
  
  local adtName::String =
    case expr.typerep of
         adtTagType(n, _, _) -> n
       | pointerType([], adtTagType(n, _, _)) -> n
       | _ -> error("Expected ADT type")
    end;
    
  e.typerep = expr.typerep;
  
  forwards to
    applyExpr(
      strategy,
      consExpr(
        explicitCastExpr(
          typeName(
            directTypeExpr(builtinType([], voidType())),
            pointerTypeExpr([], baseTypeExpr())),
          expr,
          location=builtIn()),
        nilExpr()),
      location=builtIn());
}