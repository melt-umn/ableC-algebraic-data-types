grammar edu:umn:cs:melt:exts:ableC:algDataTypes:artifacts:with_all;

{- This Silver specification does litte more than list the desired
   extensions, albeit in a somewhat stylized way.

   Files like this can easily be generated automatically from a simple
   list of the desired extensions.
 -}

import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:parseAndPrint;

-- TODO: Update this when transparent prefixes are done
parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:algDataTypes:datatype;
  edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype prefix with 'GC:';
  
  prefer edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:concretesyntax:datatypeKeyword:Datatype_t
    over edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype:datatypeKeyword:Datatype_t;
    
  edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching;
  edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite;
}

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
