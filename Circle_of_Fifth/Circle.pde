public class Circle {
  private float x;
  private float y;
  private float size;

  private final float stroke_weight = 0.01;
  private final float circles[] = {1.0, 0.8, 0.6, 0.4, 0.35};
  private float angle = 0;
  private PShape[] code_images;

  private boolean on = false;
  private int code_type = 0;
  private int code_row = 0;
  private int code_pos = 0;
  private int key_note = 0;

  public int[][][] display_codes = {
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

  public Circle(float x, float y, float size) {
    this.x = x;
    this.y = y;
    this.size = size;

    // 描画設定
    strokeCap(SQUARE);
    ellipseMode(RADIUS);
    shapeMode(CENTER);

    // コードの画像を読み込み
    code_images = new PShape[codes.length];
    for (int i = 0; i < codes.length; i++)
      code_images[i] = loadShape("codes/code_" + i + ".svg");
  }

  public void draw() {
    pushMatrix();
    translate(x, y);
    scale(size);

    pushMatrix();
    rotate(angle);

    // 円を描画
    noStroke();

    for (int i = 0; i < 3; i++) {
      fill(note_color);
      ellipse(0, 0, circles[i] * size, circles[i]);

      if (on && code_row == i) {
        fill(play_color);
        arc(0, 0, circles[i], circles[i], TWO_PI / OCTAVE_NUM * (code_pos - 3.5), TWO_PI / OCTAVE_NUM * (code_pos - 2.5));
      }
    }

    fill(note_color);
    ellipse(0, 0, circles[3], circles[3]);

    fill(back_color);
    ellipse(0, 0, circles[4], circles[4]);

    stroke(stroke_color);
    strokeWeight(stroke_weight);
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
        translate((circles[j] + circles[j + 1]) / 2 * sin(TWO_PI / OCTAVE_NUM * i + angle), (circles[j] + circles[j + 1]) / 2 * -cos(TWO_PI / OCTAVE_NUM * i + angle));
        scale(0.0022);

        shape(code_images[display_codes[code_type][j][i]]);

        popMatrix();
      }
    }

    popMatrix();
  }

  // スクリーン座標系からローカル座標系に変換
  private PVector screenToLocal(float x, float y) {
    PVector in = new PVector(x, y);
    PVector out = new PVector();

    PMatrix2D current_matrix = new PMatrix2D();
    getMatrix(current_matrix);

    current_matrix.invert();
    current_matrix.mult(in, out);

    return out;
  }

  // 座標から半径と角度を算出
  public float[] posToEuler(float mx, float my) {
    pushMatrix();
    translate(x, y);
    scale(size);

    // 位置を取得
    PVector pos = screenToLocal(mx, my);
    float r = dist(0, 0, pos.x, pos.y);
    float a = atan2(pos.x, -pos.y) - angle;

    popMatrix();

    return new float[]{r, a};
  }

  // 回転バーを掴んでいるか
  public boolean isHoldingBar(float mx, float my) {
    float[] euler = posToEuler(mx, my);
    return euler[0] < circles[3] && euler[0] >= circles[4];
  }

  // 座標から位置を取得
  public int[] getPos(float mx, float my) {
    float[] euler = posToEuler(mx, my);
    float r = euler[0];
    float a = euler[1];

    if (r > circles[0] || r < circles[3])
      return new int[]{-1, -1};

    // コードを取得
    int row = 0;
    int pos;

    for (int i = 0; i < 3; i++) {
      if (r >= circles[i + 1]) {
        row = i;
        break;
      }
    }

    pos = modOctave(round(a * OCTAVE_NUM / TWO_PI));
    return new int[]{row, pos};
  }

  // 座標から相対的な位置を取得
  public int[] getRelativePos(float mx, float my) {
    int[] pos = getPos(mx, my);

    if (pos[1] != -1)
      pos[1] = modOctave(pos[1] - key_note);

    return pos;
  }

  // 座標からコードを取得
  public int getCode(float mx, float my) {
    int[] pos = getPos(mx, my);

    if (pos[0] == -1)
      return -1;

    return display_codes[code_type][pos[0]][pos[1]];
  }

  // コードの種類を変更
  public void setCodeType(int code_type) {
    this.code_type = code_type;
  }

  // 点灯
  public void turnOn(int code_row, int code_pos) {
    this.code_row = code_row;
    this.code_pos = code_pos;
    on = true;
  }

  // 相対的な位置を指定して点灯
  public void turnOnByRelativePos(int code_row, int code_pos) {
    turnOn(code_row, modOctave(code_pos + key_note));
  }

  // コードを指定して点灯
  public void turnOnByCode(int code) {
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        for (int k = 0; k < 12; k++) {
          if (display_codes[i][j][k] == code) {
            setCodeType(i);
            turnOn(j, k);
            break;
          }
        }
      }
    }
  }

  // 座標の位置にあるコードを点灯
  public void turnOnByPos(float mx, float my) {
    int[] pos = getPos(mx, my);
    turnOn(pos[0], pos[1]);
  }

  // 消灯
  public void turnOff() {
    on = false;
  }

  // 角度を設定
  public void setAngle(float angle) {
    this.angle = angle;
  }

  // 角度を加算
  public void addAngle(float add_angle) {
    setAngle(angle + add_angle);
  }

  // キーを設定
  public void setKey(int key_note) {
    this.key_note = key_note;
  }

  // 現在の角度からキーを設定
  public void setKeyByAngle() {
    key_note = modOctave(round(angle / -TWO_PI * OCTAVE_NUM));
    angle = TWO_PI * -key_note / OCTAVE_NUM;
  }
}
