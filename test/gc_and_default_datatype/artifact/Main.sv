
import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:parseAndPrint;

-- TODO: Update this when transparent prefixes are done
parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:algDataTypes:datatype;
  edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype prefix with 'GC:';
  edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching;
  
  prefer edu:umn:cs:melt:exts:ableC:algDataTypes:datatype:concretesyntax:datatypeKeyword:Datatype_t
    over edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype:datatypeKeyword:Datatype_t;
}

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
