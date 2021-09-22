import themidibus.*;

// 入力デバイス
final int INPUT_DEVICE = 0;
final int OUTPUT_DEVICE = 5;

// 演奏コード
final int[] CODE_LIST = {
  80, 46, 19, 12,
  80, 43, 12, 22, 3,
  80, 46, 19, 12,
  80, 43,
  80, 46, 19, 12,
  80, 43, 12, 22, 3,
  80, 46, 43, 12,
  80, 10, 3
};

final boolean EASY = false;

// 描画
final color BACK_COLOR = color(255, 255, 255);
final color NOTE_COLOR = color(214, 214, 214);
final color PLAY_COLOR = color(255, 159, 159);
final color STROKE_COLOR = color(255, 255, 255);

// 音
final int OCTAVE_NUM = 12;
final int NOTE_NUM = 127;
final int BASE_POS = 21;

int transpose = 0;
int code_type = 0;
float start_angle = 0;
boolean rotating = false;

int cur_code = 0;
Note[] notes = new Note[NOTE_NUM];
boolean[] notes_on = new boolean[NOTE_NUM];

MidiBus midi_bus;
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
  size(640, 640);
  surface.setResizable(true);

  // フォント
  textFont(createFont("Arial", 24));
  textAlign(RIGHT, BOTTOM);

  // 音の設定
  MidiBus.list();
  midi_bus = new MidiBus(this, INPUT_DEVICE, OUTPUT_DEVICE);
  circle = new Circle(0, 0, 1);
}

void draw() {
  // 判定
  Code code = codes[circle.relativeToAbsoluteCode(EASY ? CODE_LIST[cur_code] % 36 : CODE_LIST[cur_code])];
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
      cur_code = (cur_code + 1) % CODE_LIST.length;
  }

  // スケーリング
  translate(width / 2.0, height / 2.0);
  scale(min(width, height) / 2.0, min(width, height) / 2.0);

  background(BACK_COLOR);

  // 五度圏表を描画
  if (rotating)
    circle.addAngle(circle.posToEuler(mouseX, mouseY)[1] - start_angle);

  circle.turnOnByRelativeCode(EASY ? CODE_LIST[cur_code] % 36 : CODE_LIST[cur_code]);
  circle.draw();

  // トランスポーズ
  pushMatrix();
  translate(0.97, 0.97);
  scale(0.0025);

  fill(0);
  text("Transpose: " + ((transpose > 0) ? "+" : "") + transpose, 0, 0);

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
  int prev_transpose = transpose;

  if (keyCode == 37) code_type--;
  if (keyCode == 39) code_type++;
  if (keyCode == 40) transpose--;
  if (keyCode == 38) transpose++;

  code_type = constrain(code_type, 0, 2);
  transpose = constrain(transpose, -6, +6);

  // コードの種類を変更
  circle.setCodeType(code_type);

  // MIDI再出力
  if (transpose != prev_transpose) {
    for (int i = 0; i < notes_on.length; i++) {
      if (notes_on[i]) {
        midi_bus.sendNoteOff(0x05, constrain(i + prev_transpose, 0, NOTE_NUM), 63);
        midi_bus.sendNoteOn(0x05, constrain(i + transpose, 0, NOTE_NUM), 63);
      }
    }
  }
}

// MIDI入力
void noteOn(int channel, int pitch, int velocity) {
  midi_bus.sendNoteOn(channel, constrain(pitch + transpose, 0, NOTE_NUM), velocity);
  notes_on[pitch] = true;
}

void noteOff(int channel, int pitch, int velocity) {
  midi_bus.sendNoteOff(channel, constrain(pitch + transpose, 0, NOTE_NUM), velocity);
  notes_on[pitch] = false;
}

void controllerChange(int channel, int pitch, int velocity) {
  midi_bus.sendControllerChange(channel, pitch, velocity);
}
