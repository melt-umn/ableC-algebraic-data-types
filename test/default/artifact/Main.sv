
import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:parseAndPrint;

parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:algDataTypes:datatype;
  edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching;
  --edu:umn:cs:melt:exts:ableC:algDataTypes;
} 

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
