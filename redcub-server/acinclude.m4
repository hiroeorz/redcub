# Configure paths for Ruby

dnl AM_PATH_RUBY([MINIMUM-VERSION])
dnl Adds support for Ruby
AC_DEFUN(AM_PATH_RUBY,
[
AC_ARG_WITH(ruby,
[  --with-ruby=PATH        path to ruby],
[
    AC_MSG_RESULT(using $withval for ruby)
    RUBY="$withval"
], [
    AC_PATH_PROG(RUBY, ruby, no)
])
if test "$RUBY" = "no"; then
    AC_MSG_ERROR(Ruby is required)
fi

ifelse([$1],[],,[
  AC_MSG_CHECKING(for Ruby version >= $1)
  if $RUBY -e 'exit(RUBY_VERSION >= "$1" ? 0 : 1)'; then
    AC_MSG_RESULT(yes)
  else
    AC_MSG_RESULT(no)
    AC_MSG_ERROR(Ruby version is too old)
  fi
])

RUBY_VERSION=`$RUBY -e 'print RUBY_VERSION'`
AC_SUBST(RUBY_VERSION)

changequote(<<, >>)dnl
rubylibdir=`$RUBY -r rbconfig -e 'print Config::CONFIG["rubylibdir"]'`
rubyarchdir=`$RUBY -r rbconfig -e 'print Config::CONFIG["archdir"]'`
rubysitelibdir=`$RUBY -r rbconfig -e 'print Config::CONFIG["sitelibdir"]'`
rubysitearchdir=`$RUBY -r rbconfig -e 'print Config::CONFIG["sitearchdir"]'`
changequote([, ])dnl
AC_SUBST(rubylibdir)
AC_SUBST(rubyarchdir)
AC_SUBST(rubysitelibdir)
AC_SUBST(rubysitearchdir)

changequote(<<, >>)dnl
RUBY_CFLAGS=`$RUBY -r rbconfig -e 'print Config::CONFIG["CFLAGS"] + " -I" + Config::CONFIG["archdir"]'`
changequote([, ])dnl
AC_SUBST(RUBY_CFLAGS)

changequote(<<, >>)dnl
RUBY_SHARED=`$RUBY -r rbconfig -e 'print Config::CONFIG["ENABLE_SHARED"]'`
if test "$RUBY_SHARED" = "yes"; then
  RUBY_LIBS=`$RUBY -r rbconfig -e 'print Config::CONFIG["LIBRUBYARG"].gsub(/-L\./, "-L" + Config::CONFIG["libdir"]) + " " + Config::CONFIG["LIBS"]'`
  RUBY_EXT_LIBS="$RUBY_LIBS"
else
  RUBY_LIBS=`$RUBY -r rbconfig -e 'print Config::CONFIG["archdir"] + "/" + Config::CONFIG["LIBRUBYARG"] + " " + Config::CONFIG["LIBS"]'`
  RUBY_EXT_LIBS=`$RUBY -r rbconfig -e 'Config::CONFIG["LIBS"]'`
fi
changequote([, ])dnl
AC_SUBST(RUBY_SHARED)
AC_SUBST(RUBY_LIBS)
AC_SUBST(RUBY_EXT_LIBS)
])
