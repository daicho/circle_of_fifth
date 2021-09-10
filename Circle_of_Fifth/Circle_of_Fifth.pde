import ddf.minim.*;
import ddf.minim.ugens.*;


// 円の位置
final float circle[] = {0.99, 0.79, 0.59, 0.39, 0.34};

// コード
final int code_num = 36;
PShape[] code_images = new PShape[code_num];

final String[] code_names = {
  "A", "B♭", "B", "C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭",
  "Am", "B♭m", "Bm", "Cm", "C♯m", "Dm", "E♭m", "Em", "Fm", "F♯m", "Gm", "G♯m",
  "Am(♭5)", "A♯m(♭5)", "Bm(♭5)", "Cm(♭5)", "C♯m(♭5)", "Dm(♭5)", "D♯m(♭5)", "Em(♭5)", "Fm(♭5)", "F♯m(♭5)", "Gm(♭5)", "G♯m(♭5)"
};

final int[][] codes = {
  {3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1, 8},
  {12, 19, 14, 21, 16, 23, 18, 13, 20, 15, 22, 17},
  {26, 33, 28, 35, 30, 25, 32, 27, 34, 29, 24, 31}
};

boolean playing;
int code_type;
int code_pos;

// 音
Minim minim;
AudioOutput sound_out;
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
  
  for (int i = 0; i < note_num; i++)
    notes[i] = new Oscil(base_note * pow(2, i / 12), 0.5, Waves.SINE);
}

void draw() {
  // スケーリング
  translate(width / 2.0, height / 2.0);
  scale(min(width, height) / 2.0, min(width, height) / 2.0);
  
  background(255);
  
  // 円を描画
  for (int i = 0; i < circle.length; i++)
    ellipse(0, 0, circle[i], circle[i]);
  
  // 線を描画
  pushMatrix();
  rotate(TWO_PI / 24);
  
  for (int i = 0; i < 12; i++) {
    line(0, circle[0], 0, circle[3]);
    rotate(TWO_PI / 12);
  }
  
  popMatrix();
  
  // コードを描画
  for (int i = 0; i < 12; i++) {
    for (int j = 0; j < 3; j++) {
      pushMatrix();
      
      translate((circle[j] + circle[j + 1]) / 2 * sin(TWO_PI / 12 * i), (circle[j] + circle[j + 1]) / 2 * -cos(TWO_PI / 12 * i));
      scale(0.0025);
      
      shape(code_images[codes[j][i]]);
      
      popMatrix();
    }
  }
  
  if (playing) {
    // 音を鳴らす
    notes[codes[code_type][code_pos]].patch(sound_out);
    ellipse((circle[code_type] + circle[code_type + 1]) / 2 * sin(TWO_PI / 12 * code_pos), (circle[code_type] + circle[code_type + 1]) / 2 * -cos(TWO_PI / 12 * code_pos), 0.08, 0.08);
  }
}

void mousePressed() {
  PVector pos = screenToLocal(mouseX, mouseY);
  float r = dist(0, 0, pos.x, pos.y);
  float a = atan2(pos.x, -pos.y) + TWO_PI / 24;
  
  if (r > circle[0] || r < circle[3])
    return;
  
  playing = true;
  code_pos = int(a * 12 / TWO_PI + 12) % 12;
  
  for (int i = 0; i < 3; i++) {
    if (r >= circle[i + 1]) {
      code_type = i;
      break;
    }
  }
}

void mouseReleased() {
  playing = false;
}
