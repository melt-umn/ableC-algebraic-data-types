grammar edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax;

imports silver:langutil; 
imports silver:langutil:pp;

imports edu:umn:cs:melt:ableC:abstractsyntax:host with fieldNames as hostFieldNames;
imports edu:umn:cs:melt:ableC:abstractsyntax:construction;
imports edu:umn:cs:melt:ableC:abstractsyntax:env;

exports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:string
  with edu:umn:cs:melt:exts:ableC:string:abstractsyntax;
-- Unconditionally include this in the adt extension artifact, for now.
-- In theory, we could put this in a seperate artifact to allow
-- using the datatype extension without depending on the string extension.
imports edu:umn:cs:melt:exts:ableC:algebraicDataTypes:datatype:abstractsyntax:string only ;
