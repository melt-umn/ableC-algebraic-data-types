grammar edu:umn:cs:melt:exts:ableC:algDataTypes:associative:concretesyntax;

imports silver:langutil only ast; --, pp, errors; --, err, wrn;
--imports silver:langutil:pp with implode as ppImplode ;

imports edu:umn:cs:melt:ableC:concretesyntax;
imports edu:umn:cs:melt:ableC:abstractsyntax;
--imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
--imports edu:umn:cs:melt:ableC:abstractsyntax:env;

--imports edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:abstractsyntax as abs;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:patternmatching:concretesyntax:patterns;

imports edu:umn:cs:melt:exts:ableC:algDataTypes:associative:abstractsyntax;

marking terminal LB_t '[' ;
terminal RB_t ']';
terminal Dots_t /\.\.+/;

concrete production arrayPattern_c
p::Pattern ::= LB_t items::ItemList_c RB_t len::PrimaryExpr_c
{ p.ast = arrayPattern(items.ast, len.ast, location=p.location); }

concrete production vecPattern_c
p::Pattern ::= LB_t items::ItemList_c RB_t
{ p.ast = vecPattern(items.ast, location=p.location); }

nonterminal ItemList_c with ast<ItemList>, location;

concrete productions is::ItemList_c
| h::Item_c ',' t::ItemList_c
  { is.ast = consItems(h.ast, t.ast, location=is.location); }

| i::Item_c ',' d::Dots_t
  { is.ast = consItems( 
               i.ast, 
               oneItem( trailingDots(location=d.location), location=i.location),
               location=is.location); }

nonterminal Item_c with ast<Item>, location;

concrete productions i::Item_c
| Dots_t ',' p::Pattern
  { i.ast = searchItem(p.ast, location=i.location); }

| p::Pattern
  { i.ast = hereItem(p.ast, location=i.location); }
