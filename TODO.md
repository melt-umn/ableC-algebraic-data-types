# TODO items for this project
## Fixes / missing functionallity
* Lack of error checking for duplicate datatype decl
  * Eric, do you want to work on this?  
* datatype decls should be able to appear in type expressions, e.g.
``` typedef datatype Foo {A(int);} Foo; ```
* Things that have to do with the closure extension:
  * Bad things happen when trying to capture a local function that references something else local.  Not sure if this is easily fixable, at least add a warning for this
  * Currently you need to write an explicit function prototype when making a recursive call from within a lambda body.  Annoying, but not easily fixable on the closure side of things.  Could be fixed for strategy definitions by automatically adding a function prototype immediately before the definition.  
  * Capturing a non-constant can cause unexpected behavior, add a warning for this?  
* Finish deriving extension

## Redesign/cleanup
* Clean up names in adtDecl and add comments (what is name_tagRefId_workaround?) 
  * Eric, do you want to work on this?  I don't really know what is going on
* Handle refId defs in adtDecl/datatypeDecl in a non-interfering manner
* Use error productions in numerous places
* 'rewrite rule' is kind of an awkward prefix for strategy definitions... change this (preferably to 'strategy', but that is the type name.  Maybe rename the strategy type to Strategy?)

## Other features
* Eric, maybe fill in what we had written on your board?  
