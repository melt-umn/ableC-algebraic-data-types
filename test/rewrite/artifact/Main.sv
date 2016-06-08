
import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:parseAndPrint;

parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:gc;
  edu:umn:cs:melt:exts:ableC:string;
  edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype;
  edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching;
  edu:umn:cs:melt:exts:ableC:algDataTypes:rewrite;
} 

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
