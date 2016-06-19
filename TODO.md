# TODO items for this project
## Fixes / missing functionallity
* Numerous places where we assume that the datatype is typedefed to the same name as the datatype, needed due to bugs with the struct refId being different in different locations... I don't know why
  * Eric, do you want to work on this?  
* Lack of error checking for duplicate datatype decl
  * Eric, do you want to work on this?  
* datatype decls should be able to appear in type expressions, e.g.
``` typedef datatype Foo {A(int);} Foo; ```
* Things that have to do with the closure extension:
  * Currently you need to write an explicit function prototype when making a recursive call from within a lambda body.  Annoying, but not easily fixable on the closure side of things.  Fixed for strategy definitions by automatically adding a function prototype immediately before the definition.  
  * Capturing a non-constant can cause unexpected behavior, add a warning for this?  
* Finish deriving extension

## Redesign/cleanup
* Clean up names in adtDecl and add comments (what is name_tagRefId_workaround?) 
  * Eric, do you want to work on this?  I don't really know what is going on
* Handle refId defs in adtDecl/datatypeDecl in a non-interfering manner
* Use error productions in numerous places

## Other features
* Get matching over vectors working
* Overload operators for strategy combinators
* Eric, maybe fill in what we had written on your board?  
