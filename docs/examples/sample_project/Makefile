a.out:	exprs_main.o exprs.o
	gcc exprs_main.o exprs.o

exprs.pp_out.c:	exprs.xc exprs.h ../../artifact/ableC.jar
	java -jar ../../artifact/ableC.jar exprs.xc

exprs.o:	exprs.pp_out.c
	gcc -c exprs.pp_out.c -o exprs.o

exprs_main.pp_out.c:	exprs_main.xc  exprs.h ../../artifact/ableC.jar
	java -jar ../../artifact/ableC.jar exprs_main.xc

exprs_main.o:	exprs_main.pp_out.c
	gcc -c exprs_main.pp_out.c -o exprs_main.o

clean:
	rm -f exprs.pp_out.c exprs.o exprs.gen_cpp \
              exprs_main.pp_out.c exprs_main.o exprs_main.gen_cpp \
              a.out
