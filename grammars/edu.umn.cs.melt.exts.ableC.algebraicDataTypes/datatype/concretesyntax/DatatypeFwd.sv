grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;

-- trigger the test
--import edu:umn:cs:melt:exts:ableC:algebraicDataTypes:src:datatype:mda_test;

-- e.g. "datatype Type;"
-- Forward declaration, mirroring C stucts closely
concrete productions s::StructOrUnionSpecifier_c
| 'datatype' id::Identifier_t
    { s.realTypeSpecifiers = 
        [ adtTagReferenceTypeExpr( s.givenQualifiers, 
             name(id.lexeme, location=s.location) ) ];
    }

