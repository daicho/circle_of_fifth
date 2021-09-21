public class Circle {
  private final float stroke_weight = 0.01;
  private final float circles[] = {1.0, 0.8, 0.6, 0.4, 0.35};
  private float cur_angle = 0;
  private float angle = 0;
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

  private PShape[] code_images;
  private boolean on = false;
  public int code = 0;
  public int code_type = 0;
  public int code_row = 0;
  public int code_pos = 0;

  private float x;
  private float y;
  private float size;

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
    rotate(cur_angle);

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
        translate((circles[j] + circles[j + 1]) / 2 * sin(TWO_PI / OCTAVE_NUM * i + cur_angle), (circles[j] + circles[j + 1]) / 2 * -cos(TWO_PI / OCTAVE_NUM * i + cur_angle));
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
    float a = atan2(pos.x, -pos.y) + TWO_PI / OCTAVE_NUM / 2 - angle;

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

    pos = int(a * OCTAVE_NUM / TWO_PI + OCTAVE_NUM) % OCTAVE_NUM;
    return new int[]{row, pos};
  }

  // 座標から相対的な位置を取得
  public int[] getRelativePos(float mx, float my) {
    int[] pos = getPos(mx, my);

    if (pos[1] != -1)
      pos[1] = (pos[1] + key_note) % OCTAVE_NUM;

    return pos;
  }

  // 座標からコードを取得
  public int getCode(float mx, float my) {
    int[] pos = getPos(mx, my);

    if (pos[0] == -1)
      return -1;

    return display_codes[code_type][pos[0]][pos[1]];
  }

  // void mouseReleased() {
  //   // 位置を取得
  //   PVector pos = screenToLocal(mouseX, mouseY);
  //   float a = atan2(pos.x, -pos.y) + TWO_PI / OCTAVE_NUM / 2 - angle;

  //   // 音を止める
  //   if (playing) {
  //     playing = false;

  //     for (int i = 0; i < NOTE_NUM; i++)
  //       notes[i].pause();
  //   }

  //   // キーを決定する
  //   if (rotating) {
  //     rotating = false;
  //     key_note = (round((angle + a - start_angle) / -TWO_PI * OCTAVE_NUM) + OCTAVE_NUM) % OCTAVE_NUM;
  //     angle = TWO_PI * -key_note / OCTAVE_NUM;
  //   }
  // }

  // void keyPressed() {
  //   if (keyCode == 37) code_type--;
  //   if (keyCode == 39) code_type++;
  //   if (keyCode == 40) center_note--;
  //   if (keyCode == 38) center_note++;
  //   code_type = constrain(code_type, 0, 2);
  //   center_note = constrain(center_note, 36, 52);
  // }
}
