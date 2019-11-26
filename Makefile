.PHONY: ability run node all

all:
	@make -C art/main_actors
	@make -C art/props
	@make -C art/tiles
	@make -C art/maps
	@make -C art/icons
	@make -C art/ui

flow: all
	love . node combat/flow.lua

run: all
	love . $(RUN_ARGS)

node: all
	love . node $(path) $(p)

ability: all
	love . ability $(path) $(p)

log:
	@rm -f log.txt
