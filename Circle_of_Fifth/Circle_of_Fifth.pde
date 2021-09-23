import ddf.minim.*;
import ddf.minim.ugens.*;

// 描画
final color BACK_COLOR = color(255, 255, 255);
final color NOTE_COLOR = color(214, 214, 214);
final color PLAY_COLOR = color(255, 159, 159);
final color STROKE_COLOR = color(255, 255, 255);

// 音
final int OCTAVE_NUM = 12;
final float BASE_NOTE = 27.5;

float fade_time = 0.1;
float volume = 0.3;
int center_note = 44;
int code_type = 0;
float start_angle = 0;
boolean rotating = false;
boolean playing = false;

Minim minim;
AudioOutput sound_out;
CodePlayer code_player;
Circle circle;

// 1オクターブに収まるように剰余を求める
int modOctave(int n) {
  return (n % OCTAVE_NUM + OCTAVE_NUM) % OCTAVE_NUM;
}

float modOctave(float n) {
  return (n % OCTAVE_NUM + OCTAVE_NUM) % OCTAVE_NUM;
}

void setup() {
  // ウィンドウ設定
  size(720, 720);
  surface.setResizable(true);

  // フォント
  textFont(createFont("Arial", 24));
  textAlign(RIGHT, BOTTOM);

  // 音の設定
  minim = new Minim(this);
  sound_out = minim.getLineOut(Minim.STEREO);
  code_player = new CodePlayer(sound_out, volume, fade_time);
  circle = new Circle(0, 0, 1);
}

void draw() {
  // スケーリング
  translate(width / 2.0, height / 2.0);
  scale(min(width, height) / 2.0, min(width, height) / 2.0);

  background(BACK_COLOR);

  // 五度圏表を描画
  if (rotating)
    circle.addAngle(circle.posToEuler(mouseX, mouseY)[1] - start_angle);

  circle.draw();

  // 中心音
  pushMatrix();
  translate(0.97, 0.97);
  scale(0.0025);

  fill(0);
  text("Center: " + center_note, 0, 0);

  popMatrix();
}

void mousePressed() {
  if (circle.isHoldingBar(mouseX, mouseY)) {
    // 回転
    rotating = true;
    start_angle = circle.posToEuler(mouseX, mouseY)[1];
  } else {
    int code = circle.getCode(mouseX, mouseY);

    if (code != -1) {
      playing = true;
      code_player.play(codes[code], center_note);
      circle.turnOnByCode(code);
    }
  }
}

void mouseReleased() {
  // 音を止める
  if (playing) {
    playing = false;
    code_player.stop();
    circle.turnOff();
  }

  // 回転位置を決定する
  if (rotating) {
    rotating = false;
    circle.setKeyByAngle();
  }
}

void keyPressed() {
  if (keyCode == 37) code_type--;
  if (keyCode == 39) code_type++;
  if (keyCode == 40) center_note--;
  if (keyCode == 38) center_note++;

  code_type = constrain(code_type, 0, 2);
  center_note = constrain(center_note, 32, 56);

  circle.setCodeType(code_type);
}
