PROJECT=pager
CT_OPTS = -create_priv_dir auto_per_tc
PKG_REVISION ?= $(shell git describe --tags)
PKG_VERSION	?= $(shell git describe --tags | tr - .)

DEPS = json kvc riak_core cowboy jiffy jsx erlydtl
dep_json = git https://github.com/hio/erlang-json.git
dep_kvc = git https://github.com/etrepum/kvc.git
dep_riak_core = git https://github.com/basho/riak_core 2.0.2
dep_cowboy = git https://github.com/ninenines/cowboy.git 1.0.0
dep_jiffy = git https://github.com/davisp/jiffy.git 0.13.0
dep_jsx = git https://github.com/talentdeficit/jsx.git v2.1.1
dep_erlydtl = git https://github.com/evanmiller/erlydtl.git

.PHONY: release

release: clean app
	rm -rf _rel
	sed  "s/VERSION/\"$(PKG_VERSION)\"/" < relx.config.script > relx.config
	./relx release --relname pager --relvsn "$(PKG_VERSION)" -V 3 --lib-dir ebin

package: release
	rm -f *.deb
	fpm -s dir -t deb -n pager -v "$(PKG_VERSION)" \
		--before-install=rel/before-install \
		_rel/pager=/opt/ \
		rel/init=/etc/init.d/pager \
		rel/var/lib/pager/=/var/lib/pager/ \
		rel/etc/pager/pager.config=/etc/pager/pager.config \
		rel/etc/default/pager=/etc/default/pager

shell_1: app
	mkdir -p data/{cluster_meta,ring}
	erl -pag ebin \
	-name pager@127.0.0.1 \
	-setcookie shell \
	-pa {apps,deps}/*/ebin \
	-pa ebin \
	-eval "application:ensure_all_started(pager)."

include erlang.mk
