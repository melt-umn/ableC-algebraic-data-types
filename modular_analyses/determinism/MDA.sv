grammar determinism;

{- This Silver specification does not generate a useful working 
   compiler, it only serves as a grammar for running the modular
   determinism analysis.
 -}

import edu:umn:cs:melt:ableC:host;

copper_mda testDatatype(ablecParser) {
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:concretesyntax;
}

copper_mda testPatternMatching(ablecParser) {
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;
}

copper_mda testAllocation(ablecParser) {
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:allocation:concretesyntax;
}
