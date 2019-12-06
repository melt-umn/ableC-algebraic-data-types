grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;

-- e.g. "datatype Type;"
-- Forward declaration, mirroring C stucts closely
concrete productions top::StructOrUnionSpecifier_c
| 'datatype' id::Identifier_c
    { top.realTypeSpecifiers = [adtTagReferenceTypeExpr(top.givenQualifiers, id.ast)]; }

