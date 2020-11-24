# Set general macros
buildFile = build/app
tempDir = .temp

# Check for Windows
ifeq ($(OS), Windows_NT)
	# Set Windows compile macros
	platform = Windows
	compiler = g++
	options = -pthread -lopengl32 -lgdi32 -lwinmm -mwindows
	
	# Set Windows commands
	cleanCommand = del build\app.exe  
else
	# Check for MacOS/Linux
	UNAMEOS := $(shell uname)
	ifeq ($(UNAMEOS), Linux)
		# Set Linux compile macros
		platform = Linux
		compiler = g++
		options = -l GL -l m -l pthread -l dl -l rt -l X11
		libGenDirectory = # Empty
	endif
	ifeq ($(UNAMEOS), Darwin)
		# Set macOS compile macros
		platform = macOS
		compiler = clang++
		options = -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL
		libGenDirectory = src
	endif

	# Set UNIX commands
	mkdirOptions = -p
	cleanCommand = rm $(buildFile); rm -rf $(tempDir)
endif

run: compile execute clean

setup: include lib

test: compile execute check clean

pull:
	# Pull and update the the build submodules
	git submodule init; git submodule update
	cd vendor/raylib-cpp; git submodule init; git submodule update

include: pull
	# Copy the relevant header files into includes
	mkdir $(mkdirOptions) include
	cp vendor/raylib-cpp/vendor/raylib/src/raylib.h include/raylib.h
	cp vendor/raylib-cpp/vendor/raylib/src/raymath.h include/raymath.h
	cp vendor/raylib-cpp/include/*.hpp include

lib: pull
	# Build the raylib static library file and copy it into lib
	cd vendor/raylib-cpp/vendor/raylib/src; make PLATFORM=PLATFORM_DESKTOP
	mkdir $(mkdirOptions) lib/$(platform)
	cp vendor/raylib-cpp/vendor/raylib/$(libGenDirectory)/libraylib.a lib/$(platform)/libraylib.a

compile:
	# Create the build folder and compile the executable
	mkdir $(mkdirOptions) build
	$(compiler) -std=c++17 -I include -L lib/$(platform) src/main.cpp -o $(buildFile) -l raylib $(options)

execute:
	# Run the executable and push the output to a log file
	mkdir $(mkdirOptions) $(tempDir)
	$(buildFile) | tee $(tempDir)/execute.log

clean:
	# Clean up all relevant files
	$(cleanCommand)

check:
	# Search the execution log for mention of raylib starting
	$(eval VAR = $(shell grep -c "raylib" $(tempDir)/execute.log))
	if [ $(VAR) -gt 0 ];\
	then echo "Application was started";\
	else echo "Application failed to start"; exit 1;\
	fi
