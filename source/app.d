import terminalwrapper;
import core.thread;
import std.random : uniform;
import std.conv : to;
import utils.lists : FIFOStack;
import utils.misc;

const Color SCORE_COLOR = Color.black; /// color of score text
const Color GAMEOVER_COLOR = Color.red; /// color of background when game's over
const Color BACK_COLOR = Color.white; /// background color
const Color GROUND_COLOR = Color.green; /// ground color
const Color GROUND_COLOR_ALT = Color.blue; /// ground color
const Color DINO_COLOR = Color.black; /// dino's color
const Color GROUND_OBSTACLE_COLOR = Color.red; /// ground based obstacle color
const Color FLYING_OBSTACLE_COLOR = Color.red; /// flying obstacles color

const float GRAVITY = 0.5; /// gravity experienced by dino
const float JUMP_VELOCITY = 3.1; /// dino's jump velocity
const float START_SPEED = 1.2; /// initial speed of game
const float SPEED_INC = 0.05; /// speed increase every 100 points
const float SPEED_MAX = 2.4; /// maximum speed of game

const DINO_POS_X = 6; /// dinos position on x-axis (constant throughtout game)
const DINO_WIDTH = 2; /// width of dino
const DINO_HEIGHT = 2; /// height of dino

const OBSTACLE_COUNT = 5; /// max number of obstacles in one spot

const PEACE_TIME = 15; /// number of frames before obstacles are added
const PEACE_TIME_UNCERTAINTY = 6; /// max number of frames that are added as extra peace time
const PEACE_TIME_RAND_MAX = 6; /// max number of frames to skip before adding obstacle when previously deciding to not add obstacle

void main(){
	TermWrapper term = new TermWrapper;
	term.color(DINO_COLOR, BACK_COLOR);
	term.fill(' ');
	// fill ground
	term.color(DINO_COLOR, GROUND_COLOR);
	term.fill(' ', 0, term.width-1, term.height-1, term.height-1);

	FIFOStack!GroundObstacle inactiveObstacles = new FIFOStack!GroundObstacle;// inactive
	foreach (i; 0 .. OBSTACLE_COUNT){
		inactiveObstacles.push(new GroundObstacle(term.height-2, term.width-1));
	}
	FIFOStack!GroundObstacle activeObstacles = new FIFOStack!GroundObstacle; // active
	Dino dino = new Dino(term.height-2, term.height-1);
	GroundDot dot = new GroundDot(term.height-1, term.width-1);
	GroundDot dot2 = new GroundDot(term.height-1, term.width/2-1);

	int peaceTime = 0; /// number of frames before next obstacle will be added
	int score = 0;
	float speed = START_SPEED;
	int lastSpeedIncAt = 0; /// at what score was speed increased last time
	int frameNum = 0 ; /// which of the 30 frames is this? 0 .. 30
	try{
		char input = 0x00;
		while (input != 'q'){
			if (peaceTime > 0)
				peaceTime --;
			input = term.getKey;
			if (input == ' ')
				dino.jump();
			dino.step(term);
			dot.step(term);
			dot2.step(term);
			// now deal with active obstacles
			for (int i = 0; i < activeObstacles.count; i ++){
				GroundObstacle obstacle = activeObstacles.pop;
				if (obstacle.x < 0){
					obstacle.x = term.width-1;
					inactiveObstacles.push(obstacle);
				}else{
					obstacle.step(term);
					if (dino.isColliding(obstacle)){
						term.color(SCORE_COLOR, GAMEOVER_COLOR);
						term.fill(' ');
						string scoreString = to!string(score);
						int xOffset = (term.width - cast(int)scoreString.length) / 2;
						foreach (x, ch; scoreString)
							term.put(xOffset+cast(int)x, term.height/2 - 1, ch);
						term.flush();

						Thread.getThis.sleep(dur!"msecs"(1500));
						throw new Exception("noob");
					}
					activeObstacles.push(obstacle);
				}
			}
			// check if more obstacles should be added
			if (activeObstacles.count < OBSTACLE_COUNT  && peaceTime <= 0){
				if (uniform(0, 2) == 0){
					peaceTime = PEACE_TIME + uniform(0, PEACE_TIME_UNCERTAINTY+1);
					activeObstacles.push(inactiveObstacles.pop);
				}else
					peaceTime = uniform(0, PEACE_TIME_RAND_MAX+1);
			}
			if (frameNum == 29)
				score ++;
			// increase speed
			if ((score - lastSpeedIncAt) % 30 == 0 && speed < SPEED_MAX){
				lastSpeedIncAt = score;
				speed += SPEED_INC;
				foreach (i; 0 .. inactiveObstacles.count){
					GroundObstacle obstacle = inactiveObstacles.pop;
					obstacle.velocity = speed;
					inactiveObstacles.push(obstacle);
				}
				foreach (i; 0 .. activeObstacles.count){
					GroundObstacle obstacle = activeObstacles.pop;
					obstacle.velocity = speed;
					activeObstacles.push(obstacle);
				}
				dot.velocity = speed;
				dot2.velocity = speed;
			}
			// write score
			string scoreString = to!string(score);
			term.color(SCORE_COLOR, BACK_COLOR);
			foreach(x, ch; scoreString)
				term.put(cast(int)x, 0, ch);
			// update terminal
			term.flush();
			Thread.getThis.sleep(dur!"msecs"(33));
			frameNum++;
			frameNum = frameNum % 30;
		}
	}catch (Exception e){
		.destroy(e);
	}
	
	.destroy(term);
}

private class GroundDot{
private:
	int _y; /// y position of dot
	float _x; /// x position of dot
	float _velocity; /// distance per frame
public:
	this(int yPos, int xPos){
		_y = yPos;
		_x = cast(float)xPos;
		_velocity = START_SPEED;
	}
	~this(){

	}
	/// Sets velocity of dot
	@property float velocity(float newVelocity){
		return _velocity = newVelocity;
	}
	/// called ~30 times per second
	void step(TermWrapper term){
		// clear cell
		term.put(cast(int)_x, _y, ' ', DINO_COLOR, GROUND_COLOR);
		_x -= _velocity;
		// if x < 0, set x to width
		if (_x < 0)
			_x = cast(float)(term.width-1);
		// draw itself
		term.put(cast(int)_x, _y, ' ', DINO_COLOR, GROUND_COLOR_ALT);
	}
}

private class GroundObstacle{
private:
	int _y; /// yPosition of obstacle
	float _x; /// xPosition of obstacle
	float _velocity; /// speed of this obstacle
public:
	this(int yPos, int xPos){
		_y = yPos;
		_x = xPos;
		_velocity = START_SPEED;
	}
	~this(){

	}
	/// Sets the velocity
	@property float velocity(float newV){
		return _velocity = newV;
	}
	/// called ~30 times per second
	void step(TermWrapper term){
		// clear last pixels
		term.color(BACK_COLOR, BACK_COLOR);
		term.put(cast(int)_x, _y, ' ');
		term.put(cast(int)_x, _y-1, ' ');
		// move
		_x -= _velocity;
		// draw itself
		if (_x >= 0){
			term.color(BACK_COLOR, GROUND_OBSTACLE_COLOR);
			term.put(cast(int)_x, _y, ' ');
			term.put(cast(int)_x, _y-1, ' ');
		}
	}
	/// Returns: x position of obstacle
	@property float x(){
		return _x;
	}
	/// Sets the x position of obstacle
	@property float x(float newX){
		return _x = newX;
	}
	/// Returns: y position of obstacle
	@property int y(){
		return _y;
	}
}

private class Dino{
private:
	int _y; /// yPos of dino
	float _velocity; /// vertical velocity. Up is positive
	int _groundY; /// yPosition of ground 
public:
	this(int yPosition, int groundY){
		_y = yPosition;
		_groundY = groundY;
		_velocity = 0;
	}
	~this(){

	}
	/// starts a jump
	void jump(){
		// check if in contact with ground
		if (_y+1 == _groundY){
			_velocity = JUMP_VELOCITY;
		}
	}
	/// called ~30 times per second
	void step(TermWrapper term){
		// clear the cells
		term.color(Color.white, Color.white);
		term.fill(' ', DINO_POS_X - DINO_WIDTH, DINO_POS_X, _y - DINO_HEIGHT + 1, _y);
		_y = _y - cast(int)_velocity;
		// decrease velocity by gravity
		_velocity -= cast(float)GRAVITY;
		// don't let it fall below ground
		if (_y >= _groundY){
			_y = _groundY - 1;
			_velocity = 0;
		}
		// draw itself
		term.color(Color.black, Color.black);
		term.fill(' ', DINO_POS_X - DINO_WIDTH, DINO_POS_X, _y - DINO_HEIGHT + 1, _y);
	}
	/// y position of dino
	@property int y(){
		return _y;
	}
	/// Returns: true if is colliding with a GroundObstacle
	bool isColliding(GroundObstacle obs){
		return (obs.x < DINO_POS_X) && (obs.x > DINO_POS_X - DINO_WIDTH) && (cast(int)_y >= obs.y-1);
	}
}