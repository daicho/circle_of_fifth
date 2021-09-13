import ddf.minim.*;
import ddf.minim.ugens.*;

// 描画
color back_color = color(255, 255, 255);
color note_color = color(214, 214, 214);
color play_color = color(255, 159, 159);
color stroke_color = color(255, 255, 255);
float stroke_weight = 0.01;
float circles[] = {0.99, 0.79, 0.59, 0.39, 0.34};
boolean rotating = false;
float angle = 0;
float start_angle;
int key_note = 0;

// 音
final float BASE_NOTE = 27.5;
final int NOTE_NUM = 88;
final int OCTAVE_NUM = 12;

float fade_time = 0.1;
float volume = 0.3;
int center_note = 44;

Minim minim;
AudioOutput sound_out;
Note[] notes = new Note[NOTE_NUM];

final int[][][] display_codes = {
  {
    {3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1, 8},
    {12, 19, 14, 21, 16, 23, 18, 13, 20, 15, 22, 17},
    {26, 33, 28, 35, 30, 25, 32, 27, 34, 29, 24, 31}
  },
  {
    {39, 46, 41, 36, 43, 38, 45, 40, 47, 42, 37, 44},
    {48, 55, 50, 57, 52, 59, 54, 49, 56, 51, 58, 53},
    {62, 69, 64, 71, 66, 61, 68, 63, 70, 65, 60, 67}
  },
  {
    {75, 82, 77, 72, 79, 74, 81, 76, 83, 78, 73, 80},
    {84, 91, 86, 93, 88, 95, 90, 85, 92, 87, 94, 89},
    {98, 105, 100, 107, 102, 97, 104, 99, 106, 101, 96, 103}
  }
};

PShape[] code_images;
boolean playing = false;
int code_type = 0;
int code_row = 0;
int code_pos = 0;

// スクリーン座標系からローカル座標系に変換
PVector screenToLocal(float x, float y) {
  PVector in = new PVector(x, y);
  PVector out = new PVector();

  PMatrix2D current_matrix = new PMatrix2D();
  getMatrix(current_matrix);

  current_matrix.invert();
  current_matrix.mult(in, out);

  return out;
}

void setup() {
  // ウィンドウ設定
  size(640, 640);
  surface.setResizable(true);

  // 描画設定
  strokeWeight(stroke_weight);
  strokeCap(SQUARE);
  ellipseMode(RADIUS);
  shapeMode(CENTER);
  textAlign(RIGHT, BOTTOM);
  
  // フォント
  textFont(createFont("Arial", 24));

  // コードの画像を読み込み
  code_images = new PShape[codes.length];
  for (int i = 0; i < codes.length; i++)
    code_images[i] = loadShape("codes/code_" + i + ".svg");

  // 音の設定
  minim = new Minim(this);
  sound_out = minim.getLineOut(Minim.STEREO);

  for (int i = 0; i < NOTE_NUM; i++)
    notes[i] = new Note(BASE_NOTE * pow(2, i / float(OCTAVE_NUM)), volume, fade_time, sound_out);
}

void draw() {
  // スケーリング
  translate(width / 2.0, height / 2.0);
  scale(min(width, height) / 2.0, min(width, height) / 2.0);

  // 位置を取得
  PVector pos = screenToLocal(mouseX, mouseY);
  float a = atan2(pos.x, -pos.y) + TWO_PI / OCTAVE_NUM / 2 - angle;
  float cur_angle = angle + (rotating ? a - start_angle : 0);

  background(back_color);

  // 円を描画
  pushMatrix();
  rotate(cur_angle);

  noStroke();

  for (int i = 0; i < 3; i++) {
    fill(note_color);
    ellipse(0, 0, circles[i], circles[i]);

    if (playing && code_row == i) {
      fill(play_color);
      arc(0, 0, circles[i], circles[i], TWO_PI / OCTAVE_NUM * (code_pos - 3.5), TWO_PI / OCTAVE_NUM * (code_pos - 2.5));
    }
  }

  fill(note_color);
  ellipse(0, 0, circles[3], circles[3]);

  fill(back_color);
  ellipse(0, 0, circles[4], circles[4]);

  stroke(stroke_color);
  noFill();

  for (int i = 0; i < circles.length; i++)
    ellipse(0, 0, circles[i], circles[i]);

  // 線を描画
  pushMatrix();
  rotate(-TWO_PI / OCTAVE_NUM / 2);

  for (int i = 0; i < OCTAVE_NUM; i++) {
    line(0, circles[0], 0, circles[3]);
    rotate(TWO_PI / OCTAVE_NUM);
  }

  popMatrix();
  popMatrix();

  // コードを描画
  for (int i = 0; i < OCTAVE_NUM; i++) {
    for (int j = 0; j < 3; j++) {
      pushMatrix();
      translate((circles[j] + circles[j + 1]) / 2 * sin(TWO_PI / OCTAVE_NUM * i + cur_angle), (circles[j] + circles[j + 1]) / 2 * -cos(TWO_PI / OCTAVE_NUM * i + cur_angle));
      scale(0.0022);

      shape(code_images[display_codes[code_type][j][i]]);

      popMatrix();
    }
  }
  
  // 中心音
  pushMatrix();
  translate(0.97, 0.97);
  scale(0.0025);

  fill(0);
  text("Center: " + center_note, 0, 0);

  popMatrix();
}

void mousePressed() {
  // 位置を取得
  PVector pos = screenToLocal(mouseX, mouseY);
  float r = dist(0, 0, pos.x, pos.y);
  float a = atan2(pos.x, -pos.y) + TWO_PI / OCTAVE_NUM / 2 - angle;

  if (r > circles[0] || r < circles[4])
    return;

  // コードを取得
  for (int i = 0; i < 4; i++) {
    if (r >= circles[i + 1]) {
      code_row = i;
      break;
    }
  }

  if (code_row == 3) {
    rotating = true;
    start_angle = a;
  } else {
    playing = true;
    code_pos = int(a * OCTAVE_NUM / TWO_PI + OCTAVE_NUM) % OCTAVE_NUM;
  
    // 音を鳴らす
    int[] voiced_code = codes[display_codes[code_type][code_row][code_pos]].voicing(center_note);
    for (int i = 0; i < voiced_code.length; i++)
      notes[voiced_code[i]].play();
  }
}

void mouseReleased() {
  // 位置を取得
  PVector pos = screenToLocal(mouseX, mouseY);
  float a = atan2(pos.x, -pos.y) + TWO_PI / OCTAVE_NUM / 2 - angle;

  // 音を止める
  if (playing) {
    playing = false;

    for (int i = 0; i < NOTE_NUM; i++)
      notes[i].pause();
  }

  // キーを決定する
  if (rotating) {
    rotating = false;
    key_note = (round((angle + a - start_angle) / -TWO_PI * OCTAVE_NUM) + OCTAVE_NUM) % OCTAVE_NUM;
    angle = TWO_PI * -key_note / OCTAVE_NUM;
  }
}

void keyPressed() {
  if (keyCode == 37) code_type--;
  if (keyCode == 39) code_type++;
  if (keyCode == 40) center_note--;
  if (keyCode == 38) center_note++;
  code_type = constrain(code_type, 0, 2);
  center_note = constrain(center_note, 36, 52);
}
