import themidibus.*;

// 入力デバイス
final int INPUT_DEVICE = 0;
final int OUTPUT_DEVICE = -1;

// 演奏コード
final String CODE_FILE = "夜に駆ける.txt";
final int TRANSPOSE = -3;
final boolean EASY = false;

// 描画
final color BACK_COLOR = color(255, 255, 255);
final color NOTE_COLOR = color(214, 214, 214);
final color PLAY_COLOR = color(255, 159, 159);
final color STROKE_COLOR = color(255, 255, 255);

// 音
final int OCTAVE = 12;
final int NOTE_NUM = 127;
final int BASE_POS = 21;

MidiBus midi_bus;
boolean[] notes_on = new boolean[NOTE_NUM];
CodeReader code_reader;

// 五度圏表
Circle circle;
float start_angle = 0;
boolean rotating = false;

// 1オクターブに収まるように剰余を求める
int modOctave(int n) {
  return (n % OCTAVE + OCTAVE) % OCTAVE;
}

float modOctave(float n) {
  return (n % OCTAVE + OCTAVE) % OCTAVE;
}

void setup() {
  // ウィンドウ設定
  size(720, 720);
  surface.setResizable(true);

  // フォント
  textFont(createFont("Arial", 24));
  textAlign(RIGHT, BOTTOM);

  // 音の設定
  MidiBus.list();
  midi_bus = new MidiBus(this, INPUT_DEVICE, OUTPUT_DEVICE);
  circle = new Circle(0, 0, 1);
  code_reader = new CodeReader(CODE_FILE, TRANSPOSE);
}

void draw() {
  // 判定
  Code code = codes[EASY ? code_reader.getCode() % 36 : code_reader.getCode()];
  boolean[] code_on = new boolean[code.notes.length];
  boolean miss = true;

  for (int i = 0; i < NOTE_NUM; i++) {
    if (notes_on[i]) {
      // 構成音に含まれているか判定
      miss = true;

      for (int j = 0; j < code.notes.length; j++) {
        if (modOctave(i - BASE_POS) == modOctave(code.notes[j])) {
          code_on[j] = true;
          miss = false;
          break;
        }
      }

      if (miss)
        break;
    }
  }

  if (!miss) {
    // 全ての音が引けているか判定
    boolean success = true;

    for (int i = 0; i < code_on.length; i++) {
      if (!code_on[i]) {
        success = false;
        break;
      }
    }

    // 次のコードへ
    if (success)
      code_reader.next();
  }

  // スケーリング
  translate(width / 2.0, height / 2.0);
  scale(min(width, height) / 2.0, min(width, height) / 2.0);

  background(BACK_COLOR);

  // 五度圏表を描画
  if (rotating)
    circle.addAngle(circle.posToEuler(mouseX, mouseY)[1] - start_angle);

  circle.turnOnByCode(EASY ? code_reader.getCode() % 36 : code_reader.getCode());
  circle.draw();

  // トランスポーズ
  pushMatrix();
  translate(0.97, 0.97);
  scale(0.0025);

  fill(0);
  text("Transpose: " + code_reader.transpose, 0, 0);

  popMatrix();
}

void mousePressed() {
  // 回転
  if (circle.isHoldingBar(mouseX, mouseY)) {
    rotating = true;
    start_angle = circle.posToEuler(mouseX, mouseY)[1];
  }
}

void mouseReleased() {
  // 回転位置を決定する
  if (rotating) {
    rotating = false;
    circle.setKeyByAngle();
  }
}

void keyPressed() {
  if (keyCode == 37) circle.addKey(+1);
  if (keyCode == 39) circle.addKey(-1);
  if (keyCode == 38) code_reader.addTranspose(+1);
  if (keyCode == 40) code_reader.addTranspose(-1);
}

// MIDI入力
void noteOn(int channel, int pitch, int velocity) {
  notes_on[pitch] = true;
}

void noteOff(int channel, int pitch, int velocity) {
  notes_on[pitch] = false;
}
