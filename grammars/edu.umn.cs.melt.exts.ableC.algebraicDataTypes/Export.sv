grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes;

exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype;
exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching;
exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation;

exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction
   with edu:umn:cs:melt:ableC:silverconstruction:concretesyntax:antiquotation;
-- Include this in the main extension artifact, for now.
-- In theory, we could build a seperate artifact containing the Silver ableC construction utilties.
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction only ;
