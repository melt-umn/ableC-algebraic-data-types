# TODO items for this project
## Fixes / missing functionallity
* Lack of error checking for duplicate datatype decl
  * Eric, do you want to work on this?  
* datatype decls should be able to appear in type expressions, e.g.
``` typedef datatype Foo {A(int);} Foo; ```
* I (Lucas) will add more of these when I get time...

## Redesign/cleanup
* Clean up names in adtDecl and add comments (what is name_tagRefId_workaround?) 
  * Eric, do you want to work on this?  I don't really know what is going on
* Handle refId defs in adtDecl/datatypeDecl in a non-interfering manner
* Use error productions in numerous places

## Other features
* Eric, maybe fill in what we had written on your board?  
