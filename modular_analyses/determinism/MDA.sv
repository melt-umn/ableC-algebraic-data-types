grammar determinism;

{- This Silver specification does not generate a useful working 
   compiler, it only serves as a grammar for running the modular
   determinism analysis.
 -}

import edu:umn:cs:melt:ableC:host;
import edu:umn:cs:melt:ableC:concretesyntax;

copper_mda testDatatype(ablecParser) {
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;
}

parser ableCWithStrings :: Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:string:concretesyntax;
}

copper_mda testDatatypeWithString(ableCWithStrings) {
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;
}

copper_mda testPatternMatching(ablecParser) {
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;
}

copper_mda testAllocation(ablecParser) {
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:concretesyntax;
}

parser ableCWithDatatypes :: Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:concretesyntax;
}

copper_mda testSilverConstruction(ableCWithDatatypes) {
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:silverconstruction;
  edu:umn:cs:melt:exts:silver:ableC:concretesyntax:antiquotation;
  silver:compiler:host:core;
  silver:compiler:extension:patternmatching;
  silver:compiler:extension:list;
  silver:compiler:modification:let_fix;
}
