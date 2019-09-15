all:
	@make -C art/main_actors
	@make -C art/props
	@make -C art/tiles
	@make -C art/maps
	@make -C art/icons
	@make -C art/ui

log:
	@rm -f log.txt
