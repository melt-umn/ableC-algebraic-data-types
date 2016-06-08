grammar edu:umn:cs:melt:exts:ableC:algDataTypes:datatype;

exports edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:abstractsyntax;
exports edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:concretesyntax;
exports edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:mda_test;

-- These are essentially pure extensions to datatype, but we consider them as part of the same overall extension
-- so we include them to force a build every time
option edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype;
option edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching;

-- Rewrite isn't a pure extension to datatype so we need to include it as an option
option edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite;