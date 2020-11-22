grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;

import edu:umn:cs:melt:exts:ableC:string:concretesyntax;
import silver:langutil;

-- e.g. "datatype Type;"
-- Forward declaration, mirroring C stucts closely
concrete productions top::StructOrUnionSpecifier_c
| 'datatype' id::Identifier_c
    { top.realTypeSpecifiers = [adtTagReferenceTypeExpr(top.givenQualifiers, id.ast)]; }

concrete productions top::StructOrEnumOrUnionKeyword_c
| 'datatype'
    { top.lookupType = \id::TypeName_t ->
        adtTagReferenceTypeExpr(nilQualifier(), fromTy(id)); }
