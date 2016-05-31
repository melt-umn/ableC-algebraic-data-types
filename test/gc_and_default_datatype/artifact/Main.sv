
import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:parseAndPrint;

import edu:umn:cs:melt:exts:ableC:algDataTypes:datatype;
import edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype;

-- TODO: Update this when transparent prefixes are done
disambiguate edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:concretesyntax:datatypeKeyword:Datatype_t, edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype:datatypeKeyword:Datatype_t {
  pluck edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:concretesyntax:datatypeKeyword:Datatype_t;
}

parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:algDataTypes:datatype;
  edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype prefix edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype:datatypeKeyword:Datatype_t with 'GC:';
  edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching;
} 

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
