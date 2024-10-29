a.out:	exprs_main.o exprs.o
	gcc exprs_main.o exprs.o

exprs.c:	exprs.xc exprs.xh compiler.jar
	java -Xss6M -jar compiler.jar exprs.xc

exprs.o:	exprs.c
	gcc -c exprs.c -o exprs.o

exprs_main.c:	exprs_main.xc  exprs.xh compiler.jar
	java -Xss6M -jar compiler.jar exprs_main.xc

exprs_main.o:	exprs_main.c
	gcc -c exprs_main.c -o exprs_main.o

compiler.jar:
	silver -I ../../../../ableC/ableC.jar -I ../../ableC-algebraic-data-types.jar -I ../../../ableC-string/ableC-string.jar -I ../../../ableC-constructor/ableC-constructor.jar -I ../../../ableC-allocation/ableC-allocation.jar -o compiler.jar artifact

clean:
	rm -f compiler.jar exprs.c exprs.i exprs.o \
              exprs_main.c exprs_main.i exprs_main.o \
              a.out
