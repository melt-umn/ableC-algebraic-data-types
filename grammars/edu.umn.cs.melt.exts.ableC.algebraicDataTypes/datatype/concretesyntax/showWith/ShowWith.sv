grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax:showWith;

import edu:umn:cs:melt:ableC:abstractsyntax:construction;
import edu:umn:cs:melt:ableC:abstractsyntax:host;
import edu:umn:cs:melt:ableC:concretesyntax;
import edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;
import edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;
import edu:umn:cs:melt:exts:ableC:string:concretesyntax;
import silver:langutil;

concrete productions top::TagKeyword_c
| 'datatype'
    { top.ast = adtTagReferenceTypeExpr(nilQualifier(), _); }
