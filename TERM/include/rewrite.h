#include <gc.h>
#include <closure.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <stdarg.h>
//#include <pthread.h>

#ifndef __REWRITE_H
#define __REWRITE_H

//#define PRINT_STRATEGY_CALLS // Uncomment to print all strategy calls

// TODO: This may need to be re-thought since we now have vectors as children
#define MAX_FIELDS 100

typedef closure((void*) -> void*) strategy;

typedef void *(*ConstructFun)(void**, void*); // Takes pointer to storage and old object, returns new object
typedef int (*DestructFun)(void**, void*); // Takes pointer to storage and object, returns size
typedef closure((strategy) -> strategy) RecFun;

// Need a dummy datatype to force generation of the _GenericDatatype struct
typedef datatype _dummy _dummy;
datatype _dummy {};

/* Basic strategy combinators */
static strategy sequence(strategy s1, strategy s2) {
  return lambda (void *x) . (({
#ifdef PRINT_STRATEGY_CALLS
        printf("sequence\n");
#endif
        void *res = s1(x);
        res == NULL? NULL : s2(res);}));
}

static strategy choice(strategy s1, strategy s2) {
  return lambda (void *x) . (({
#ifdef PRINT_STRATEGY_CALLS
        printf("choice\n");
#endif
        void *res = s1(x);
        res == NULL? s2(x) : res;}));
}
/*
static strategy nchoice(strategy s1, strategy s2) {
  return lambda (void *x) . (({
#ifdef PRINT_STRATEGY_CALLS
        printf("nchoice\n");
#endif
        void *fn(strategy s) {
          return NULL;
        }
        void *res = s1(x);
        res == NULL? s2(x) : res;}));
}
*/
static strategy all(strategy s) {
  return lambda (void *x) . (({
#ifdef PRINT_STRATEGY_CALLS
        printf("all\n");
#endif
        // Just using the same array for old & new structures, since the old ones aren't needed.  
        void *contents[MAX_FIELDS];
        int size = (((struct _GenericDatatype *) x)->destructFun)(contents, x);
        for (int i = 0; i < size; i++) {
          contents[i] = s(contents[i]);
          if (contents[i] == NULL)
            return NULL;
        }
        (((struct _GenericDatatype *) x)->constructFun)(contents, x);}));
}

static strategy one(strategy s) {
  return lambda (void *x) . (({
#ifdef PRINT_STRATEGY_CALLS
        printf("one\n");
#endif
        void *contents[MAX_FIELDS];
        int size = (((struct _GenericDatatype *) x)->destructFun)(contents, x);
        for (int i = 0; i < size; i++) {
          void *res = s(contents[i]);
          if (res != NULL) {
            contents[i] = res;
            return (((struct _GenericDatatype *) x)->constructFun)(contents, x);
          }
        }
        NULL;}));
}

static strategy fail() {
#ifdef PRINT_STRATEGY_CALLS
  return lambda (void *x) . (({printf("fail\n"); NULL;}));
#else
  return lambda (void *x) . (NULL);
#endif
}

static strategy identity() {
#ifdef PRINT_STRATEGY_CALLS
  return lambda (void *x) . (({printf("identity\n"); x;}));
#else
  return lambda (void *x) . (x);
#endif
}

/* Should only be called internally */
// Wraps a strategy with a name, useful for debugging with PRINT_STRATEGY_CALLS
static strategy _rule(strategy s, const char *name) {
#ifdef PRINT_STRATEGY_CALLS
  return lambda (void *x) . (({printf("rule %s\n", name); s(x);}));
#else
  return s;
#endif
}

static strategy _rec(RecFun f);
static strategy _rec(RecFun f) {
#ifdef PRINT_STRATEGY_CALLS
  return lambda (void *x) . (({printf("_rec\n"); f(_rec(f))(x);}));
#else
  return lambda (void *x) . (f(_rec(f))(x));
#endif
}

/* Util strategy combinators */
static strategy try(strategy);
static strategy repeat(strategy);
static strategy bottomUp(strategy);
static strategy topDown(strategy);
static strategy onceBottomUp(strategy);
static strategy onceTopDown(strategy);
static strategy innermost(strategy);
static strategy outermost(strategy);

newstrategy try(strategy s) extends (identity()) {
  s;
}

newstrategy repeat(strategy s) {
  rec(self) {
    try {
      sequence {s; self;}
    }
  }
}

newstrategy bottomUp(strategy s) {
  rec(self) {
    sequence {
      all {self;}
      s;
    }
  }
}

newstrategy topDown(strategy s) {
  rec(self) {
    sequence {
      s;
      all {self;}
    }
  }
}

newstrategy onceBottomUp(strategy s) {
  rec(self) {
    choice {
      one {self;}
      s;
    }
  }
}

newstrategy onceTopDown(strategy s) {
  rec(self) {
    choice {
      s;
      one {self;}
    }
  }
}

newstrategy innermost(strategy s) {
  rec(self) {
    sequence(all(self), try(sequence(s, self)));
  }
}

newstrategy outermost(strategy s) {
  rec(self) {
    sequence(try(sequence(s, self)), all(self));
  }
}

// Vararg versions of sequence and choice
static strategy vsequence(int count, ...) {
  va_list ap;
  va_start(ap, count);

  if (count == 0)
    return identity();

  strategy result = (strategy)va_arg(ap, strategy);
  for (int i = 0; i < count - 1; i++)
    result = sequence(result, (strategy)va_arg(ap, strategy));
  
  va_end(ap);
  return result;
}

static strategy vchoice(int count, ...) {
  va_list ap;
  va_start(ap, count);

  if (count == 0)
    return fail();
  
  strategy result = (strategy)va_arg(ap, strategy);
  for (int i = 0; i < count - 1; i++)
    result = choice(result, (strategy)va_arg(ap, strategy));
  
  va_end(ap);
  return result;
}

#define seq(...) vsequence(_countArgs(#__VA_ARGS__), __VA_ARGS__)
#define ch(...)  vchoice(_countArgs(#__VA_ARGS__), __VA_ARGS__)

/* Misc strategies */
// Prints a message and does nothing
#define print(format, ...) _rule(lambda (void *term) . (({printf(format, __VA_ARGS__); term;})), "print")

/* Helpers */
// Parses the source code given by seq or ch and counts the total number of arguments
static int _countArgs(const char *args) {
  int result = 0;
  int i = 0;
  int depth = 0;

  // Skip leading whitespace
  while (args[i] == ' ' || args[i] == '\t' || args[i] == '\n' || args[i] == '\r') i++;

  // If the string doesn't immediately end, then there is at least 1 arg
  if (args[i]) result++;

  // Loop over chars at the top level
  // Invariant: args[i] is the next unprocessed char
  while (args[i]) {
    // Count top level commas
    if (args[i] == ',')
      if (depth == 0) result++;

    // Ignore escape chars
    else if (args[i] == '\'') i += 2;

    // Ignore strings
    else if (args[i] == '\"') {
      // Skip chars until an unescaped quote ends the string
      while (args[i]) {
        if (args[i+1] == '\"' && args[i] != '\\') {
          i++;
          break;
        }
        i++;
      }
    }

    // Ignore contents of nested parens
    else if (args[i] == '(') {
      depth++;
    }
    else if (args[i] == ')') {
      depth--;
    }
    i++;
  }

  return result;
}

#endif