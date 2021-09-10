import ddf.minim.*;
import ddf.minim.ugens.*;


// 円の位置
final float circles[] = {0.99, 0.79, 0.59, 0.39, 0.34};

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

boolean playing;
int code_type;
int code_pos;
int code;

// 音
Minim minim;
AudioOutput sound_out;
Summer summer;
final float base_note = 27.5;
final int note_num = 88;
Oscil[] notes = new Oscil[note_num];


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
  strokeWeight(0.004);
  strokeCap(SQUARE);
  ellipseMode(RADIUS);
  stroke(0);
  fill(255);
  shapeMode(CENTER);
  
  // コードの画像を読み込み
  for (int i = 0; i < code_num; i++)
    code_images[i] = loadShape("codes/code_" + i + ".svg");
  
  // 正弦波を生成
  minim = new Minim(this);
  sound_out = minim.getLineOut(Minim.STEREO);
  summer = new Summer();
  
  for (int i = 0; i < note_num; i++) {
    notes[i] = new Oscil(base_note * pow(2, i / 12.0), 0.3, Waves.SINE);
  }
}

void draw() {
  // スケーリング
  translate(width / 2.0, height / 2.0);
  scale(min(width, height) / 2.0, min(width, height) / 2.0);
  
  background(255);
  
  // 円を描画
  for (int i = 0; i < circles.length; i++)
    ellipse(0, 0, circles[i], circles[i]);
  
  // 線を描画
  pushMatrix();
  rotate(TWO_PI / 24);
  
  for (int i = 0; i < 12; i++) {
    line(0, circles[0], 0, circles[3]);
    rotate(TWO_PI / 12);
  }
  
  popMatrix();
  
  // コードを描画
  for (int i = 0; i < 12; i++) {
    for (int j = 0; j < 3; j++) {
      pushMatrix();
      
      translate((circles[j] + circles[j + 1]) / 2 * sin(TWO_PI / 12 * i), (circles[j] + circles[j + 1]) / 2 * -cos(TWO_PI / 12 * i));
      scale(0.0025);
      
      shape(code_images[display_codes[j][i]]);
      
      popMatrix();
    }
  }
  
  if (playing) {
    ellipse((circles[code_type] + circles[code_type + 1]) / 2 * sin(TWO_PI / 12 * code_pos), (circles[code_type] + circles[code_type + 1]) / 2 * -cos(TWO_PI / 12 * code_pos), 0.08, 0.08);
  }
}

void mousePressed() {
  // 位置を取得
  PVector pos = screenToLocal(mouseX, mouseY);
  float r = dist(0, 0, pos.x, pos.y);
  float a = atan2(pos.x, -pos.y) + TWO_PI / 24;
  
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
  code_pos = int(a * 12 / TWO_PI + 12) % 12;
  code = display_codes[code_type][code_pos];
  
  // 音を鳴らす
  summer = new Summer();
  
  for (int i = 1; i < code_notes[code].length; i++) {
    notes[code_notes[code][i] + 36].patch(summer);
  }
  
  summer.patch(sound_out);
}

void mouseReleased() {
  if (playing) {
    playing = false;
    summer.unpatch(sound_out);
  }
}
