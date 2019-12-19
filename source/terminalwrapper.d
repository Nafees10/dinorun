module terminalwrapper;

import arsd.terminal;

public alias Color = arsd.terminal.Color;

/// Wrapper to arsd.terminal to make it work bit more like termbox-d
class TermWrapper{
private:
	Terminal _term;
	RealTimeConsoleInput _input;
public:
	/// constructor
	this(){
		_term = Terminal(ConsoleOutputType.cellular);
		_input = RealTimeConsoleInput(&_term,ConsoleInputFlags.allInputEvents);
	}
	~this(){
		_term.clear;
		.destroy(_input);
		.destroy(_term);
	}
	/// Returns: width of termial
	@property int width(){
		return _term.width;
	}
	/// Returns: height of terminal
	@property int height(){
		return _term.height;
	}
	/// sets terminal colors. `fg` is foreground, `bg` is background
	void color(Color fg, Color bg){
		_term.color(fg, bg);
	}
	/// fills all cells with a character
	void fill(char ch){
		int _w = width, _h = height;
		char[] line;
		line.length = _w;
		line[] = ch;
		// write line _h times
		for (uint i = 0; i < _h; i ++){
			_term.moveTo(0,i);
			_term.write(line);
		}
	}
	/// fills a rectangle with a character
	void fill(char ch, int x1, int x2, int y1, int y2){
		char[] line;
		line.length = (x2 - x1) + 1;
		line[] = ch;
		foreach(i; y1 .. y2 +1){
			_term.moveTo(x1, i);
			_term.write(line);
		}
	}
	/// flush to terminal
	void flush(){
		_term.moveTo(width+1, height+1);
		_term.hideCursor();
		_term.flush();
	}
	/// writes a character `ch` at a position `(x, y)`
	void put(int x, int y, char ch){
		_term.moveTo(x, y);
		_term.write(ch);
	}
	/// writes a character `ch` at a position `(x, y)` with `fg` as foreground ang `bg` as background color
	void put(int x, int y, char ch, Color fg, Color bg){
		_term.color(fg, bg);
		_term.moveTo(x, y);
		_term.write(ch);
	}
	/// Returns: a key press which is a char, if no char pressed, returns 0x00
	char getKey(){
		KeyboardEvent k;
		k.which = _input.getch(true);
		if (k.isCharacter)
			return cast(char)k.which;
		return 0x00;
	}
}