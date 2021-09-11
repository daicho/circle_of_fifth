import ddf.minim.*;
import ddf.minim.ugens.*;


// 描画
final color back_color = color(255, 255, 255);
final color note_color = color(240, 240, 240);
final color play_color = color(255, 191, 191);

final float circles[] = {0.99, 0.79, 0.59, 0.39, 0.34};

// 音
Minim minim;
AudioOutput sound_out;
final float base_note = 27.5;
final int note_num = 88;
final int octave_num = 12;
final int center_note = 44;
final float fade_time = 0.75;
final float volume = 0.1;
Note[] notes = new Note[note_num];

// コード
final int code_num = 36;
PShape[] code_images = new PShape[code_num];

final String[] code_names = {
  "A", "B♭", "B", "C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭",
  "Am", "B♭m", "Bm", "Cm", "C♯m", "Dm", "E♭m", "Em", "Fm", "F♯m", "Gm", "G♯m",
  "Am(♭5)", "A♯m(♭5)", "Bm(♭5)", "Cm(♭5)", "C♯m(♭5)", "Dm(♭5)", "D♯m(♭5)", "Em(♭5)", "Fm(♭5)", "F♯m(♭5)", "Gm(♭5)", "G♯m(♭5)"
};

final int[][] code_notes = {
  {0, 0, 4, 7}, {1, 1, 5, 8}, {2, 2, 6, 9}, {3, 3, 7, 10}, {4, 4, 8, 11}, {5, 5, 9, 0},
  {6, 6, 10, 1}, {7, 7, 11, 2}, {8, 8, 0, 3}, {9, 9, 1, 4}, {10, 10, 2, 5}, {11, 11, 3, 6},
  {0, 0, 3, 7}, {1, 1, 4, 8}, {2, 2, 5, 9}, {3, 3, 6, 10}, {4, 4, 7, 11}, {5, 5, 8, 0},
  {6, 6, 9, 1}, {7, 7, 10, 2}, {8, 8, 11, 3}, {9, 9, 0, 4}, {10, 10, 1, 5}, {11, 11, 2, 6},
  {0, 0, 3, 6}, {1, 1, 4, 7}, {2, 2, 5, 8}, {3, 3, 6, 9}, {4, 4, 7, 10}, {5, 5, 8, 11},
  {6, 6, 9, 0}, {7, 7, 10, 1}, {8, 8, 11, 2}, {9, 9, 0, 3}, {10, 10, 1, 4}, {11, 11, 2, 5}
};

final int[][] display_codes = {
  {3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1, 8},
  {12, 19, 14, 21, 16, 23, 18, 13, 20, 15, 22, 17},
  {26, 33, 28, 35, 30, 25, 32, 27, 34, 29, 24, 31}
};

int code_type;
int code_pos;
int code;
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

// 転回形
int[] inversion(int[] code_note, int n) {
  int[] inverted_code = new int[code_note.length];
  inverted_code[0] = code_note[0];

  for (int i = 0; i < code_note.length - 1; i++) {
    int p = (n + i) % (code_note.length - 1) + 1;
    int note = floor(float(inverted_code[i] - code_note[p] + octave_num) / octave_num) * octave_num + code_note[p];
    inverted_code[i + 1] = note;
  }

  return inverted_code;
}

// ボイジング
int[] voicing(int[] code_note, int center) {
  float min_diff = octave_num;
  float min_ave = 0;
  int min_i = 0;

  for (int i = 0; i < code_note.length - 1; i++) {
    int[] inverted_code = inversion(code_note, i);
    int sum = 0;
    float ave;
    float diff;

    // 転回コードの重心を算出
    for (int j = 1; j < inverted_code.length; j++)
      sum += inverted_code[j];
    ave = sum / (inverted_code.length - 1);

    // 中心音からの距離を算出
    diff = (ave - center) % octave_num;
    if (abs(diff) > octave_num / 2.0)
      diff = (diff < 0) ? (diff + octave_num) : (diff - octave_num);

    // 一番中心音に近いものを残す
    if (abs(diff) < abs(min_diff)) {
      min_diff = diff;
      min_ave = ave;
      min_i = i;
    }
  }

  // コードを再構成
  int offset = round(center + min_diff - min_ave);
  int[] voiced_code = inversion(code_note, min_i);

  for (int i = 0; i < voiced_code.length; i++)
    voiced_code[i] = voiced_code[i] + offset;

  return voiced_code;
}


void setup() {
  // ウィンドウ設定
  size(640, 640);
  surface.setResizable(true);

  // 描画設定
  strokeWeight(0.004);
  strokeCap(SQUARE);
  ellipseMode(RADIUS);
  shapeMode(CENTER);

  // コードの画像を読み込み
  for (int i = 0; i < code_num; i++)
    code_images[i] = loadShape("codes/code_" + i + ".svg");

  // 音の設定
  minim = new Minim(this);
  sound_out = minim.getLineOut(Minim.STEREO);

  for (int i = 0; i < note_num; i++)
    notes[i] = new Note(base_note * pow(2, i / float(octave_num)), volume, fade_time, sound_out);
    
  thread("update");
}

void draw() {
  // スケーリング
  translate(width / 2.0, height / 2.0);
  scale(min(width, height) / 2.0, min(width, height) / 2.0);

  background(back_color);

  // 円を描画
  noStroke();

  for (int i = 0; i < circles.length - 1; i++) {
    fill(note_color);
    ellipse(0, 0, circles[i], circles[i]);

    if (playing && code_type == i) {
      fill(play_color);
      arc(0, 0, circles[i], circles[i], TWO_PI / octave_num * (code_pos - 3.5), TWO_PI / octave_num * (code_pos - 2.5));
    }
  }

  fill(back_color);
  ellipse(0, 0, circles[circles.length - 1], circles[circles.length - 1]);

  stroke(0);
  noFill();

  for (int i = 0; i < circles.length; i++)
    ellipse(0, 0, circles[i], circles[i]);

  // 線を描画
  pushMatrix();
  rotate(-TWO_PI / octave_num / 2);

  for (int i = 0; i < octave_num; i++) {
    line(0, circles[0], 0, circles[3]);
    rotate(TWO_PI / octave_num);
  }

  popMatrix();

  // コードを描画
  for (int i = 0; i < octave_num; i++) {
    for (int j = 0; j < 3; j++) {
      pushMatrix();
      translate((circles[j] + circles[j + 1]) / 2 * sin(TWO_PI / octave_num * i), (circles[j] + circles[j + 1]) / 2 * -cos(TWO_PI / octave_num * i));
      scale(0.0025);

      shape(code_images[display_codes[j][i]]);

      popMatrix();
    }
  }
}

void update() {
  // 音を更新
  while (true) {
    for (int i = 0; i < note_num; i++)
      notes[i].update();
    
    try {
      Thread.sleep(1);
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}

void mousePressed() {
  // 位置を取得
  PVector pos = screenToLocal(mouseX, mouseY);
  float r = dist(0, 0, pos.x, pos.y);
  float a = atan2(pos.x, -pos.y) + TWO_PI / octave_num / 2;

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
  code_pos = int(a * octave_num / TWO_PI + octave_num) % octave_num;
  code = display_codes[code_type][code_pos];

  // 音を鳴らす
  int[] voiced_code = voicing(code_notes[code], center_note);
  for (int i = 0; i < voiced_code.length; i++)
    notes[voiced_code[i]].play();
}

void mouseReleased() {
  playing = false;

  // 音を止める
  for (int i = 0; i < note_num; i++)
    notes[i].pause();
}
