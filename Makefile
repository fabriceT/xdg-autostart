all: xdg-autostart strip

SRC= AutostartInfoBuilder.vala\
     AutostartInfo.vala\
     App.vala\
     DirectoryReader.vala\
     ProgramLauncher.vala

xdg-autostart: $(SRC)
	@echo "Compiling $<"
	@valac -o xdg-autostart $(SRC)
	# Debug
	#@valac -g xdg-autostart.vala --save-temps

.PHONY: strip clean

strip: xdg-autostart
	@echo "Stripping $<"
	@strip --strip-unneeded $<

clean:
	rm xdg-autostart 2>/dev/null

