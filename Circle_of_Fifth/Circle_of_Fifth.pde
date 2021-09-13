import ddf.minim.*;
import ddf.minim.ugens.*;

// 描画
color back_color = color(255, 255, 255);
color note_color = color(214, 214, 214);
color play_color = color(255, 159, 159);
color stroke_color = color(255, 255, 255);
float stroke_weight = 0.01;

float circles[] = {0.99, 0.79, 0.59, 0.39, 0.34};

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

// コード
Code[] codes = {
  new Code("A", 0, new int[]{0, 4, 7}),
  new Code("B♭", 1, new int[]{1, 5, 8}),
  new Code("B", 2, new int[]{2, 6, 9}),
  new Code("C", 3, new int[]{3, 7, 10}),
  new Code("D♭", 4, new int[]{4, 8, 11}),
  new Code("D", 5, new int[]{5, 9, 0}),
  new Code("E♭", 6, new int[]{6, 10, 1}),
  new Code("E", 7, new int[]{7, 11, 2}),
  new Code("F", 8, new int[]{8, 0, 3}),
  new Code("G♭", 9, new int[]{9, 1, 4}),
  new Code("G", 10, new int[]{10, 2, 5}),
  new Code("A♭", 11, new int[]{11, 3, 6}),
  new Code("Am", 0, new int[]{0, 3, 7}),
  new Code("B♭m", 1, new int[]{1, 4, 8}),
  new Code("Bm", 2, new int[]{2, 5, 9}),
  new Code("Cm", 3, new int[]{3, 6, 10}),
  new Code("C♯m", 4, new int[]{4, 7, 11}),
  new Code("Dm", 5, new int[]{5, 8, 0}),
  new Code("E♭m", 6, new int[]{6, 9, 1}),
  new Code("Em", 7, new int[]{7, 10, 2}),
  new Code("Fm", 8, new int[]{8, 11, 3}),
  new Code("F♯m", 9, new int[]{9, 0, 4}),
  new Code("Gm", 10, new int[]{10, 1, 5}),
  new Code("G♯m", 11, new int[]{11, 2, 6}),
  new Code("Am(♭5)", 0, new int[]{0, 3, 6}),
  new Code("A♯m(♭5)", 1, new int[]{1, 4, 7}),
  new Code("Bm(♭5)", 2, new int[]{2, 5, 8}),
  new Code("Cm(♭5)", 3, new int[]{3, 6, 9}),
  new Code("C♯m(♭5)", 4, new int[]{4, 7, 10}),
  new Code("Dm(♭5)", 5, new int[]{5, 8, 11}),
  new Code("D♯m(♭5)", 6, new int[]{6, 9, 0}),
  new Code("Em(♭5)", 7, new int[]{7, 10, 1}),
  new Code("Fm(♭5)", 8, new int[]{8, 11, 2}),
  new Code("F♯m(♭5)", 9, new int[]{9, 0, 3}),
  new Code("Gm(♭5)", 10, new int[]{10, 1, 4}),
  new Code("G♯m(♭5)", 11, new int[]{11, 2, 5})
};

final int[][] display_codes = {
  {3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1, 8},
  {12, 19, 14, 21, 16, 23, 18, 13, 20, 15, 22, 17},
  {26, 33, 28, 35, 30, 25, 32, 27, 34, 29, 24, 31}
};

PShape[] code_images = new PShape[codes.length];
int code_type;
int code_pos;
int code_num;
boolean playing;


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

  // コードの画像を読み込み
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

  background(back_color);

  // 円を描画
  noStroke();

  for (int i = 0; i < 3; i++) {
    fill(note_color);
    ellipse(0, 0, circles[i], circles[i]);

    if (playing && code_type == i) {
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

  // コードを描画
  for (int i = 0; i < OCTAVE_NUM; i++) {
    for (int j = 0; j < 3; j++) {
      pushMatrix();
      translate((circles[j] + circles[j + 1]) / 2 * sin(TWO_PI / OCTAVE_NUM * i), (circles[j] + circles[j + 1]) / 2 * -cos(TWO_PI / OCTAVE_NUM * i));
      scale(0.0025);

      shape(code_images[display_codes[j][i]]);

      popMatrix();
    }
  }
}

void mousePressed() {
  // 位置を取得
  PVector pos = screenToLocal(mouseX, mouseY);
  float r = dist(0, 0, pos.x, pos.y);
  float a = atan2(pos.x, -pos.y) + TWO_PI / OCTAVE_NUM / 2;

  if (r > circles[0] || r < circles[3])
    return;

  // コードを取得
  for (int i = 0; i < 3; i++) {
    if (r >= circles[i + 1]) {
      code_type = i;
      break;
    }
  }

  playing = true;
  code_pos = int(a * OCTAVE_NUM / TWO_PI + OCTAVE_NUM) % OCTAVE_NUM;
  code_num = display_codes[code_type][code_pos];

  // 音を鳴らす
  int[] voiced_code = codes[code_num].voicing(center_note);
  for (int i = 0; i < voiced_code.length; i++)
    notes[voiced_code[i]].play();
}

void mouseReleased() {
  playing = false;

  // 音を止める
  for (int i = 0; i < NOTE_NUM; i++)
    notes[i].pause();
}
