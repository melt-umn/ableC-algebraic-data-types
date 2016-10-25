
import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:parseAndPrint;

parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:string;
  edu:umn:cs:melt:exts:ableC:algDataTypes:datatype;
  --edu:umn:cs:melt:exts:ableC:algDataTypes:gcdatatype prefix "GC";
  edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching;
  edu:umn:cs:melt:exts:ableC:algDataTypes:deriving:eq;
  edu:umn:cs:melt:exts:ableC:algDataTypes:deriving:show;
  --edu:umn:cs:melt:exts:ableC:algDataTypes:deriving:read;
  --edu:umn:cs:melt:exts:ableC:algDataTypes:deriving:free;
  --edu:umn:cs:melt:exts:ableC:algDataTypes:deriving:copy;
} 

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
