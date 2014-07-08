all: xdg-autostart strip

xdg-autostart: xdg-autostart.vala
	@echo "Compiling $<"
	@valac xdg-autostart.vala

.PHONY: strip clean

strip: xdg-autostart
	@echo "Stripping $<"
	@strip --strip-unneeded $<

clean:
	rm xdg-autostart 2>/dev/null

