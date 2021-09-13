public class Code {
  public String name;
  private int base;
  private int[] notes;

  public Code(String name, int base, int[] notes) {
    this.name = name;
    this.base = base;
    this.notes = notes;
  }

  // 転回形
  private int[] inversion(int n) {
    int[] inverted_notes = new int[notes.length];
    int prev = base;

    for (int i = 0; i < notes.length; i++) {
      int p = (n + i) % notes.length;
      inverted_notes[i] = floor(float(prev - notes[p] + OCTAVE_NUM) / OCTAVE_NUM) * OCTAVE_NUM + notes[p];
      prev = inverted_notes[i];
    }

    return inverted_notes;
  }

  // ボイジング
  int[] voicing(int center) {
    float min_diff = OCTAVE_NUM;
    float min_ave = 0;
    int min_i = 0;

    for (int i = 0; i < notes.length; i++) {
      int[] inverted_notes = inversion(i);
      float sum = 0, ave, diff;

      // 転回コードの重心を算出
      for (int j = 0; j < inverted_notes.length; j++)
        sum += inverted_notes[j];
      ave = sum / inverted_notes.length;

      // 中心音からの距離を算出
      diff = (ave - center) % OCTAVE_NUM;
      if (abs(diff) > OCTAVE_NUM / 2.0)
        diff = (diff < 0) ? (diff + OCTAVE_NUM) : (diff - OCTAVE_NUM);

      // 一番中心音に近いものを残す
      if (abs(diff) < abs(min_diff)) {
        min_diff = diff;
        min_ave = ave;
        min_i = i;
      }
    }

    // コードを再構成
    int offset = round(center + min_diff - min_ave);
    int[] voiced_notes = concat(new int[]{base}, inversion(min_i));

    for (int i = 0; i < voiced_notes.length; i++)
      voiced_notes[i] = voiced_notes[i] + offset;

    return voiced_notes;
  }
}
