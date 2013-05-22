dnl $Id$
dnl config.m4 for extension swoole

dnl Comments in this file start with the string 'dnl'.
dnl Remove where necessary. This file will not work
dnl without editing.

dnl If your extension references something external, use with:

dnl Otherwise use enable:

PHP_ARG_ENABLE(swoole-debug, whether to enable swoole debug,
[  --enable-swoole-debug           Enable swoole debug], no, no)

PHP_ARG_WITH(swoole, for swoole support,
[  --with-swoole             Include swoole support])

AC_DEFUN([AC_SWOOLE_KQUEUE],
[
	AC_MSG_CHECKING([for kqueue])

	AC_TRY_COMPILE(
	[ 
		#include <sys/types.h>
		#include <sys/event.h>
		#include <sys/time.h>
	], [
		int kfd;
		struct kevent k;
		kfd = kqueue();
		/* 0 -> STDIN_FILENO */
		EV_SET(&k, 0, EVFILT_READ , EV_ADD | EV_CLEAR, 0, 0, NULL);
	], [
		AC_DEFINE([HAVE_KQUEUE], 1, [do we have kqueue?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_DEFUN([AC_SWOOLE_CPU_AFFINITY],
[
    AC_MSG_CHECKING([for cpu affinity])
    AC_TRY_COMPILE(
    [
    ], [
        cpu_set_t cpu_set;
		CPU_ZERO(&cpu_set);
		CPU_SET(pti % SW_CPU_NUM, &cpu_set);
    ], [
        AC_DEFINE([HAVE_CPU_AFFINITY], 1, [cpu affinity?])
        AC_MSG_RESULT([yes])
    ], [
        AC_MSG_RESULT([no])
    ])
])

AC_DEFUN([AC_SWOOLE_TIMERFD],
[
	AC_MSG_CHECKING([for timerfd])

	AC_TRY_COMPILE(
	[ 
	    #include <sys/time.h>
		#include <sys/timerfd.h>
	], [
        timerfd_create(CLOCK_REALTIME, TFD_NONBLOCK | TFD_CLOEXEC);
	], [
		AC_DEFINE([HAVE_TIMERFD], 1, [do we have timerfd?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_DEFUN([AC_SWOOLE_EPOLL],
[
	AC_MSG_CHECKING([for epoll])

	AC_TRY_COMPILE(
	[ 
		#include <sys/epoll.h>
	], [
		int epollfd;
		struct epoll_event e;

		epollfd = epoll_create(1);
		if (epollfd < 0) {
			return 1;
		}

		e.events = EPOLLIN | EPOLLET;
		e.data.fd = 0;

		if (epoll_ctl(epollfd, EPOLL_CTL_ADD, 0, &e) == -1) {
			return 1;
		}

		e.events = 0;
		if (epoll_wait(epollfd, &e, 1, 1) < 0) {
			return 1;
		}
	], [
		AC_DEFINE([HAVE_EPOLL], 1, [do we have epoll?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])

AC_DEFUN([AC_SWOOLE_EVENTFD],
[
	AC_MSG_CHECKING([for eventfd])

	AC_TRY_COMPILE(
	[ 
		#include <sys/eventfd.h>
	], [
		int efd;

		efd = eventfd(0, 0);
		if (efd < 0) {
			return 1;
		}
	], [
		AC_DEFINE([HAVE_EVENTFD], 1, [do we have eventfd?])
		AC_MSG_RESULT([yes])
	], [
		AC_MSG_RESULT([no])
	])
])


if test "$PHP_SWOOLE" != "no"; then
  PHP_ADD_INCLUDE($SWOOLE_DIR/include)
  AC_ARG_ENABLE(debug, 
    [--enable-debug,  compile with debug symbols],
    [PHP_DEBUG = $enableval],
    [PHP_DEBUG = 0]
  )

  if test "$PHP_SWOOLE_DEBUG" != "no"; then
      AC_DEFINE(SW_DEBUG, 1, [do we enable swoole debug])
  fi

  AC_SWOOLE_EVENTFD
  AC_SWOOLE_EPOLL
  AC_SWOOLE_KQUEUE
  AC_SWOOLE_TIMERFD
  AC_SWOOLE_CPU_AFFINITY

  PHP_NEW_EXTENSION(swoole, swoole.c \
    src/core/Base.c \
	src/core/RingQueue.c \
    src/factory/Factory.c \
    src/factory/FactoryThread.c \
    src/factory/FactoryProcess.c \
    src/reactor/ReactorBase.c \
    src/reactor/ReactorSelect.c \
	src/reactor/ReactorPoll.c \
    src/reactor/ReactorEpoll.c \
    src/reactor/ReactorKqueue.c \
	src/pipe/PipeBase.c \
	src/pipe/PipeEventfd.c \
	src/pipe/PipeUnsock.c \
	src/pipe/PipeMsg.c \
    src/network/Server.c \
    src/network/Client.c \
  , $ext_shared)
fi
