a.out:	exprs_main.o exprs.o
	gcc exprs_main.o exprs.o

exprs.c:	exprs.xc exprs.h ../ableC.jar
	java -Xss6M -jar ../ableC.jar exprs.xc

exprs.o:	exprs.c
	gcc -c exprs.c -o exprs.o

exprs_main.c:	exprs_main.xc  exprs.h ../ableC.jar
	java -Xss6M -jar ../ableC.jar exprs_main.xc

exprs_main.o:	exprs_main.c
	gcc -c exprs_main.c -o exprs_main.o

../ableC.jar:
	cd .. && make ableC.jar

clean:
	rm -f exprs.c exprs.i exprs.o \
              exprs_main.c exprs_main.i exprs_main.o \
              a.out
